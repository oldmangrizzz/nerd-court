import XCTest
@testable import NerdCourt

/// Pipeline engine smoke tests. These exercise the retry/fallback contract
/// without touching any of the trial nodes — anything specific to the
/// trial graph is covered by the integration tests that drive
/// `TrialWorkflowFactory`.
final class PipelineEngineTests: XCTestCase {

    private actor Counter {
        private var n = 0
        func bump() -> Int { n += 1; return n }
        var value: Int { n }
    }

    private struct PassNode: PipelineNode {
        let name: String
        let mark: String
        var retryPolicy: RetryPolicy { .none }
        func execute(_ input: String, context: PipelineContext) async throws -> String {
            return input + mark
        }
    }

    private struct FlakyNode: PipelineNode {
        let name = "flaky"
        let counter: Counter
        let succeedOn: Int
        var retryPolicy: RetryPolicy { RetryPolicy(maxAttempts: 4, baseDelay: 0) }
        func execute(_ input: String, context: PipelineContext) async throws -> String {
            let attempt = await counter.bump()
            if attempt < succeedOn { throw NSError(domain: "flake", code: attempt) }
            return input + "-ok"
        }
    }

    private struct AlwaysFailNode: PipelineNode {
        let name = "fail"
        let fallbackValue: String?
        var retryPolicy: RetryPolicy { RetryPolicy(maxAttempts: 2, baseDelay: 0) }
        func execute(_ input: String, context: PipelineContext) async throws -> String {
            throw NSError(domain: "boom", code: 42)
        }
        func fallback(for input: String, error: Error, context: PipelineContext) async -> String? {
            fallbackValue
        }
    }

    func testTwoNodeChainRunsBothNodes() async throws {
        let workflow = Workflow(name: "t",
                                  PassNode(name: "a", mark: "-a"),
                                  PassNode(name: "b", mark: "-b"))
        let (task, _) = workflow.run("input")
        let result = try await task.value
        XCTAssertEqual(result, "input-a-b")
    }

    func testRetryPolicyEventuallySucceeds() async throws {
        let counter = Counter()
        let workflow = Workflow(name: "retry",
                                  PassNode(name: "head", mark: ""),
                                  FlakyNode(counter: counter, succeedOn: 3))
        let (task, _) = workflow.run("seed")
        let result = try await task.value
        XCTAssertEqual(result, "seed-ok")
        let final = await counter.value
        XCTAssertEqual(final, 3)
    }

    func testFallbackProducesValueAfterExhaustion() async throws {
        let workflow = Workflow(name: "fallback",
                                  PassNode(name: "head", mark: ""),
                                  AlwaysFailNode(fallbackValue: "fallback!"))
        let (task, _) = workflow.run("x")
        let result = try await task.value
        XCTAssertEqual(result, "fallback!")
    }

    func testNoFallbackPropagatesError() async {
        let workflow = Workflow(name: "fail",
                                  PassNode(name: "head", mark: ""),
                                  AlwaysFailNode(fallbackValue: nil))
        let (task, _) = workflow.run("x")
        do {
            _ = try await task.value
            XCTFail("expected throw")
        } catch let PipelineError.nodeFailed(node, _, attempts) {
            XCTAssertEqual(node, "fail")
            XCTAssertEqual(attempts, 2)
        } catch {
            XCTFail("wrong error: \(error)")
        }
    }

    func testEventStreamEmitsLifecycle() async throws {
        let workflow = Workflow(name: "events",
                                  PassNode(name: "a", mark: "-a"),
                                  PassNode(name: "b", mark: "-b"))
        let (task, events) = workflow.run("seed")
        var observed: [String] = []
        let collector = Task {
            for await ev in events {
                switch ev {
                case .workflowStarted: observed.append("start")
                case .nodeStarted(let n): observed.append("node:\(n)")
                case .nodeCompleted(let n, _): observed.append("done:\(n)")
                case .workflowCompleted: observed.append("end")
                default: break
                }
            }
            return observed
        }
        _ = try await task.value
        let final = await collector.value
        XCTAssertEqual(final.first, "start")
        XCTAssertEqual(final.last, "end")
        XCTAssertTrue(final.contains("node:a"))
        XCTAssertTrue(final.contains("done:a"))
        XCTAssertTrue(final.contains("node:b"))
        XCTAssertTrue(final.contains("done:b"))
    }
}
