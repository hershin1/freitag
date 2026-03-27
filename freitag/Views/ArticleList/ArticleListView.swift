import SwiftUI
import SwiftData

struct ArticleListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Article.createdAt, order: .reverse) private var articles: [Article]

    @State private var viewModel = ArticleListViewModel()
    @State private var showAddAlert = false
    @State private var pastedURL = ""

    private var filteredArticles: [Article] {
        if viewModel.searchText.isEmpty {
            return articles
        }
        return articles.filter { article in
            article.displayTitle.localizedCaseInsensitiveContains(viewModel.searchText)
            || article.author.localizedCaseInsensitiveContains(viewModel.searchText)
            || article.url.localizedCaseInsensitiveContains(viewModel.searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if articles.isEmpty && !viewModel.isProcessingPending {
                    LoadingStateView(
                        state: .empty("还没有保存任何文章\n从浏览器分享文章到这里\n或点击右上角添加链接")
                    )
                } else if filteredArticles.isEmpty && !viewModel.searchText.isEmpty {
                    LoadingStateView(
                        state: .empty("没有找到匹配的文章")
                    )
                } else {
                    articleList
                }
            }
            .navigationTitle("文章")
            .searchable(text: $viewModel.searchText, prompt: "搜索文章标题、作者")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    addButton
                }
            }
            .alert("添加文章", isPresented: $showAddAlert) {
                TextField("粘贴文章链接", text: $pastedURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Button("添加") {
                    addArticleFromURL()
                }
                Button("取消", role: .cancel) {
                    pastedURL = ""
                }
            } message: {
                Text("请输入文章的网页链接")
            }
            .overlay {
                if viewModel.isProcessingPending {
                    processingOverlay
                }
            }
            .alert("提示", isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("好的", role: .cancel) {}
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
        .refreshable {
            await viewModel.processPendingArticles(context: modelContext)
        }
        .task {
            await viewModel.processPendingArticles(context: modelContext)
        }
    }

    // MARK: - Article List

    private var articleList: some View {
        List {
            ForEach(filteredArticles) { article in
                NavigationLink(value: article) {
                    ArticleRowView(article: article)
                }
            }
            .onDelete(perform: deleteArticles)
        }
        .listStyle(.plain)
        .navigationDestination(for: Article.self) { article in
            ArticleDetailView(article: article)
        }
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button {
            pastedURL = ""
            // Auto-fill from clipboard if it contains a URL
            if let clipboardString = UIPasteboard.general.string,
               let url = URL(string: clipboardString),
               url.scheme?.hasPrefix("http") == true {
                pastedURL = clipboardString
            }
            showAddAlert = true
        } label: {
            Image(systemName: "plus.circle")
        }
    }

    // MARK: - Processing Overlay

    private var processingOverlay: some View {
        VStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            Text("正在处理文章...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, 16)
    }

    // MARK: - Actions

    private func addArticleFromURL() {
        let urlString = pastedURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !urlString.isEmpty else { return }

        pastedURL = ""

        Task {
            _ = await viewModel.addArticleFromURL(urlString, context: modelContext)
        }
    }

    private func deleteArticles(at offsets: IndexSet) {
        for index in offsets {
            let article = filteredArticles[index]
            viewModel.deleteArticle(article, context: modelContext)
        }
    }
}

#Preview {
    ArticleListView()
        .modelContainer(for: [Article.self, Analysis.self], inMemory: true)
}
