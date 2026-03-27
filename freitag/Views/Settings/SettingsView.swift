import SwiftUI
import SwiftData

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @State private var showAPIKey = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - AI Service Configuration
                aiConfigSection

                // MARK: - About
                aboutSection
            }
            .navigationTitle("设置")
        }
    }

    // MARK: - AI Config Section

    private var aiConfigSection: some View {
        Section {
            // Provider Picker
            Picker("服务商", selection: $viewModel.config.providerType) {
                ForEach(ProviderType.allCases) { provider in
                    Text(providerDisplayName(provider)).tag(provider)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: viewModel.config.providerType) { _, newValue in
                viewModel.selectProvider(newValue)
            }

            // Base URL
            VStack(alignment: .leading, spacing: 4) {
                Text("Base URL")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("https://api.example.com/v1", text: $viewModel.config.baseURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .disabled(!viewModel.config.providerType.isOpenAICompatible || viewModel.config.providerType != .custom)
                    .foregroundStyle(viewModel.config.providerType == .custom ? .primary : .secondary)
                    .onChange(of: viewModel.config.baseURL) { _, _ in
                        viewModel.saveConfig()
                    }
            }

            // Model Name
            VStack(alignment: .leading, spacing: 4) {
                Text("模型名称")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("gpt-4o", text: $viewModel.config.modelName)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onChange(of: viewModel.config.modelName) { _, _ in
                        viewModel.saveConfig()
                    }
            }

            // API Key
            VStack(alignment: .leading, spacing: 4) {
                Text("API Key")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    Group {
                        if showAPIKey {
                            TextField("sk-...", text: $viewModel.apiKey)
                        } else {
                            SecureField("sk-...", text: $viewModel.apiKey)
                        }
                    }
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onChange(of: viewModel.apiKey) { _, _ in
                        viewModel.saveAPIKey()
                    }

                    Button {
                        showAPIKey.toggle()
                    } label: {
                        Image(systemName: showAPIKey ? "eye.slash" : "eye")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Temperature
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("温度 (Temperature)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.1f", viewModel.config.temperature))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Slider(value: $viewModel.config.temperature, in: 0.0...1.0, step: 0.1)
                    .tint(.blue)
                    .onChange(of: viewModel.config.temperature) { _, _ in
                        viewModel.saveConfig()
                    }
            }

            // Max Tokens
            Stepper(value: $viewModel.config.maxTokens, in: 1024...8192, step: 1024) {
                HStack {
                    Text("最大 Tokens")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(viewModel.config.maxTokens)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            .onChange(of: viewModel.config.maxTokens) { _, _ in
                viewModel.saveConfig()
            }

            // Test Connection
            HStack {
                Button {
                    Task {
                        await viewModel.testConnection()
                    }
                } label: {
                    HStack(spacing: 6) {
                        if viewModel.isTesting {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Text("测试连接")
                    }
                }
                .disabled(viewModel.apiKey.isEmpty || viewModel.isTesting)

                Spacer()
            }

            if let result = viewModel.testResult {
                Text(result)
                    .font(.caption)
                    .foregroundStyle(result.hasPrefix("✅") ? .green : .red)
            }
        } header: {
            Label("AI 服务配置", systemImage: "brain")
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section {
            HStack {
                Text("应用名称")
                Spacer()
                Text("freitag")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("版本")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("关于")
                    .font(.subheadline.weight(.medium))
                Text("freitag 是一款智能文章收藏与分析工具。通过系统分享菜单快速保存网页文章，并利用 AI 进行深度分析，帮助您高效阅读和理解文章内容。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
            }
            .padding(.vertical, 4)
        } header: {
            Label("关于", systemImage: "info.circle")
        }
    }

    // MARK: - Helpers

    private func providerDisplayName(_ provider: ProviderType) -> String {
        switch provider {
        case .openAI: return "OpenAI"
        case .deepSeek: return "DeepSeek"
        case .gemini: return "Gemini"
        case .custom: return "自定义"
        }
    }
}

#Preview {
    SettingsView()
}
