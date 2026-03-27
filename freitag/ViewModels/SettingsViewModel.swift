import Foundation

@Observable
class SettingsViewModel {
    var config: AIProviderConfig
    var apiKey: String
    var testResult: String?
    var isTesting: Bool = false
    
    init() {
        self.config = AIProviderConfig.load()
        self.apiKey = KeychainHelper.apiKey ?? ""
    }
    
    func selectProvider(_ type: ProviderType) {
        config.providerType = type
        config.baseURL = type.defaultBaseURL
        config.modelName = type.defaultModelName
        saveConfig()
    }
    
    func saveConfig() {
        config.save()
    }
    
    func saveAPIKey() {
        if apiKey.isEmpty {
            _ = KeychainHelper.delete(key: "apiKey")
        } else {
            _ = KeychainHelper.save(key: "apiKey", value: apiKey)
        }
    }
    
    @MainActor
    func testConnection() async {
        isTesting = true
        testResult = nil
        
        guard !apiKey.isEmpty else {
            testResult = "❌ 请先输入 API Key"
            isTesting = false
            return
        }
        
        // Save current key first
        saveAPIKey()
        saveConfig()
        
        let service = AIServiceFactory.create(config: config)
        
        do {
            let result = try await service.analyzeArticle(
                title: "测试",
                content: "这是一个连接测试。请简短回复'你好'两个字。"
            )
            if !result.rawResponse.isEmpty {
                testResult = "✅ 连接成功！模型: \(config.modelName)"
            } else {
                testResult = "⚠️ 连接成功但返回为空"
            }
        } catch {
            testResult = "❌ 连接失败: \(error.localizedDescription)"
        }
        
        isTesting = false
    }
}
