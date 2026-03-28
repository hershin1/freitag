import Foundation
import SwiftData
import UIKit

// MARK: - Analysis State

enum AnalysisState: Equatable {
    case idle
    case fetchingContent
    case analyzing
    case streaming(String) // accumulated text
    case completed
    case error(String)

    static func == (lhs: AnalysisState, rhs: AnalysisState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.fetchingContent, .fetchingContent),
             (.analyzing, .analyzing), (.completed, .completed):
            return true
        case (.streaming(let a), .streaming(let b)):
            return a == b
        case (.error(let a), .error(let b)):
            return a == b
        default:
            return false
        }
    }
}

// MARK: - Infographic State

enum InfographicState: Equatable {
    case idle
    case generating
    case completed
    case failed(String)
    case skipped

    static func == (lhs: InfographicState, rhs: InfographicState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.generating, .generating),
             (.completed, .completed), (.skipped, .skipped):
            return true
        case (.failed(let a), .failed(let b)):
            return a == b
        default:
            return false
        }
    }
}

// MARK: - View Model

@Observable
class ArticleDetailViewModel {
    let article: Article
    var analysisState: AnalysisState = .idle
    var streamingText: String = ""

    // v2: mode selection + infographic
    var selectedMode: AnalysisMode = .deep
    var infographicState: InfographicState = .idle
    var infographicImages: [UIImage] = []

    private var analysisTask: Task<Void, Never>?
    private var infographicTask: Task<Void, Never>?

    init(article: Article) {
        self.article = article
        if article.isAnalyzed {
            self.analysisState = .completed
            // Restore mode from saved analysis
            if let mode = AnalysisMode(rawValue: article.analysis?.analysisMode ?? "deep") {
                self.selectedMode = mode
            }
            // Load cached infographic images
            loadCachedInfographics()
        }
    }

    // MARK: - Analysis

    func startAnalysis(mode: AnalysisMode, context: ModelContext) {
        guard analysisState != .analyzing && analysisState != .fetchingContent else { return }

        selectedMode = mode
        analysisTask?.cancel()
        infographicTask?.cancel()
        streamingText = ""
        infographicImages = []
        infographicState = .idle

        analysisTask = Task { @MainActor in
            do {
                // Phase 1: Fetch content if needed
                if article.plainTextContent.isEmpty {
                    analysisState = .fetchingContent
                    guard let url = URL(string: article.url) else {
                        analysisState = .error("无效的文章链接")
                        return
                    }
                    let html = try await NetworkService.shared.fetchHTML(from: url)
                    let parsed = WeChatArticleParser.parse(html: html)
                    article.title = parsed.title.isEmpty ? article.title : parsed.title
                    article.author = parsed.author
                    article.plainTextContent = parsed.content
                    article.coverImageURL = parsed.coverImageURL
                    try? context.save()
                }

                guard !article.plainTextContent.isEmpty else {
                    analysisState = .error("无法获取文章内容，文章可能需要在微信中查看")
                    return
                }

                // Phase 2: AI analysis (streaming)
                analysisState = .analyzing

                let config = AIProviderConfig.load()
                guard KeychainHelper.apiKey != nil else {
                    analysisState = .error("请先在设置中配置 API Key")
                    return
                }

                let service = AIServiceFactory.create(config: config)

                let stream = service.analyzeArticleStreaming(
                    title: article.title,
                    content: article.plainTextContent,
                    mode: mode
                )

                for try await chunk in stream {
                    if Task.isCancelled { return }
                    streamingText += chunk
                    analysisState = .streaming(streamingText)
                }

                // Phase 3: Parse and save
                let result = AnalysisParser.parseFromMarkdown(streamingText)

                let analysis = Analysis(
                    summary: result.summary,
                    coreInsights: result.coreInsights,
                    investmentOpportunities: result.investmentOpportunities,
                    industryTrends: result.industryTrends,
                    actionSuggestions: result.actionSuggestions,
                    rawResponse: streamingText,
                    modelUsed: config.modelName,
                    analysisMode: mode.rawValue
                )

                article.analysis = analysis
                article.isAnalyzed = true
                try? context.save()

                analysisState = .completed

                // Phase 4: Generate infographic (after text completes)
                startInfographicGeneration(context: context)

            } catch is CancellationError {
                analysisState = .idle
            } catch {
                analysisState = .error("分析失败: \(error.localizedDescription)")
            }
        }
    }

