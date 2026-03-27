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
}
