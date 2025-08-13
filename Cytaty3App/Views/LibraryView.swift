// Views/LibraryView.swift
import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var modal: ModalManager

    @StateObject var viewModel: LibraryViewModel
    let network: NetworkService
    let imageCache: ImageCacheServiceProtocol

    @State private var isPresentingSearch = false

    var body: some View {
        List {
            ForEach(viewModel.books) { book in
                HStack(spacing: 12) {
                    CachedAsyncImage(
                        urlString: book.localCoverFilename == nil ? book.coverURL : nil,
                        cacheKey: book.localCoverFilename ?? (book.id + "_remote"),
                        imageCache: imageCache,
                        size: CGSize(width: 44, height: 60)
                    )
                    VStack(alignment: .leading) {
                        Text(book.title).font(.headline)
                        Text(book.authors.joined(separator: ", "))
                            .font(.subheadline).foregroundColor(.secondary)
                    }
                    Spacer()
                    if !book.quotes.isEmpty {
                        Text("\(book.quotes.count)")
                            .font(.caption)
                            .padding(6)
                            .background(Color.secondary.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { router.goToBookDetail(book.id) }
                .contextMenu {
                    Button("Edytuj") {
                        // TODO: Add/Edit Book in kolejnej iteracji (w tym PhotosPicker)
                    }
                    Button(role: .destructive) {
                        if let idx = viewModel.books.firstIndex(of: book) {
                            viewModel.deleteBooks(at: IndexSet(integer: idx))
                        }
                    } label: { Text("Usuń") }
                }
            }
            .onDelete(perform: viewModel.deleteBooks)
        }
        .navigationTitle("Biblioteka")
        .searchable(text: $viewModel.searchText)
        .onChange(of: viewModel.searchText) { _ in viewModel.apply() }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Najnowsze najpierw") { viewModel.sortOption = .addedDesc; viewModel.apply() }
                    Button("Tytuł A→Z") { viewModel.sortOption = .titleAsc; viewModel.apply() }
                    Button("Autor A→Z") { viewModel.sortOption = .authorAsc; viewModel.apply() }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    isPresentingSearch = true
                } label: { Image(systemName: "plus") }
                .accessibilityLabel("Dodaj książkę")
            }
        }
        .sheet(isPresented: $isPresentingSearch) {
            SearchBooksView(network: network) { result in
                // dismiss -> mutate
                isPresentingSearch = false
                guard !result.id.isEmpty else { return } // “Zamknij” fallback
                let book = Book(
                    title: result.title,
                    authors: result.authors.isEmpty ? ["Autor nieznany"] : result.authors,
                    publishYear: result.publishYear,
                    isbn: result.isbn,
                    coverURL: result.coverURL,
                    addedDate: Date(),
                    quotes: []
                )
                mutateAfterDismiss { viewModel.addBook(book) }
            }
        }
    }
}
