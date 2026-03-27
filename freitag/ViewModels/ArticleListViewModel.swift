import Foundation
import SwiftData
import SwiftUI

@Observable
class ArticleListViewModel {
    var searchText: String = ""
    var isProcessingPending = false
    var errorMessage: String?
    
    // Process pending articles (those with empty title - just saved URL from Share Extension)
    func processPendingArticles(context: ModelContext) async {
        isProcessingPending = true
        defer { isProcessingPending = false }
        
        // Fetch articles with empty title
        let descriptor = FetchDescriptor<Article>(
            predicate: #Predicate { $0.title == "" }
        )
        
        guard let pendingArticles = try? context.fetch(descriptor) else { return }
        
        for article in pendingArticles {
            do {
                guard let url = URL(string: article.url) else { continue }
                let html = try await NetworkService.shared.fetchHTML(from: url)
                let parsed = WeChatArticleParser.parse(html: html)
                
                await MainActor.run {
                    article.title = parsed.title
                    article.author = parsed.author
                    article.plainTextContent = parsed.content
                    article.coverImageURL = parsed.coverImageURL
                    if let dateStr = parsed.publishDate {
                        // Simple date parsing for common WeChat formats
                        let formatter = DateFormatter()
                        formatter.locale = Locale(identifier: "zh_CN")
                        formatter.dateFormat = "yyyy-MM-dd"
                        article.publishDate = formatter.date(from: dateStr)
                        if article.publishDate == nil {
                            formatter.dateFormat = "yyyy年MM月dd日"
                            article.publishDate = formatter.date(from: dateStr)
                        }
                    }
                    try? context.save()
                }
            } catch {
                print("Error processing article \(article.url): \(error)")
            }
        }
    }
    
    // Add article from clipboard URL
    func addArticleFromURL(_ urlString: String, context: ModelContext) async -> Bool {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed),
              let host = url.host?.lowercased(),
              host.contains("weixin.qq.com") || host.contains("mp.weixin") else {
            errorMessage = "请输入有效的微信公众号文章链接"
            return false
        }
        
        // Check for duplicates
        let descriptor = FetchDescriptor<Article>(
            predicate: #Predicate { $0.url == trimmed }
        )
        if let existing = try? context.fetch(descriptor), !existing.isEmpty {
            errorMessage = "这篇文章已经保存过了"
            return false
        }
        
        // Create article with just URL first
        let article = Article(url: trimmed)
        context.insert(article)
        try? context.save()
        
        // Then fetch and parse
        do {
            let html = try await NetworkService.shared.fetchHTML(from: url)
            let parsed = WeChatArticleParser.parse(html: html)
            
            await MainActor.run {
                article.title = parsed.title
                article.author = parsed.author
                article.plainTextContent = parsed.content
                article.coverImageURL = parsed.coverImageURL
                try? context.save()
            }
            return true
        } catch {
            errorMessage = "获取文章失败: \(error.localizedDescription)"
            return false
        }
    }
    
    // Delete article
    func deleteArticle(_ article: Article, context: ModelContext) {
        context.delete(article)
        try? context.save()
    }
}
