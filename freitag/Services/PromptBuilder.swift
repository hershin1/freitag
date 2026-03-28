import Foundation

// MARK: - Prompt Builder

/// Constructs the system and user prompts used for WeChat article analysis.
enum PromptBuilder {

    /// System prompt that instructs the AI to behave as a senior business analyst
    /// and produce a structured five-section report.
    /// The depth of each section varies by analysis mode.
    static func buildSystemPrompt(mode: AnalysisMode) -> String {
        switch mode {
        case .brief:
            return """
            你是一位高效的商业分析师，擅长从公众号文章中快速提取核心信息。

            你的任务是阅读用户提供的微信公众号文章内容，并按照以下固定格式输出精简分析报告。

            输出格式要求：
            1. 必须使用以下五个二级标题，顺序不可更改：
               ## 文章摘要
               ## 核心观点
               ## 投资机会
               ## 行业趋势
               ## 行动建议
            2. 每个部分用 1-3 个要点概括，每个要点不超过一句话。
            3. 文章摘要不超过 80 字，其他部分各不超过 100 字。
            4. 如果文章内容与投资无直接关系，简要说明即可。
            5. 保持客观、精炼，去掉所有冗余信息。
            6. 如果文章内容过短或不完整，在相应部分注明"原文信息不足"。
            """
        case .deep:
            return """
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
    }

    /// User prompt that wraps the article title and content, instructing the AI
    /// to analyse according to the five required sections.
    static func buildUserPrompt(title: String, content: String, mode: AnalysisMode) -> String {
        let modeInstruction: String
        switch mode {
        case .brief:
            modeInstruction = "请以精简模式输出，每个部分控制在1-3个要点，尽量简短。"
        case .deep:
            modeInstruction = "请严格按照系统提示中要求的五个部分（文章摘要、核心观点、投资机会、行业趋势、行动建议）输出你的深度分析。"
        }

        return """
        请分析以下微信公众号文章：

        【文章标题】\(title)

        【文章正文】
        \(content)

        \(modeInstruction)
        """
    }

    /// Build a prompt for infographic image generation.
    /// The prompt instructs the AI to produce a clean, NotebookLM-style infographic.
    static func buildInfographicPrompt(title: String, summary: String) -> String {
        return """
        Generate a clean, professional infographic image that visually summarizes the following article analysis. \
        The style should be similar to Google NotebookLM's visual summaries: \
        modern, minimal, using structured layouts with icons, color blocks, and clear typography. \
        Use a light background with pastel accent colors. Include the article title at the top.

        Article Title: \(title)

        Key Analysis:
        \(summary)

        Requirements:
        - Clean, modern infographic design
        - Structured layout with clear visual hierarchy
        - Use icons and diagrams to represent key concepts
        - Pastel color palette on light background
        - All text in Chinese (Simplified)
        - Make it easy to scan and understand at a glance
        """
    }
}
