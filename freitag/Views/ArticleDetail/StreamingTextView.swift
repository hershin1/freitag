import SwiftUI

struct StreamingTextView: View {
    let text: String
    var isStreaming: Bool = true

    @State private var showCursor: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            (
                Text(text)
                    .foregroundStyle(.primary)
                +
                Text(isStreaming && showCursor ? " \u{25A0}" : "")
                    .foregroundStyle(.blue)
            )
            .font(.body)
            .lineSpacing(4)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            startCursorAnimation()
        }
        .onChange(of: isStreaming) { _, newValue in
            if !newValue {
                showCursor = false
            }
        }
    }

    private func startCursorAnimation() {
        guard isStreaming else { return }

        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            showCursor.toggle()
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 20) {
        StreamingTextView(
            text: "这篇文章主要讨论了人工智能在现代教育中的应用...",
            isStreaming: true
        )

        Divider()

        StreamingTextView(
            text: "分析已完成。这是最终的结果文本。",
            isStreaming: false
        )
    }
    .padding()
}
