import Foundation

/// Trial orchestration as an n8n-style declarative pipeline.
///
/// Where n8n connects HTTP triggers to executable nodes through edges in a
/// JSON workflow document, this engine connects typed Swift nodes through
/// in-process channels. Each trial phase (research → debate → playback →
/// finisher → persistence) is a `PipelineNode` with its own retry policy,
/// fallback strategy, and observable event stream.
///
/// Why: the previous `TrialCoordinator.startTrial` was 80 lines of inline
/// imperative code. A failure anywhere collapsed the trial. Pipelines give
/// us:
///   - per-step retry + fallback (debate fails → scripted fallback, persist
///     fails → cached replay)
///   - observable progress for the UI (`AsyncStream<WorkflowEvent>`)
///   - cancellation that respects in-flight work
///   - testable nodes in isolation (no full SpriteKit harness needed)
///   - swappable graphs (debug build can stub the LLM node, replay build
///     can skip research and replay a stored Episode)

// MARK: - Retry policy

struct RetryPolicy: Sendable {
    let maxAttempts: Int
    let baseDelay: TimeInterval

    static let none = RetryPolicy(maxAttempts: 1, baseDelay: 0)
    static let standard = RetryPolicy(maxAttempts: 3, baseDelay: 0.6)
    static let llm = RetryPolicy(maxAttempts: 3, baseDelay: 1.5)

    init(maxAttempts: Int, baseDelay: TimeInterval) {
        precondition(maxAttempts >= 1)
        self.maxAttempts = max(1, maxAttempts)
        self.baseDelay = max(0, baseDelay)
    }

    func delay(forAttempt attempt: Int) -> TimeInterval {
        // Exponential backoff with full jitter, capped at 8 seconds.
        let exponent = max(0, attempt - 1)
        let raw = baseDelay * pow(2.0, Double(exponent))
        let capped = min(raw, 8.0)
        return capped == 0 ? 0 : Double.random(in: 0...capped)
    }
}

// MARK: - Errors

enum PipelineError: Error, LocalizedError {
    case nodeFailed(node: String, underlying: Error, attempts: Int)
    case cancelled
    case missingDependency(node: String, dependency: String)

    var errorDescription: String? {
        switch self {
        case .nodeFailed(let node, let err, let attempts):
            return "Pipeline node '\(node)' failed after \(attempts) attempt(s): \(err.localizedDescription)"
        case .cancelled:
            return "Pipeline cancelled"
        case .missingDependency(let node, let dep):
            return "Pipeline node '\(node)' missing dependency '\(dep)'"
        }
    }
}

// MARK: - Node protocol

protocol PipelineNode: Sendable {
    associatedtype Input: Sendable
    associatedtype Output: Sendable

    /// Stable identifier (unique within a workflow). Used in events + logs.
    var name: String { get }

    /// Retry policy applied to `execute`. Override per node.
    var retryPolicy: RetryPolicy { get }

    /// Do the work. Throwing escalates to retry policy.
    func execute(_ input: Input, context: PipelineContext) async throws -> Output

    /// Optional fallback when all retries are exhausted. Returning a value
    /// converts a fatal failure into a soft failure that lets the workflow
    /// continue. Default returns nil (propagate error).
    func fallback(for input: Input, error: Error, context: PipelineContext) async -> Output?
}

extension PipelineNode {
    var retryPolicy: RetryPolicy { .standard }
    func fallback(for input: Input, error: Error, context: PipelineContext) async -> Output? { nil }
}

// MARK: - Workflow events

enum WorkflowEvent: Sendable {
    case workflowStarted(name: String)
    case nodeStarted(node: String)
    case nodeRetry(node: String, attempt: Int, error: String)
    case nodeFallback(node: String, error: String)
    case nodeCompleted(node: String, durationMs: Int)
    case workflowCompleted(name: String, durationMs: Int)
    case workflowFailed(name: String, node: String, error: String)
    case workflowCancelled(name: String)
}

// MARK: - Context

/// Shared, mutable, per-execution context. Passed by reference to every node.
/// Holds the cancellation token, the event stream continuation, and a
/// scratchpad keyed by string for cross-node value passing.
final class PipelineContext: @unchecked Sendable {
    let workflowName: String
    let startedAt: Date
    private let continuation: AsyncStream<WorkflowEvent>.Continuation
    private let lock = NSLock()
    private var scratch: [String: Any] = [:]
    private var cancelled = false

    init(workflowName: String,
         startedAt: Date,
         continuation: AsyncStream<WorkflowEvent>.Continuation) {
        self.workflowName = workflowName
        self.startedAt = startedAt
        self.continuation = continuation
    }

    func emit(_ event: WorkflowEvent) {
        continuation.yield(event)
    }

    func cancel() {
        lock.lock(); defer { lock.unlock() }
        cancelled = true
    }

    var isCancelled: Bool {
        lock.lock(); defer { lock.unlock() }
        return cancelled
    }

    func set<T>(_ key: String, _ value: T) {
        lock.lock(); defer { lock.unlock() }
        scratch[key] = value
    }

    func get<T>(_ key: String, as type: T.Type = T.self) -> T? {
        lock.lock(); defer { lock.unlock() }
        return scratch[key] as? T
    }
}

// MARK: - Workflow

