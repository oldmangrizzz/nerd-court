import Foundation

/// Sanitises raw LLM responses before they are spoken by TTS, persisted to
/// Convex, or rendered into speech bubbles.
///
/// Threat model:
///   - Model leaks the SECURITY CONTRACT system prompt or other internal text.
///   - Model regurgitates `<USER_DATA>` framing or role markers.
///   - Model produces multi-thousand-character output that blows the TTS
///     latency budget and the Convex document size budget.
///   - Model emits URLs that, when spoken aloud, are an exfiltration channel
///     ("visit dot evil dot example dot com slash...").
///
/// Strategy: strip obvious leakage markers, cap length, collapse whitespace,
/// and keep the result speakable. Never throws — failure mode is "shorter
/// safer string," not "missing dialogue."
enum LLMResponseSanitizer {

    /// One debate turn. Long enough for a meaty paragraph, short enough that
    /// a 4-voice trial can run in the 10-20 minute production budget.
    static let maxTurnLength = 800

    private static let leakagePatterns: [String] = [
        // Our own system-prompt scaffolding leaking back out.
        #"(?i)<\s*/?\s*USER_DATA\s*>"#,
        #"(?i)\bSECURITY CONTRACT[^.\n]{0,200}"#,
        // Generic role markers reflected by the model.
        #"(?i)<\s*\|?\s*(system|assistant|user|tool|developer|im_start|im_end)\s*\|?\s*>"#,
        #"(?i)\[\s*(system|assistant|user|tool|inst|/?inst)\s*\]"#,
        // Common prompt-leak phrases.
        #"(?i)\bmy\s+system\s+prompt\s+(is|says|reads)\b[^.\n]{0,200}"#,
        #"(?i)\bi\s+was\s+instructed\s+(to|not\s+to)\b[^.\n]{0,200}"#,
        // URL exfiltration channel — strip href payloads but keep "(link)".
        #"https?://\S+"#,
        // Code fences would render as gibberish through TTS.
        #"```+"#
    ]

    private static let compiledRegexes: [NSRegularExpression] = {
        leakagePatterns.compactMap { try? NSRegularExpression(pattern: $0) }
    }()

    /// Always returns a TTS-safe, length-capped string. Empty input ⇒ empty.
    static func sanitize(_ raw: String) -> String {
        var working = raw

        // Drop control chars except whitespace.
        working = String(working.unicodeScalars.compactMap { scalar -> Unicode.Scalar? in
            if scalar.value == 0x09 || scalar.value == 0x0A || scalar.value == 0x0D { return scalar }
            if CharacterSet.controlCharacters.contains(scalar) { return nil }
            return scalar
        }.map(Character.init))

        for regex in compiledRegexes {
            let range = NSRange(working.startIndex..., in: working)
            working = regex.stringByReplacingMatches(
                in: working, options: [], range: range, withTemplate: " "
            )
        }

        let collapsed = working
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if collapsed.count > maxTurnLength {
            // Cut on the last sentence boundary that fits, otherwise hard cap.
            let head = collapsed.prefix(maxTurnLength)
            if let lastTerminator = head.lastIndex(where: { ".!?".contains($0) }) {
                return String(collapsed[..<collapsed.index(after: lastTerminator)])
            }
            return String(head)
        }
        return collapsed
    }
}
