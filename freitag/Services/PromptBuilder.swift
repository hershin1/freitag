import Foundation

// MARK: - Prompt Builder

/// Constructs the system and user prompts used for WeChat article analysis.
enum PromptBuilder {

    /// System prompt that instructs the AI to behave as a senior business analyst
    /// and produce a structured five-section report.
    static func buildSystemPrompt() -> String {
        """
        你是一位资深的商业分析师和投资顾问，擅长从公众号文章中提取核心信息并提供深度分析。

        你的任务是阅读用户提供的微信公众号文章内容，并按照以下固定格式输出结构化分析报告。

        输出格式要求：
        1. 必须使用以下五个二级标题，顺序不可更改：
           ## 文章摘要
           ## 核心观点
           ## 投资机会
           ## 行业趋势
           ## 行动建议
        2. 每个部分使用清晰的中文段落或要点列表。
        3. 如果文章内容与投资无直接关系，在"投资机会"部分说明"本文未涉及明确的投资标的"，但仍需从宏观角度分析可能的间接影响。
        4. 保持客观、专业的语气，避免过度推测。
        5. 每个部分的内容应简洁有力，摘要不超过200字，其他部分各不超过300字。
        6. 如果文章内容过短或不完整，在相应部分注明"原文信息不足，无法充分分析"。
        """
    }

    /// User prompt that wraps the article title and content, instructing the AI
    /// to analyse according to the five required sections.
    static func buildUserPrompt(title: String, content: String) -> String {
        """
        请分析以下微信公众号文章：

        【文章标题】\(title)

        【文章正文】
        \(content)

        请严格按照系统提示中要求的五个部分（文章摘要、核心观点、投资机会、行业趋势、行动建议）输出你的分析。
        """
    }
}
