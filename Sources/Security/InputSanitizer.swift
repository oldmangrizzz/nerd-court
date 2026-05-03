import Foundation

/// Hardens free-text user input from `IntakeScreen` before it is allowed to
/// flow into LLM prompts, TTS payloads, Convex documents, or anywhere else.
///
/// Threat model:
///   - Prompt injection ("ignore previous instructions...", role markers, fake
///     system/tool/assistant headers, jailbreak preludes).
///   - Resource exhaustion (multi-MB pastes, infinite-newline expansion).
///   - Control-character smuggling (BOM, zero-width chars, ANSI escapes).
///   - Markdown/code-fence escapes that change downstream parsing semantics.
///   - Template placeholders the LLM might dereference.
///
/// Strategy: deny-by-construction. We normalise to a printable, length-capped,
/// instruction-neutered slug and rely on `OllamaCloudClient` to wrap it in
/// delimited "user data" blocks (defence in depth).
enum InputSanitizer {

    enum Limit {
        static let plaintiffOrDefendant = 80
        static let grievance = 600
    }

    enum Field {
        case party
        case grievance

        var maxLength: Int {
            switch self {
            case .party: return Limit.plaintiffOrDefendant
            case .grievance: return Limit.grievance
            }
        }
    }

    private static let injectionPatterns: [String] = [
        #"(?i)<\s*\|?\s*(system|assistant|user|tool|function|developer)\s*\|?\s*>"#,
        #"(?i)\[\s*(system|assistant|user|tool|inst|/?inst)\s*\]"#,
        #"(?i)<\s*/?\s*(im_start|im_end)\s*\|?>"#,
        #"(?i)\bignore\s+(all\s+)?(previous|prior|above)\s+(instructions?|prompts?|rules?)\b"#,
        #"(?i)\bdisregard\s+(all\s+)?(previous|prior|above)\s+(instructions?|prompts?|rules?)\b"#,
        #"(?i)\byou\s+are\s+now\s+(?:in\s+)?(?:dan|developer|jailbreak|god)\s*(?:mode)?\b"#,
        #"(?i)\bact\s+as\s+(?:if\s+you\s+(?:are|were)\s+)?(?:an?\s+)?(?:unrestricted|uncensored|root|admin)\b"#,
        #"```+"#,
        #"\$\{[^}]{0,128}\}"#,
        #"\u{001B}\[[0-?]*[ -/]*[@-~]"#
    ]

    private static let compiledInjectionRegexes: [NSRegularExpression] = {
        injectionPatterns.compactMap { try? NSRegularExpression(pattern: $0) }
    }()

    private static let zeroWidthScalars: Set<Unicode.Scalar> = [
        "\u{200B}", "\u{200C}", "\u{200D}", "\u{2060}", "\u{FEFF}",
        "\u{202A}", "\u{202B}", "\u{202C}", "\u{202D}", "\u{202E}",
        "\u{2066}", "\u{2067}", "\u{2068}", "\u{2069}"
    ]

    /// Always returns a safe string (never throws). Empty if input was junk.
    static func sanitize(_ raw: String, field: Field) -> String {
        let truncated = String(raw.prefix(field.maxLength * 4))

        var stripped = String(String.UnicodeScalarView(
            truncated.unicodeScalars.filter { !zeroWidthScalars.contains($0) }
        ))

        stripped = String(stripped.unicodeScalars.compactMap { scalar -> Unicode.Scalar? in
            if scalar.value == 0x09 || scalar.value == 0x0A { return scalar }
            if CharacterSet.controlCharacters.contains(scalar) { return nil }
            return scalar
        }.map(Character.init))

        for regex in compiledInjectionRegexes {
            let range = NSRange(stripped.startIndex..., in: stripped)
            stripped = regex.stringByReplacingMatches(
                in: stripped, options: [], range: range, withTemplate: " "
            )
        }

        let collapsed = stripped
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if collapsed.count > field.maxLength {
            return String(collapsed.prefix(field.maxLength))
        }
        return collapsed
    }
}