    func cancelAnalysis() {
        analysisTask?.cancel()
        infographicTask?.cancel()
        analysisState = .idle
        infographicState = .idle
        streamingText = ""
        infographicImages = []
    }

    func reanalyze(context: ModelContext) {
        // Clear existing analysis and infographics
        if let analysis = article.analysis {
            InfographicStorage.delete(fileNames: analysis.infographicFileNames)
            context.delete(analysis)
            article.analysis = nil
            article.isAnalyzed = false
            try? context.save()
        }
        streamingText = ""
        infographicImages = []
        infographicState = .idle
        analysisState = .idle
        startAnalysis(mode: selectedMode, context: context)
    }

    // MARK: - Infographic Generation

    private func startInfographicGeneration(context: ModelContext) {
        // Only generate infographics if main provider is Gemini
        guard let geminiKey = resolveGeminiImageKey() else {
            infographicState = .skipped
            article.analysis?.infographicStatus = "skipped"
            try? context.save()
            return
        }

        infographicState = .generating
        article.analysis?.infographicStatus = "generating"
        try? context.save()

        infographicTask = Task { @MainActor in
            do {
                let service = GeminiImageService()
                let result = try await service.generateInfographics(
                    title: article.title,
                    analysisText: streamingText,
                    apiKey: geminiKey,
                    baseURL: AppConstants.geminiDefaultBaseURL
                )

                guard !result.images.isEmpty else {
                    infographicState = .skipped
                    article.analysis?.infographicStatus = "skipped"
                    try? context.save()
                    return
                }

                // Save images to disk
                guard let analysis = article.analysis else { return }
                var fileNames: [String] = []
                for (index, imageData) in result.images.enumerated() {
                    let fileName = try InfographicStorage.save(
                        imageData: imageData,
                        for: analysis.id,
                        index: index
                    )
                    fileNames.append(fileName)
                }

                // Update model
                analysis.infographicFileNames = fileNames
                analysis.infographicStatus = "completed"
                try? context.save()

                // Load for display
                infographicImages = result.images.compactMap { UIImage(data: $0) }
                infographicState = .completed

            } catch is CancellationError {
                infographicState = .idle
            } catch {
                infographicState = .failed("信息图生成失败")
                article.analysis?.infographicStatus = "failed"
                try? context.save()
            }
        }
    }

    // MARK: - Private Helpers

    /// Resolve a Gemini API key for image generation.
    /// Returns the main API key only if the current provider is Gemini.
    private func resolveGeminiImageKey() -> String? {
        let config = AIProviderConfig.load()
        guard config.providerType == .gemini else { return nil }
        guard let key = KeychainHelper.apiKey, !key.isEmpty else { return nil }
        return key
    }

    /// Load cached infographic images from disk when opening a previously analyzed article.
    private func loadCachedInfographics() {
        guard let analysis = article.analysis else { return }

        if analysis.infographicStatus == "completed" && !analysis.infographicFileNames.isEmpty {
            infographicImages = analysis.infographicFileNames.compactMap { fileName in
                guard let data = InfographicStorage.load(fileName: fileName) else { return nil }
                return UIImage(data: data)
            }
            infographicState = infographicImages.isEmpty ? .skipped : .completed
        } else if analysis.infographicStatus == "skipped" || analysis.infographicStatus == "none" {
            infographicState = .skipped
        } else if analysis.infographicStatus == "failed" {
            infographicState = .failed("信息图生成失败")
        }
    }
}
