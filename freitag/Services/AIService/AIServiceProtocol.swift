import Foundation

// MARK: - Analysis Result

/// Structured output from an AI analysis of a WeChat article.
struct AnalysisResult {
    /// Brief summary of the article (文章摘要).
    var summary: String = ""
    /// Core insights extracted from the article (核心观点).
    var coreInsights: String = ""
    /// Investment opportunities identified (投资机会).
    var investmentOpportunities: String = ""
    /// Industry trends discussed (行业趋势).
    var industryTrends: String = ""
    /// Actionable suggestions (行动建议).
    var actionSuggestions: String = ""
    /// The full raw response text from the AI model.
    var rawResponse: String = ""
    /// The model identifier that produced the result.
    var modelUsed: String = ""
    /// Token usage count, if available.
    var tokensUsed: Int?
}

// MARK: - AI Service Protocol

/// Common interface for any AI analysis backend (OpenAI, DeepSeek, etc.).
protocol AIServiceProtocol {
    /// Perform a full (non-streaming) analysis and return a structured result.
    func analyzeArticle(title: String, content: String) async throws -> AnalysisResult

    /// Perform a streaming analysis, yielding incremental text chunks.
    func analyzeArticleStreaming(title: String, content: String) -> AsyncThrowingStream<String, Error>
}

// MARK: - Markdown Analysis Parser

/// Splits a Markdown response into the five predefined analysis sections.
/// Shared utility used by all AI service implementations and view models.
enum AnalysisParser {
    static func parseFromMarkdown(_ text: String) -> AnalysisResult {
        var result = AnalysisResult()
        result.rawResponse = text

        let sectionHeaders: [(key: WritableKeyPath<AnalysisResult, String>, header: String)] = [
            (\.summary,                  "文章摘要"),
            (\.coreInsights,             "核心观点"),
            (\.investmentOpportunities,  "投资机会"),
            (\.industryTrends,           "行业趋势"),
            (\.actionSuggestions,        "行动建议"),
        ]

        for (index, section) in sectionHeaders.enumerated() {
            guard let startRange = text.range(of: "## \(section.header)") else { continue }
            let contentStart = startRange.upperBound

            var contentEnd = text.endIndex
            for nextIndex in (index + 1)..<sectionHeaders.count {
                if let nextRange = text.range(of: "## \(sectionHeaders[nextIndex].header)") {
                    contentEnd = nextRange.lowerBound
                    break
                }
            }

            let sectionText = String(text[contentStart..<contentEnd])
                .trimmingCharacters(in: .whitespacesAndNewlines)

            result[keyPath: section.key] = sectionText
        }

        return result
    }
}
