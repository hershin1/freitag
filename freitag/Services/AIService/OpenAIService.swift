import Foundation

// MARK: - OpenAI-Compatible Service

/// Concrete ``AIServiceProtocol`` implementation that works with any
/// OpenAI-compatible chat completions API (OpenAI, DeepSeek, local proxies, etc.).
final class OpenAIService: AIServiceProtocol {

    // MARK: - Properties

    private let config: AIProviderConfig

    // MARK: - Decodable Response Models

    private struct ChatCompletionResponse: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable {
                let content: String?
            }
            let message: Message
        }
        struct Usage: Decodable {
            let totalTokens: Int

            enum CodingKeys: String, CodingKey {
                case totalTokens = "total_tokens"
            }
        }
        let choices: [Choice]
        let model: String?
        let usage: Usage?
    }

    // MARK: - Initializer

    init(config: AIProviderConfig) {
        self.config = config
    }

    // MARK: - Non-Streaming Analysis

    func analyzeArticle(title: String, content: String, mode: AnalysisMode) async throws -> AnalysisResult {
        let apiKey = try resolveAPIKey()
        let url = try buildCompletionsURL()
        let body = try buildRequestBody(title: title, content: content, mode: mode, stream: false)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 120

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            if let httpResponse = response as? HTTPURLResponse {
                throw NetworkError.apiError(statusCode: httpResponse.statusCode)
            }
            throw NetworkError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        let rawText = decoded.choices.first?.message.content ?? ""

        var result = parseAnalysisFromMarkdown(rawText)
        result.rawResponse = rawText
        result.modelUsed = decoded.model ?? config.modelName
        result.tokensUsed = decoded.usage?.totalTokens
        return result
    }

    // MARK: - Streaming Analysis

    func analyzeArticleStreaming(title: String, content: String, mode: AnalysisMode) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let apiKey = try resolveAPIKey()
                    let url = try buildCompletionsURL()
                    let body = try buildRequestBody(title: title, content: content, mode: mode, stream: true)

                    let headers: [String: String] = [
                        "Content-Type": "application/json",
                        "Authorization": "Bearer \(apiKey)"
                    ]

                    let stream = await NetworkService.shared.streamingPost(
                        url: url,
                        headers: headers,
                        body: body
                    )

                    for try await chunk in stream {
                        guard let line = String(data: chunk, encoding: .utf8) else { continue }
                        if let content = StreamingResponseParser.parseSSELine(line) {
                            continuation.yield(content)
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

    // MARK: - Markdown Section Parsing

    /// Splits a Markdown response into the five predefined analysis sections
    /// based on `## ` headers. Delegates to the shared `AnalysisParser`.
    static func parseAnalysisFromMarkdown(_ text: String) -> AnalysisResult {
        AnalysisParser.parseFromMarkdown(text)
    }

    // MARK: - Private Helpers

    private func resolveAPIKey() throws -> String {
        guard let key = KeychainHelper.apiKey, !key.isEmpty else {
            throw AIServiceError.missingAPIKey
        }
        return key
    }

    private func buildCompletionsURL() throws -> URL {
        let base = config.baseURL.hasSuffix("/")
            ? String(config.baseURL.dropLast())
            : config.baseURL
        guard let url = URL(string: "\(base)/chat/completions") else {
            throw AIServiceError.invalidBaseURL
        }
        return url
    }

    private func buildRequestBody(title: String, content: String, mode: AnalysisMode, stream: Bool) throws -> Data {
        let systemPrompt = PromptBuilder.buildSystemPrompt(mode: mode)
        let userPrompt = PromptBuilder.buildUserPrompt(title: title, content: content, mode: mode)

        let body: [String: Any] = [
            "model": config.modelName,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt],
            ],
            "temperature": config.temperature,
            "max_tokens": config.maxTokens,
            "stream": stream,
        ]
        return try JSONSerialization.data(withJSONObject: body, options: [])
    }
}

// MARK: - Convenience wrapper (non-static access)

extension OpenAIService {
    /// Instance-level convenience so callers don't need to use `OpenAIService.parseAnalysisFromMarkdown`.
    func parseAnalysisFromMarkdown(_ text: String) -> AnalysisResult {
        Self.parseAnalysisFromMarkdown(text)
    }
}

// MARK: - AI Service Errors

enum AIServiceError: LocalizedError {
    case missingAPIKey
    case invalidBaseURL

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "未配置 API 密钥，请在设置中添加"
        case .invalidBaseURL:
            return "API 基础地址无效"
        }
    }
}
