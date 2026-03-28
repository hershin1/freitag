import Foundation
import SwiftData

@Model
final class Analysis {
    @Attribute(.unique) var id: UUID
    var summary: String
    var coreInsights: String
    var investmentOpportunities: String
    var industryTrends: String
    var actionSuggestions: String
    var rawResponse: String
    var modelUsed: String
    var analyzedAt: Date

    // v2: analysis mode and infographic support
    var analysisMode: String
    var infographicFileNames: [String]
    var infographicStatus: String

    var article: Article?

    init(
        id: UUID = UUID(),
        summary: String,
        coreInsights: String,
        investmentOpportunities: String,
        industryTrends: String,
        actionSuggestions: String,
        rawResponse: String,
        modelUsed: String,
        analyzedAt: Date = Date(),
        analysisMode: String = "deep",
        infographicFileNames: [String] = [],
        infographicStatus: String = "none"
    ) {
        self.id = id
        self.summary = summary
        self.coreInsights = coreInsights
        self.investmentOpportunities = investmentOpportunities
        self.industryTrends = industryTrends
        self.actionSuggestions = actionSuggestions
        self.rawResponse = rawResponse
        self.modelUsed = modelUsed
        self.analyzedAt = analyzedAt
        self.analysisMode = analysisMode
        self.infographicFileNames = infographicFileNames
        self.infographicStatus = infographicStatus
    }
}
