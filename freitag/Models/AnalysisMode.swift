import Foundation

/// Analysis mode determines the depth and verbosity of AI article analysis.
enum AnalysisMode: String, Codable, CaseIterable, Identifiable {
    case brief = "brief"   // 精简总结
    case deep = "deep"     // 深度分析

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .brief: return "精简总结"
        case .deep: return "深度分析"
        }
    }

    var icon: String {
        switch self {
        case .brief: return "doc.plaintext"
        case .deep: return "wand.and.stars"
        }
    }

    var subtitle: String {
        switch self {
        case .brief: return "快速概览，精炼要点"
        case .deep: return "五维深度分析"
        }
    }
}
