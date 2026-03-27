import Foundation
import SwiftSoup // SPM dependency

// MARK: - Parsed Article

/// The structured data extracted from a WeChat public account article.
struct ParsedArticle {
    var title: String
    var author: String
    var content: String
    var coverImageURL: String?
    var publishDate: String?
}

// MARK: - WeChat Article Parser

/// Extracts structured article data from WeChat ``mp.weixin.qq.com`` HTML pages.
///
/// Uses **SwiftSoup** (an HTML/CSS selector library) as the primary parser and
/// falls back to regex-based extraction when SwiftSoup is unavailable or fails.
struct WeChatArticleParser {

    // MARK: - Public API

    /// Parse raw HTML from a WeChat article page and return structured data.
    static func parse(html: String) -> ParsedArticle {
        // Try SwiftSoup-based parsing first
        do {
            let doc = try SwiftSoup.parse(html)

            let title       = try extractTitle(from: doc)
            let author      = try extractAuthor(from: doc)
            let content     = try extractContent(from: doc)
            let coverImage  = try extractCoverImage(from: doc)
            let publishDate = try extractPublishDate(from: doc)

            return ParsedArticle(
                title: title,
                author: author,
                content: truncateContent(content),
                coverImageURL: coverImage,
                publishDate: publishDate
            )
        } catch {
            // Fallback to regex parsing
            return regexFallbackParse(html: html)
        }
    }

    // MARK: - SwiftSoup Extraction Helpers

    /// Title extraction chain: `h1#activity-name` -> `.rich_media_title` -> `og:title`.
    private static func extractTitle(from doc: Document) throws -> String {
        if let el = try doc.select("h1#activity-name").first() {
            let text = try el.text().trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty { return text }
        }
        if let el = try doc.select(".rich_media_title").first() {
            let text = try el.text().trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty { return text }
        }
        if let el = try doc.select("meta[property=og:title]").first() {
            return try el.attr("content").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return "未知标题"
    }

    /// Author extraction chain: `a#js_name` -> `.rich_media_meta_text` -> `og:article:author`.
    private static func extractAuthor(from doc: Document) throws -> String {
        if let el = try doc.select("a#js_name").first() {
            let text = try el.text().trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty { return text }
        }
        if let el = try doc.select(".rich_media_meta_text").first() {
            return try el.text().trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let el = try doc.select("meta[property=og:article:author]").first() {
            return try el.attr("content")
        }
        return ""
    }

    /// Content extraction: `div#js_content` (or `.rich_media_content`) stripped of
    /// scripts, styles, and images. Falls back to `og:description`.
    private static func extractContent(from doc: Document) throws -> String {
        if let contentDiv = try doc.select("div#js_content").first()
            ?? doc.select(".rich_media_content").first() {
            // Remove non-text elements
            try contentDiv.select("script, style, img").remove()

            let text = try contentDiv.text(trimAndNormaliseWhitespace: true)
            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return text
            }
        }

        // Fallback to og:description
        if let el = try doc.select("meta[property=og:description]").first() {
            let desc = try el.attr("content")
            if !desc.isEmpty {
                return desc + "\n\n[注：仅获取到文章摘要，完整内容可能需要在微信中查看]"
            }
        }

        return ""
    }

    /// Cover image from `og:image` meta tag.
    private static func extractCoverImage(from doc: Document) throws -> String? {
        if let el = try doc.select("meta[property=og:image]").first() {
            let url = try el.attr("content")
            return url.isEmpty ? nil : url
        }
        return nil
    }

    /// Publish date from `#publish_time` element.
    private static func extractPublishDate(from doc: Document) throws -> String? {
        if let el = try doc.select("#publish_time").first() {
            let text = try el.text().trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? nil : text
        }
        return nil
    }

    // MARK: - Content Truncation

    /// Truncate content to ``AppConstants.maxArticleContentLength`` characters.
    private static func truncateContent(_ content: String) -> String {
        let maxLength = AppConstants.maxArticleContentLength
        if content.count <= maxLength { return content }
        let index = content.index(content.startIndex, offsetBy: maxLength)
        return String(content[..<index]) + "\n\n[内容已截断，原文过长]"
    }

    // MARK: - Regex Fallback

    /// Lightweight regex-based parser used when SwiftSoup fails.
    private static func regexFallbackParse(html: String) -> ParsedArticle {
        let title       = extractMetaContent(html: html, property: "og:title") ?? "未知标题"
        let author      = extractMetaContent(html: html, property: "og:article:author") ?? ""
        let description = extractMetaContent(html: html, property: "og:description") ?? ""
        let coverImage  = extractMetaContent(html: html, property: "og:image")

        return ParsedArticle(
            title: title,
            author: author,
            content: description.isEmpty
                ? ""
                : description + "\n\n[注：使用备用解析，仅获取到文章摘要]",
            coverImageURL: coverImage,
            publishDate: nil
        )
    }

    /// Extract the `content` attribute from a `<meta>` tag matching a given `property`.
    /// Handles both attribute orderings (`property` before `content` and vice-versa).
    private static func extractMetaContent(html: String, property: String) -> String? {
        let escapedProperty = NSRegularExpression.escapedPattern(for: property)

        // property="..." content="..."
        let pattern1 = "<meta[^>]+property=[\"']\(escapedProperty)[\"'][^>]+content=[\"']([^\"']*)[\"']"
        if let value = firstCaptureGroup(pattern: pattern1, in: html) {
            return value
        }

        // content="..." property="..."
        let pattern2 = "<meta[^>]+content=[\"']([^\"']*)[\"'][^>]+property=[\"']\(escapedProperty)[\"']"
        return firstCaptureGroup(pattern: pattern2, in: html)
    }

    /// Returns the first capture group from the first match of `pattern` in `text`.
    private static func firstCaptureGroup(pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return String(text[range])
    }
}
