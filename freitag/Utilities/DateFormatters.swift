import Foundation

enum DateFormatters {

    /// Formats dates as "yyyy年M月d日" (e.g. "2026年3月27日")
    static let articleDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()

    /// Relative date formatting in Chinese locale (e.g. "3小时前", "昨天")
    static let relativeDate: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.unitsStyle = .full
        return formatter
    }()
}
