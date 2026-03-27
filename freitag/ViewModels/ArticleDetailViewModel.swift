import Foundation
import SwiftData

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

@Observable
class ArticleDetailViewModel {
    let article: Article
    var analysisState: AnalysisState = .idle
    var streamingText: String = ""
    
    private var analysisTask: Task<Void, Never>?
    
    init(article: Article) {
        self.article = article
        if article.isAnalyzed {
            self.analysisState = .completed
        }
    }
    
    func startAnalysis(context: ModelContext) {
        guard analysisState != .analyzing && analysisState != .fetchingContent else { return }
        
        analysisTask?.cancel()
        streamingText = ""
        
        analysisTask = Task { @MainActor in
            do {
                // Check if we need to fetch content first
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
                
                analysisState = .analyzing
                
                let config = AIProviderConfig.load()
                guard KeychainHelper.apiKey != nil else {
                    analysisState = .error("请先在设置中配置 API Key")
                    return
                }
                
                let service = AIServiceFactory.create(config: config)
                
                // Use streaming
                let stream = service.analyzeArticleStreaming(
                    title: article.title,
                    content: article.plainTextContent
                )
                
                for try await chunk in stream {
                    if Task.isCancelled { return }
                    streamingText += chunk
                    analysisState = .streaming(streamingText)
                }
                
                // Parse the final result
                let result = AnalysisParser.parseFromMarkdown(streamingText)
                
                // Save analysis
                let analysis = Analysis(
                    summary: result.summary,
                    coreInsights: result.coreInsights,
                    investmentOpportunities: result.investmentOpportunities,
                    industryTrends: result.industryTrends,
                    actionSuggestions: result.actionSuggestions,
                    rawResponse: streamingText,
                    modelUsed: config.modelName
                )
                
                article.analysis = analysis
                article.isAnalyzed = true
                try? context.save()
                
                analysisState = .completed
                
            } catch is CancellationError {
                analysisState = .idle
            } catch {
                analysisState = .error("分析失败: \(error.localizedDescription)")
            }
        }
    }
    
    func cancelAnalysis() {
        analysisTask?.cancel()
        analysisState = .idle
        streamingText = ""
    }
    
    func reanalyze(context: ModelContext) {
        // Clear existing analysis
        if let analysis = article.analysis {
            context.delete(analysis)
            article.analysis = nil
            article.isAnalyzed = false
            try? context.save()
        }
        streamingText = ""
        analysisState = .idle
        startAnalysis(context: context)
    }
}
