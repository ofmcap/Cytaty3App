// Views/BookDetailView.swift
import SwiftUI

struct BookDetailView: View {
    @EnvironmentObject private var modal: ModalManager
    @StateObject var viewModel: BookDetailViewModel
    let imageCache: ImageCacheServiceProtocol

    var body: some View {
        List {
            Section {
                HStack(alignment: .top, spacing: 12) {
                    CachedAsyncImage(
                        urlString: viewModel.book.localCoverFilename == nil ? viewModel.book.coverURL : nil,
                        cacheKey: viewModel.book.localCoverFilename ?? (viewModel.book.id + "_remote"),
                        imageCache: imageCache,
                        size: CGSize(width: 64, height: 88)
                    )
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.book.title).font(.title3).bold()
                        Text(viewModel.book.authors.joined(separator: ", "))
                            .font(.subheadline).foregroundColor(.secondary)
                        if let year = viewModel.book.publishYear {
                            Text("\(String(localized: "PUBLISH_YEAR")) \(year)")
                                .font(.footnote).foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                }
            }
            Section(header: Text("QUOTES_SECTION_TITLE")) {
                Picker("QUOTES_SORT_TITLE", selection: $viewModel.quoteSort) {
                    Text("QUOTES_SORT_NEWEST").tag(BookDetailViewModel.QuoteSort.addedDesc)
                    Text("QUOTES_SORT_OLDEST").tag(BookDetailViewModel.QuoteSort.addedAsc)
                    Text("QUOTES_SORT_PAGE_ASC").tag(BookDetailViewModel.QuoteSort.pageAsc)
                    Text("QUOTES_SORT_PAGE_DESC").tag(BookDetailViewModel.QuoteSort.pageDesc)
                }
                .pickerStyle(.segmented)
                .onChange(of: viewModel.quoteSort) { _ in viewModel.applySort() }

                ForEach(viewModel.book.quotes) { quote in
                    QuoteRowView(quote: quote)
                        .contentShape(Rectangle())
                        .onTapGesture { modal.openEditQuote(quote) }
                }
                .onDelete(perform: viewModel.deleteQuotes)
            }
        }
        .navigationTitle("BOOK_DETAILS_TITLE")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    modal.openAddQuote()
                } label: { Image(systemName: "plus.bubble") }
                .accessibilityLabel(Text("ADD_QUOTE"))
            }
        }
        .fullScreenCover(isPresented: $modal.isPresentingAddQuoteFullScreen) {
            AddEditQuoteView(mode: .add) { newQuote in
                modal.dismissAddQuote()
                if let q = newQuote { viewModel.addQuote(q) }
            }
        }
        .sheet(item: $modal.editingQuote) { quote in
            AddEditQuoteView(mode: .edit(quote)) { updated in
                modal.dismissEditQuote()
                if let q = updated { viewModel.updateQuote(q) }
            }
        }
        .onAppear { viewModel.refresh() }
    }
}