/// A linear chain of typed nodes. The pipeline runner threads the output
/// of each node into the input of the next. Branching workflows compose
/// multiple `Workflow` instances and join their results in a custom node
/// (mirrors n8n's "merge" node pattern).
struct Workflow<First: PipelineNode, Last: PipelineNode>: Sendable
where First.Input: Sendable, Last.Output: Sendable {
    let name: String
    let runner: @Sendable (First.Input, PipelineContext) async throws -> Last.Output

    /// Two-node chain.
    init(name: String, _ a: First, _ b: Last)
    where First.Output == Last.Input {
        self.name = name
        self.runner = { input, ctx in
            let mid = try await PipelineRunner.run(a, input: input, context: ctx)
            return try await PipelineRunner.run(b, input: mid, context: ctx)
        }
    }

    /// Three-node chain.
    init<B: PipelineNode>(
        name: String, _ a: First, _ b: B, _ c: Last
    ) where First.Output == B.Input, B.Output == Last.Input {
        self.name = name
        self.runner = { input, ctx in
            let m1 = try await PipelineRunner.run(a, input: input, context: ctx)
            let m2 = try await PipelineRunner.run(b, input: m1, context: ctx)
            return try await PipelineRunner.run(c, input: m2, context: ctx)
        }
    }

    /// Four-node chain.
    init<B: PipelineNode, C: PipelineNode>(
        name: String, _ a: First, _ b: B, _ c: C, _ d: Last
    ) where First.Output == B.Input, B.Output == C.Input, C.Output == Last.Input {
        self.name = name
        self.runner = { input, ctx in
            let m1 = try await PipelineRunner.run(a, input: input, context: ctx)
            let m2 = try await PipelineRunner.run(b, input: m1, context: ctx)
            let m3 = try await PipelineRunner.run(c, input: m2, context: ctx)
            return try await PipelineRunner.run(d, input: m3, context: ctx)
        }
    }

    /// Five-node chain.
    init<B: PipelineNode, C: PipelineNode, D: PipelineNode>(
        name: String, _ a: First, _ b: B, _ c: C, _ d: D, _ e: Last
    ) where First.Output == B.Input, B.Output == C.Input, C.Output == D.Input, D.Output == Last.Input {
        self.name = name
        self.runner = { input, ctx in
            let m1 = try await PipelineRunner.run(a, input: input, context: ctx)
            let m2 = try await PipelineRunner.run(b, input: m1, context: ctx)
            let m3 = try await PipelineRunner.run(c, input: m2, context: ctx)
            let m4 = try await PipelineRunner.run(d, input: m3, context: ctx)
            return try await PipelineRunner.run(e, input: m4, context: ctx)
        }
    }

    /// Execute the whole workflow. Returns the workflow output and an
    /// `AsyncStream<WorkflowEvent>` for UI subscription.
    func run(_ input: First.Input) -> (
        result: Task<Last.Output, Error>,
        events: AsyncStream<WorkflowEvent>
    ) {
        let (stream, continuation) = AsyncStream<WorkflowEvent>.makeStream()
        let ctx = PipelineContext(workflowName: name,
                                   startedAt: Date(),
                                   continuation: continuation)
        ctx.emit(.workflowStarted(name: name))
        let workflowName = self.name
        let runner = self.runner
        let task = Task { () async throws -> Last.Output in
            do {
                let output = try await runner(input, ctx)
                let elapsedMs = Int(Date().timeIntervalSince(ctx.startedAt) * 1000)
                ctx.emit(.workflowCompleted(name: workflowName, durationMs: elapsedMs))
                continuation.finish()
                return output
            } catch {
                if ctx.isCancelled {
                    ctx.emit(.workflowCancelled(name: workflowName))
                } else if case let PipelineError.nodeFailed(node, underlying, _) = error {
                    ctx.emit(.workflowFailed(name: workflowName,
                                              node: node,
                                              error: underlying.localizedDescription))
                } else {
                    ctx.emit(.workflowFailed(name: workflowName,
                                              node: "<unknown>",
                                              error: error.localizedDescription))
                }
                continuation.finish()
                throw error
            }
        }
        return (task, stream)
    }
}

// MARK: - Runner

/// Encapsulates the retry+fallback loop. Exposed as `static run` so chained
/// workflows (above) can re-use it without relying on type erasure.
enum PipelineRunner {
    static func run<N: PipelineNode>(
        _ node: N,
        input: N.Input,
        context: PipelineContext
    ) async throws -> N.Output {
        if context.isCancelled { throw PipelineError.cancelled }
        context.emit(.nodeStarted(node: node.name))
        let started = Date()
        var lastError: Error?
        let policy = node.retryPolicy
        for attempt in 1...policy.maxAttempts {
            if context.isCancelled { throw PipelineError.cancelled }
            do {
                let output = try await node.execute(input, context: context)
                let ms = Int(Date().timeIntervalSince(started) * 1000)
                context.emit(.nodeCompleted(node: node.name, durationMs: ms))
                return output
            } catch {
                lastError = error
                if attempt < policy.maxAttempts {
                    context.emit(.nodeRetry(node: node.name,
                                             attempt: attempt,
                                             error: error.localizedDescription))
                    let waitFor = policy.delay(forAttempt: attempt)
                    if waitFor > 0 {
                        try? await Task.sleep(nanoseconds: UInt64(waitFor * 1_000_000_000))
                    }
                    continue
                }
            }
        }
        // Exhausted retries: try fallback.
        if let last = lastError, let fallback = await node.fallback(for: input, error: last, context: context) {
            context.emit(.nodeFallback(node: node.name, error: last.localizedDescription))
            let ms = Int(Date().timeIntervalSince(started) * 1000)
            context.emit(.nodeCompleted(node: node.name, durationMs: ms))
            return fallback
        }
        let err = lastError ?? PipelineError.missingDependency(node: node.name, dependency: "execution")
        throw PipelineError.nodeFailed(node: node.name,
                                        underlying: err,
                                        attempts: policy.maxAttempts)
    }
}
