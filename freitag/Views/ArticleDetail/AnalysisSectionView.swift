import SwiftUI

struct AnalysisSectionView: View {
    let title: String
    let content: String
    let icon: String

    @State private var isExpanded: Bool = true

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            Text(content)
                .font(.body)
                .foregroundStyle(.primary)
                .lineSpacing(4)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
                .padding(.bottom, 4)
        } label: {
            Label {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
            } icon: {
                Image(systemName: icon)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.blue)
                    .frame(width: 24, height: 24)
            }
        }
        .tint(.secondary)
    }
}

#Preview {
    List {
        AnalysisSectionView(
            title: "内容摘要",
            content: "这篇文章主要讨论了人工智能在现代教育中的应用，分析了其优势和潜在挑战，并提出了未来发展的建议。",
            icon: "doc.text"
        )

        AnalysisSectionView(
            title: "关键观点",
            content: "1. AI 可以个性化学习体验\n2. 教师角色将从知识传授者转变为引导者\n3. 需要关注数据隐私问题",
            icon: "lightbulb"
        )
    }
}
