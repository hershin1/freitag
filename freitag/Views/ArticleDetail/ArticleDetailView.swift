import SwiftUI
import SwiftData

struct ArticleDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let article: Article

    @State private var viewModel: ArticleDetailViewModel?
    @State private var selectedInfographic: UIImage?

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
        .sheet(item: Binding(
            get: { selectedInfographic.map { IdentifiableImage(image: $0) } },
            set: { selectedInfographic = $0?.image }
        )) { item in
            InfographicFullScreenView(image: item.image)
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
                completedAnalysisView(analysis: analysis, viewModel: viewModel)
            } else {
                idleAnalysisView(viewModel: viewModel)
            }

        case .error(let message):
            failedAnalysisView(message: message, viewModel: viewModel)
        }
    }

    // MARK: - Idle State (Mode Selection)

    private func idleAnalysisView(viewModel: ArticleDetailViewModel) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 32))
                .foregroundStyle(.blue)

            Text("选择分析模式")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                // Brief Summary Button
                analysisModeButton(
                    icon: "doc.plaintext",
                    title: "精简总结",
                    subtitle: "快速概览，精炼要点",
                    color: .green
                ) {
                    viewModel.startAnalysis(mode: .brief, context: modelContext)
                }

                // Deep Analysis Button
                analysisModeButton(
                    icon: "wand.and.stars",
                    title: "深度分析",
                    subtitle: "五维深度分析",
                    color: .blue
                ) {
                    viewModel.startAnalysis(mode: .deep, context: modelContext)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private func analysisModeButton(
        icon: String,
        title: String,
        subtitle: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [color, color.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
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

    private func completedAnalysisView(analysis: Analysis, viewModel: ArticleDetailViewModel) -> some View {
        VStack(spacing: 12) {
            // Mode badge
            HStack {
                let mode = AnalysisMode(rawValue: analysis.analysisMode) ?? .deep
                Label(mode.displayName, systemImage: mode.icon)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(mode == .brief ? .green : .blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule().fill(
                            mode == .brief
                                ? Color.green.opacity(0.1)
                                : Color.blue.opacity(0.1)
                        )
                    )
                Spacer()
            }

            // Infographic section
            infographicSection(viewModel: viewModel)

            // Analysis sections (all 5 for both modes)
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

    // MARK: - Infographic Section

    @ViewBuilder
    private func infographicSection(viewModel: ArticleDetailViewModel) -> some View {
        switch viewModel.infographicState {
        case .idle, .skipped:
            EmptyView()

        case .generating:
            VStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("正在生成信息图...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))

        case .completed:
            if !viewModel.infographicImages.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("AI 信息图", systemImage: "photo.artframe")
                        .font(.subheadline.weight(.medium))

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(viewModel.infographicImages.enumerated()), id: \.offset) { _, image in
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 280)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                                    .onTapGesture {
                                        selectedInfographic = image
                                    }
                            }
                        }
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
            }

        case .failed:
            HStack(spacing: 6) {
                Image(systemName: "photo.badge.exclamationmark")
                    .foregroundStyle(.orange)
                Text("信息图生成失败，不影响分析结果")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))
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

            Button(action: { viewModel.startAnalysis(mode: viewModel.selectedMode, context: modelContext) }) {
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

// MARK: - Identifiable Image Wrapper

private struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

// MARK: - Full Screen Infographic View

private struct InfographicFullScreenView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView([.horizontal, .vertical]) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding()
            }
            .navigationTitle("信息图")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}
