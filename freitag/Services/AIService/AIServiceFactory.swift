import Foundation

// MARK: - AI Service Factory

/// Creates concrete ``AIServiceProtocol`` instances from a provider configuration.
enum AIServiceFactory {
    /// Returns an ``AIServiceProtocol`` implementation appropriate for the given config.
    static func create(config: AIProviderConfig) -> AIServiceProtocol {
        switch config.providerType {
        case .gemini:
            return GeminiService(config: config)
        case .openAI, .deepSeek, .custom:
            return OpenAIService(config: config)
        }
    }
}
