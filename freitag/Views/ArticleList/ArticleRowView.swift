import SwiftUI
import SwiftData

struct ArticleRowView: View {
    let article: Article

    var body: some View {
        HStack(spacing: 12) {
            // MARK: - Cover Image
            coverImage

            // MARK: - Text Content
            VStack(alignment: .leading, spacing: 4) {
                Text(article.displayTitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    if !article.author.isEmpty {
                        Text(article.author)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(DateFormatters.relativeDate.localizedString(for: article.createdAt, relativeTo: Date()))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer(minLength: 0)

            // MARK: - Status Badge
            statusBadge
        }
        .padding(.vertical, 4)
    }

    // MARK: - Cover Image

    @ViewBuilder
    private var coverImage: some View {
        if let urlString = article.coverImageURL, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    placeholderIcon
                case .empty:
                    ProgressView()
                        .frame(width: 40, height: 40)
                @unknown default:
                    placeholderIcon
                }
            }
            .frame(width: 40, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        } else {
            placeholderIcon
        }
    }

    private var placeholderIcon: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color(.systemGray5))
            .frame(width: 40, height: 40)
            .overlay {
                Image(systemName: "doc.text")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
            }
    }

    // MARK: - Status Badge

    @ViewBuilder
    private var statusBadge: some View {
        if article.isPending {
            StatusBadge(text: "待处理", color: .orange)
        } else if article.isAnalyzed {
            StatusBadge(text: "已分析", color: .green)
        }
    }
}

// MARK: - StatusBadge

private struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(color.opacity(0.12))
            )
    }
}
