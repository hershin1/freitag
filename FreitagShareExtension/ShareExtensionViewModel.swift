import Foundation
import SwiftData
import UniformTypeIdentifiers

@Observable
class ShareExtensionViewModel {
    var url: String = ""
    var status: ShareStatus = .loading
    var errorMessage: String?

    enum ShareStatus: Equatable {
        case loading, saved, error
    }

    func extractURL(from provider: NSItemProvider) async {
        await MainActor.run {
            status = .loading
            errorMessage = nil
        }

        // Try URL type first
        if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            if let item = try? await provider.loadItem(forTypeIdentifier: UTType.url.identifier),
               let url = item as? URL {
                await MainActor.run {
                    self.url = url.absoluteString
                }
                await saveArticle()
                return
            }
        }

        // Fallback: try plain text
        if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            if let item = try? await provider.loadItem(forTypeIdentifier: UTType.plainText.identifier),
               let text = item as? String,
               let url = URL(string: text), url.host != nil {
                await MainActor.run {
                    self.url = text
                }
                await saveArticle()
                return
            }
        }

        await MainActor.run {
            status = .error
            errorMessage = "无法获取文章链接"
        }
    }

    @MainActor
    private func saveArticle() async {
        do {
            let container = try SharedModelContainer.create()
            let context = ModelContext(container)

            // Check for duplicates
            let urlStr = self.url
            let descriptor = FetchDescriptor<Article>(
                predicate: #Predicate<Article> { $0.url == urlStr }
            )
            if let existing = try? context.fetch(descriptor), !existing.isEmpty {
                status = .saved // Already exists, treat as success
                return
            }

            let article = Article(url: self.url)
            context.insert(article)
            try context.save()
            status = .saved
        } catch {
            status = .error
            errorMessage = "保存失败: \(error.localizedDescription)"
        }
    }
}
