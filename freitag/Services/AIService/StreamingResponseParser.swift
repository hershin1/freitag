import Foundation

// MARK: - Streaming Response Parser

/// Parses Server-Sent Events (SSE) lines from an OpenAI-compatible streaming API.
///
/// Expected format per line:
/// - `data: {"choices":[{"delta":{"content":"..."}}]}`
/// - `data: [DONE]` signals end of stream.
struct StreamingResponseParser {

    // MARK: - Decodable Models

    struct StreamChunk: Decodable {
        struct Choice: Decodable {
            struct Delta: Decodable {
                let content: String?
            }
            let delta: Delta
        }
        let choices: [Choice]
    }

    // MARK: - Parsing

    /// Attempts to extract an incremental content string from a single SSE line.
    ///
    /// - Parameter line: A raw line from the event stream.
    /// - Returns: The content fragment, or `nil` if the line is empty, a comment,
    ///   the `[DONE]` sentinel, or otherwise unparseable.
    static func parseSSELine(_ line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

        // Skip empty lines and SSE comments
        guard !trimmed.isEmpty, !trimmed.hasPrefix(":") else { return nil }

        // Must begin with the SSE "data: " prefix
        guard trimmed.hasPrefix("data: ") else { return nil }
        let jsonString = String(trimmed.dropFirst(6))

        // Stream termination sentinel
        if jsonString == "[DONE]" { return nil }

        // Decode the JSON payload
        guard let data = jsonString.data(using: .utf8),
              let chunk = try? JSONDecoder().decode(StreamChunk.self, from: data),
              let content = chunk.choices.first?.delta.content else {
            return nil
        }
        return content
    }
}
