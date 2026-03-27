import Foundation

enum ProviderType: String, Codable, CaseIterable, Identifiable {
    case openAI = "OpenAI"
    case deepSeek = "DeepSeek"
    case gemini = "Gemini"
    case custom = "Custom"

    var id: String { rawValue }

    var defaultBaseURL: String {
        switch self {
        case .openAI: return "https://api.openai.com/v1"
        case .deepSeek: return "https://api.deepseek.com/v1"
        case .gemini: return "https://generativelanguage.googleapis.com/v1beta"
        case .custom: return ""
        }
    }

    var defaultModelName: String {
        switch self {
        case .openAI: return "gpt-4o"
        case .deepSeek: return "deepseek-chat"
        case .gemini: return "gemini-2.5-flash"
        case .custom: return ""
        }
    }

    /// Whether this provider uses the OpenAI-compatible chat completions API format.
    var isOpenAICompatible: Bool {
        switch self {
        case .openAI, .deepSeek, .custom: return true
        case .gemini: return false
        }
    }
}

struct AIProviderConfig: Codable, Equatable {
    var providerType: ProviderType
    var baseURL: String
    var modelName: String
    var maxTokens: Int
    var temperature: Double

    static var `default`: AIProviderConfig {
        AIProviderConfig(
            providerType: .deepSeek,
            baseURL: ProviderType.deepSeek.defaultBaseURL,
            modelName: ProviderType.deepSeek.defaultModelName,
            maxTokens: AppConstants.defaultMaxTokens,
            temperature: AppConstants.defaultTemperature
        )
    }

    // Save to shared UserDefaults
    func save() {
        guard let data = try? JSONEncoder().encode(self),
              let defaults = UserDefaults(suiteName: AppConstants.appGroupID) else { return }
        defaults.set(data, forKey: AppConstants.aiProviderKey)
    }

    // Load from shared UserDefaults
    static func load() -> AIProviderConfig {
        guard let defaults = UserDefaults(suiteName: AppConstants.appGroupID),
              let data = defaults.data(forKey: AppConstants.aiProviderKey),
              let config = try? JSONDecoder().decode(AIProviderConfig.self, from: data) else {
            return .default
        }
        return config
    }
}
