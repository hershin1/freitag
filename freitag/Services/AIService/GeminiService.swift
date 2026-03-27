import Foundation

// MARK: - Google Gemini Service

/// ``AIServiceProtocol`` implementation for the Google Gemini REST API.
///
/// Gemini uses a completely different API format from OpenAI:
/// - URL pattern: `{baseURL}/models/{model}:generateContent?key={apiKey}`
/// - Streaming:   `{baseURL}/models/{model}:streamGenerateContent?key={apiKey}&alt=sse`
/// - API key is a query parameter, not a Bearer token.
/// - Request body uses `contents` / `systemInstruction` instead of `messages`.
/// - Response uses `candidates[].content.parts[].text` instead of `choices[].message.content`.
final class GeminiService: AIServiceProtocol {

    // MARK: - Properties

    private let config: AIProviderConfig

    // MARK: - Decodable Response Models

    private struct GeminiResponse: Decodable {
        struct Candidate: Decodable {
            struct Content: Decodable {
                struct Part: Decodable {
                    let text: String?
                }
                let parts: [Part]?
            }
            let content: Content?
        }
        struct UsageMetadata: Decodable {
            let totalTokenCount: Int?
        }
        let candidates: [Candidate]?
        let usageMetadata: UsageMetadata?
    }

    // MARK: - Init

    init(config: AIProviderConfig) {
        self.config = config
    }

    // MARK: - Non-Streaming

    func analyzeArticle(title: String, content: String) async throws -> AnalysisResult {
        let apiKey = try resolveAPIKey()
        let url = try buildURL(apiKey: apiKey, stream: false)
        let body = try buildRequestBody(title: title, content: content)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            // Try to extract Gemini error message
            if let errorJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJSON["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw GeminiError.apiError(message: message)
            }
            throw NetworkError.apiError(statusCode: httpResponse.statusCode)
        }

        let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
        let rawText = decoded.candidates?.first?.content?.parts?.compactMap(\.text).joined() ?? ""

        var result = AnalysisParser.parseFromMarkdown(rawText)
        result.rawResponse = rawText
        result.modelUsed = config.modelName
        result.tokensUsed = decoded.usageMetadata?.totalTokenCount
        return result
    }

    // MARK: - Streaming

    func analyzeArticleStreaming(title: String, content: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let apiKey = try resolveAPIKey()
                    let url = try buildURL(apiKey: apiKey, stream: true)
                    let body = try buildRequestBody(title: title, content: content)

                    let headers: [String: String] = [
                        "Content-Type": "application/json"
                    ]

                    let stream = await NetworkService.shared.streamingPost(
                        url: url,
                        headers: headers,
                        body: body
                    )

                    for try await chunk in stream {
                        guard let line = String(data: chunk, encoding: .utf8) else { continue }
                        if let text = parseGeminiSSELine(line) {
                            continuation.yield(text)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    // MARK: - SSE Parsing

    /// Parses a single SSE line from the Gemini streaming response.
    /// Format: `data: {"candidates":[{"content":{"parts":[{"text":"..."}]}}]}`
    private func parseGeminiSSELine(_ line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.hasPrefix(":") else { return nil }

        // Strip "data: " prefix
        guard trimmed.hasPrefix("data: ") else { return nil }
        let jsonString = String(trimmed.dropFirst(6))

        guard let data = jsonString.data(using: .utf8),
              let response = try? JSONDecoder().decode(GeminiResponse.self, from: data),
              let parts = response.candidates?.first?.content?.parts else {
            return nil
        }

        let text = parts.compactMap(\.text).joined()
        return text.isEmpty ? nil : text
    }

    // MARK: - Private Helpers

    private func resolveAPIKey() throws -> String {
        guard let key = KeychainHelper.apiKey, !key.isEmpty else {
            throw AIServiceError.missingAPIKey
        }
        return key
    }

    /// Builds the Gemini endpoint URL.
    /// - Non-streaming: `{baseURL}/models/{model}:generateContent?key={apiKey}`
    /// - Streaming:     `{baseURL}/models/{model}:streamGenerateContent?key={apiKey}&alt=sse`
    private func buildURL(apiKey: String, stream: Bool) throws -> URL {
        let base = config.baseURL.hasSuffix("/")
            ? String(config.baseURL.dropLast())
            : config.baseURL
        let action = stream ? "streamGenerateContent" : "generateContent"
        let queryExtra = stream ? "&alt=sse" : ""
        let urlString = "\(base)/models/\(config.modelName):\(action)?key=\(apiKey)\(queryExtra)"
        guard let url = URL(string: urlString) else {
            throw AIServiceError.invalidBaseURL
        }
        return url
    }

    /// Builds the Gemini request body.
    /// ```json
    /// {
    ///   "contents": [{"role": "user", "parts": [{"text": "..."}]}],
    ///   "systemInstruction": {"parts": [{"text": "..."}]},
    ///   "generationConfig": {"temperature": 0.7, "maxOutputTokens": 4096}
    /// }
    /// ```
    private func buildRequestBody(title: String, content: String) throws -> Data {
        let systemPrompt = PromptBuilder.buildSystemPrompt()
        let userPrompt = PromptBuilder.buildUserPrompt(title: title, content: content)

        let body: [String: Any] = [
            "contents": [
                ["role": "user", "parts": [["text": userPrompt]]]
            ],
            "systemInstruction": [
                "parts": [["text": systemPrompt]]
            ],
            "generationConfig": [
                "temperature": config.temperature,
                "maxOutputTokens": config.maxTokens
            ]
        ]
        return try JSONSerialization.data(withJSONObject: body, options: [])
    }
}

// MARK: - Gemini Errors

enum GeminiError: LocalizedError {
    case apiError(message: String)

    var errorDescription: String? {
        switch self {
        case .apiError(let message):
            return "Gemini API 错误: \(message)"
        }
    }
}
