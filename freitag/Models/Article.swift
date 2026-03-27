import Foundation
import SwiftData

@Model
final class Article {
    @Attribute(.unique) var id: UUID
    var url: String
    var title: String
    var author: String
    var publishDate: Date?
    var plainTextContent: String
    var coverImageURL: String?
    var createdAt: Date
    var isAnalyzed: Bool

    @Relationship(deleteRule: .cascade, inverse: \Analysis.article)
    var analysis: Analysis?

    var isPending: Bool {
        title.isEmpty
    }

    var displayTitle: String {
        title.isEmpty ? "待处理..." : title
    }

    init(
        id: UUID = UUID(),
        url: String,
        title: String = "",
        author: String = "",
        publishDate: Date? = nil,
        plainTextContent: String = "",
        coverImageURL: String? = nil,
        createdAt: Date = Date(),
        isAnalyzed: Bool = false,
        analysis: Analysis? = nil
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.author = author
        self.publishDate = publishDate
        self.plainTextContent = plainTextContent
        self.coverImageURL = coverImageURL
        self.createdAt = createdAt
        self.isAnalyzed = isAnalyzed
        self.analysis = analysis
    }
}
