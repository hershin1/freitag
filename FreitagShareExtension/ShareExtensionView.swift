import SwiftUI

struct ShareExtensionView: View {
    let itemProvider: NSItemProvider
    let close: () -> Void

    @State private var viewModel = ShareExtensionViewModel()

    var body: some View {
        ZStack {
            // Semi-transparent backdrop
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    close()
                }

            // Card
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 20) {
                    // Header
                    headerView

                    Divider()

                    // Status
                    statusView

                    // URL Preview
                    if !viewModel.url.isEmpty {
                        urlPreview
                    }

                    // Buttons
                    buttonRow
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 34)
            }
        }
        .task {
            await viewModel.extractURL(from: itemProvider)
        }
        .onChange(of: viewModel.status) { _, newStatus in
            if newStatus == .saved {
                Task {
                    try? await Task.sleep(for: .seconds(1.5))
                    close()
                }
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Image(systemName: "bookmark.fill")
                .font(.title3)
                .foregroundStyle(.blue)

            Text("freitag")
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)

            Spacer()
        }
    }

    // MARK: - Status

    @ViewBuilder
    private var statusView: some View {
        switch viewModel.status {
        case .loading:
            HStack(spacing: 10) {
                ProgressView()
                    .controlSize(.small)
                Text("正在保存...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

        case .saved:
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title3)
                Text("已保存")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

        case .error:
            HStack(spacing: 10) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
                    .font(.title3)
                Text(viewModel.errorMessage ?? "保存失败")
                    .font(.subheadline)
                    .foregroundStyle(.red)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - URL Preview

    private var urlPreview: some View {
        HStack {
            Image(systemName: "link")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(viewModel.url)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .truncationMode(.middle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
    }

    // MARK: - Buttons

    private var buttonRow: some View {
        HStack(spacing: 12) {
            Button(action: close) {
                Text("取消")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .tint(.secondary)

            if viewModel.status == .error {
                Button {
                    Task {
                        await viewModel.extractURL(from: itemProvider)
                    }
                } label: {
                    Text("重试")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
