import SwiftUI

enum LoadingState: Equatable {
    case loading(String)
    case error(String)
    case empty(String)

    static func == (lhs: LoadingState, rhs: LoadingState) -> Bool {
        switch (lhs, rhs) {
        case let (.loading(a), .loading(b)):
            return a == b
        case let (.error(a), .error(b)):
            return a == b
        case let (.empty(a), .empty(b)):
            return a == b
        default:
            return false
        }
    }
}

struct LoadingStateView: View {
    let state: LoadingState
    var retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            switch state {
            case .loading(let message):
                loadingView(message: message)

            case .error(let message):
                errorView(message: message)

            case .empty(let message):
                emptyView(message: message)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Loading

    @ViewBuilder
    private func loadingView(message: String) -> some View {
        ProgressView()
            .controlSize(.large)
            .padding(.bottom, 4)

        Text(message)
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    // MARK: - Error

    @ViewBuilder
    private func errorView(message: String) -> some View {
        Image(systemName: "exclamationmark.triangle.fill")
            .font(.system(size: 40))
            .foregroundStyle(.orange)

        Text(message)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)

        if let retryAction {
            Button(action: retryAction) {
                Label("重试", systemImage: "arrow.clockwise")
                    .font(.subheadline.weight(.medium))
            }
            .buttonStyle(.bordered)
            .tint(.blue)
        }
    }

    // MARK: - Empty

    @ViewBuilder
    private func emptyView(message: String) -> some View {
        Image(systemName: "tray")
            .font(.system(size: 40))
            .foregroundStyle(.secondary)

        Text(message)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
    }
}

#Preview("Loading") {
    LoadingStateView(state: .loading("正在加载文章..."))
}

#Preview("Error") {
    LoadingStateView(state: .error("加载失败，请检查网络连接")) {
        print("retry")
    }
}

#Preview("Empty") {
    LoadingStateView(state: .empty("还没有保存任何文章\n从浏览器分享文章到这里开始"))
}
