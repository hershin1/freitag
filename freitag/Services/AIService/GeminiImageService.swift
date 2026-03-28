import Foundation
import UIKit

// MARK: - Gemini Image Generation Service

/// Calls Google Gemini's image generation model to produce infographic images.
/// This service is independent from the text analysis pipeline and always uses the Gemini API.
final class GeminiImageService {

    // MARK: - Result Type

    struct InfographicResult {
        let images: [Data]       // PNG image data
        let textResponse: String? // Any text the model returned alongside images
    }

    // MARK: - Decodable Response Models

    private struct ImageResponse: Decodable {
        struct Candidate: Decodable {
            struct Content: Decodable {
                struct Part: Decodable {
                    let text: String?
                    let inlineData: InlineData?
                }
                struct InlineData: Decodable {
                    let mimeType: String
                    let data: String // base64-encoded
                }
                let parts: [Part]?
            }
            let content: Content?
        }
        let candidates: [Candidate]?
    }

    // MARK: - Public API

    /// Generate 1-2 infographic images based on article analysis.
    ///
    /// - Parameters:
    ///   - title: Article title
    ///   - analysisText: Completed analysis text to visualize
    ///   - apiKey: Gemini API key
    ///   - baseURL: Gemini API base URL
    /// - Returns: ``InfographicResult`` containing image data
    func generateInfographics(
        title: String,
        analysisText: String,
        apiKey: String,
        baseURL: String
    ) async throws -> InfographicResult {
        let url = try buildURL(apiKey: apiKey, baseURL: baseURL)
        let body = try buildRequestBody(title: title, analysisText: analysisText)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiImageError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            // Try to extract Gemini error message
            if let errorJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJSON["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw GeminiImageError.apiError(message: message)
            }
            throw GeminiImageError.httpError(statusCode: httpResponse.statusCode)
        }

        let decoded = try JSONDecoder().decode(ImageResponse.self, from: data)
        return extractResults(from: decoded)
    }

    // MARK: - Private Helpers

    private func buildURL(apiKey: String, baseURL: String) throws -> URL {
        let base = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
        let model = AppConstants.infographicModelName
        let urlString = "\(base)/models/\(model):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw GeminiImageError.invalidURL
        }
        return url
    }

    private func buildRequestBody(title: String, analysisText: String) throws -> Data {
        // Truncate analysis text to avoid exceeding token limits
        let truncatedAnalysis = String(analysisText.prefix(3000))
        let prompt = PromptBuilder.buildInfographicPrompt(title: title, summary: truncatedAnalysis)

        let body: [String: Any] = [
            "contents": [
                ["role": "user", "parts": [["text": prompt]]]
            ],
            "generationConfig": [
                "temperature": 0.8,
                "responseModalities": ["TEXT", "IMAGE"]
            ]
        ]
        return try JSONSerialization.data(withJSONObject: body, options: [])
    }

    private func extractResults(from response: ImageResponse) -> InfographicResult {
        var images: [Data] = []
        var textParts: [String] = []

        guard let parts = response.candidates?.first?.content?.parts else {
            return InfographicResult(images: [], textResponse: nil)
        }

        for part in parts {
            if let text = part.text {
                textParts.append(text)
            }
            if let inlineData = part.inlineData,
               inlineData.mimeType.hasPrefix("image/"),
               let imageData = Data(base64Encoded: inlineData.data) {
                images.append(imageData)
            }
        }

        return InfographicResult(
            images: images,
            textResponse: textParts.isEmpty ? nil : textParts.joined(separator: "\n")
        )
    }
}

// MARK: - Errors

enum GeminiImageError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case apiError(message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Gemini 图片 API 地址无效"
        case .invalidResponse:
            return "Gemini 图片 API 响应无效"
        case .httpError(let code):
            return "Gemini 图片 API 错误 (HTTP \(code))"
        case .apiError(let message):
            return "Gemini 图片 API: \(message)"
        }
    }
}
