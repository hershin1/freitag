import SwiftUI
import SwiftData

struct ArticleDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let article: Article

    @State private var viewModel: ArticleDetailViewModel?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // MARK: - Header
                headerSection

                Divider()

                // MARK: - Analysis
                if let viewModel {
                    analysisSection(viewModel: viewModel)
                }

                // MARK: - Original Link
                if let url = URL(string: article.url) {
                    Divider()
                    originalLinkButton(url: url)
                }
            }
            .padding()
        }
        .navigationTitle(article.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let viewModel {
                    Button {
                        viewModel.reanalyze(context: modelContext)
                    } label: {
                        Label("重新分析", systemImage: "arrow.clockwise")
                    }
                    .disabled(isProcessing(viewModel.analysisState))
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = ArticleDetailViewModel(article: article)
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(article.displayTitle)
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)

            HStack(spacing: 8) {
                if !article.author.isEmpty {
                    Text(article.author)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("\u{00B7}")
                        .font(.subheadline)
                        .foregroundStyle(.quaternary)
                }

                Text(article.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Analysis Section

    @ViewBuilder
    private func analysisSection(viewModel: ArticleDetailViewModel) -> some View {
        switch viewModel.analysisState {
        case .idle:
            idleAnalysisView(viewModel: viewModel)

        case .fetchingContent:
            fetchingContentView

        case .analyzing:
            analyzingView

        case .streaming(let text):
            streamingView(text: text)

        case .completed:
            if let analysis = article.analysis {
                completedAnalysisView(analysis: analysis)
            } else {
                idleAnalysisView(viewModel: viewModel)
            }

        case .error(let message):
            failedAnalysisView(message: message, viewModel: viewModel)
        }
    }

    // MARK: - Idle State

    private func idleAnalysisView(viewModel: ArticleDetailViewModel) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 32))
                .foregroundStyle(.blue)

            Text("使用 AI 深度分析这篇文章")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(action: { viewModel.startAnalysis(context: modelContext) }) {
                HStack(spacing: 8) {
                    Image(systemName: "wand.and.stars")
                    Text("AI 智能分析")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [.blue, .blue.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Fetching Content State

    private var fetchingContentView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)

            Text("正在获取文章内容...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - Analyzing State

    private var analyzingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)

            Text("AI 正在分析文章...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - Streaming State

    private func streamingView(text: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("AI 正在分析...")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.blue)
            }

            StreamingTextView(text: text, isStreaming: true)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }

    // MARK: - Completed State

    private func completedAnalysisView(analysis: Analysis) -> some View {
        VStack(spacing: 12) {
            AnalysisSectionView(
                title: "文章摘要",
                content: analysis.summary.isEmpty ? "暂无摘要" : analysis.summary,
                icon: "doc.text"
            )

            AnalysisSectionView(
                title: "核心观点",
                content: analysis.coreInsights.isEmpty ? "暂无核心观点" : analysis.coreInsights,
                icon: "lightbulb.fill"
            )

            AnalysisSectionView(
                title: "投资机会",
                content: analysis.investmentOpportunities.isEmpty ? "暂无投资机会分析" : analysis.investmentOpportunities,
                icon: "chart.line.uptrend.xyaxis"
            )

            AnalysisSectionView(
                title: "行业趋势",
                content: analysis.industryTrends.isEmpty ? "暂无行业趋势分析" : analysis.industryTrends,
                icon: "arrow.triangle.branch"
            )

            AnalysisSectionView(
                title: "行动建议",
                content: analysis.actionSuggestions.isEmpty ? "暂无行动建议" : analysis.actionSuggestions,
                icon: "checkmark.seal.fill"
            )
        }
    }

    // MARK: - Failed State

    private func failedAnalysisView(message: String, viewModel: ArticleDetailViewModel) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 28))
                .foregroundStyle(.orange)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button(action: { viewModel.startAnalysis(context: modelContext) }) {
                Label("重新尝试", systemImage: "arrow.clockwise")
                    .font(.subheadline.weight(.medium))
            }
            .buttonStyle(.bordered)
            .tint(.blue)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    // MARK: - Original Link

    private func originalLinkButton(url: URL) -> some View {
        Link(destination: url) {
            HStack {
                Image(systemName: "safari")
                    .foregroundStyle(.blue)
                Text("查看原文")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
            )
        }
    }

    // MARK: - Helpers

    private func isProcessing(_ state: AnalysisState) -> Bool {
        switch state {
        case .analyzing, .streaming, .fetchingContent:
            return true
        default:
            return false
        }
    }
}
