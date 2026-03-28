import Foundation

enum AppConstants {
    static let appGroupID = "group.com.freitag.app"
    static let defaultMaxTokens = 4096
    static let defaultTemperature = 0.7
    static let maxArticleContentLength = 12000 // Chinese characters

    // UserDefaults keys
    static let aiProviderKey = "aiProviderConfig"

    // Keychain
    static let keychainServiceName = "com.freitag.apikey"

    // Infographic
    static let infographicModelName = "gemini-2.0-flash-preview-image-generation"
    static let geminiDefaultBaseURL = "https://generativelanguage.googleapis.com/v1beta"
}
