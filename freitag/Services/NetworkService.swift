import Foundation

// MARK: - Network Service

actor NetworkService {
    static let shared = NetworkService()

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 120
        session = URLSession(configuration: config)
    }

    // MARK: - HTML Fetching

    /// Fetch HTML from a URL with a mobile User-Agent header.
    /// Attempts UTF-8 decoding first, then falls back to GB18030.
    func fetchHTML(from url: URL) async throws -> String {
        var request = URLRequest(url: url)
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 "
            + "(KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue("zh-CN,zh;q=0.9", forHTTPHeaderField: "Accept-Language")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }

        // Try UTF-8 first
        if let html = String(data: data, encoding: .utf8) {
            return html
        }

        // Fallback to GB18030 / GBK
        let cfEncoding = CFStringConvertEncodingToNSStringEncoding(
            CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)
        )
        if let html = String(data: data, encoding: String.Encoding(rawValue: cfEncoding)) {
            return html
        }

        throw NetworkError.decodingFailed
    }

    // MARK: - Streaming POST

    /// Perform a streaming POST request suitable for OpenAI-compatible APIs.
    /// Returns an `AsyncThrowingStream` that yields raw `Data` chunks (one per line).
    func streamingPost(url: URL, headers: [String: String], body: Data) -> AsyncThrowingStream<Data, Error> {
        AsyncThrowingStream { continuation in
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = body
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
            request.timeoutInterval = 120

            let task = Task {
                do {
                    let (bytes, response) = try await session.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse,
                          (200...299).contains(httpResponse.statusCode) else {
                        if let httpResponse = response as? HTTPURLResponse {
                            throw NetworkError.apiError(statusCode: httpResponse.statusCode)
                        }
                        throw NetworkError.invalidResponse
                    }

                    for try await line in bytes.lines {
                        continuation.yield(Data(line.utf8))
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
}

// MARK: - Network Error

enum NetworkError: LocalizedError {
    case invalidResponse
    case decodingFailed
    case apiError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "服务器响应无效"
        case .decodingFailed:
            return "内容解码失败"
        case .apiError(let code):
            return "API 错误 (HTTP \(code))"
        }
    }
}
