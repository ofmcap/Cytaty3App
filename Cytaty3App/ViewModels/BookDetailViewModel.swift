// ViewModels/BookDetailViewModel.swift
import Foundation

@MainActor
final class BookDetailViewModel: ObservableObject {
    @Published private(set) var book: Book
    @Published var quoteSort: QuoteSort = .addedDesc

    enum QuoteSort: CaseIterable {
        case addedDesc, addedAsc, pageAsc, pageDesc
    }

    private let storage: StorageService
    private var library: LibraryRoot

    init(storage: StorageService, bookID: String) {
        self.storage = storage
        self.library = (try? storage.loadLibrary()) ?? LibraryRoot()
        self.book = library.books.first(where: { $0.id == bookID }) ?? Book(id: bookID, title: "Nie znaleziono", authors: [], addedDate: Date(), quotes: [])
        applySort()
    }

    func refresh() {
        library = (try? storage.loadLibrary()) ?? LibraryRoot()
        if let updated = library.books.first(where: { $0.id == book.id }) {
            book = updated
            applySort()
        }
    }

    func addQuote(_ quote: Quote) {
        mutateAfterDismiss { [weak self] in
            guard let self, let idx = self.library.books.firstIndex(where: { $0.id == self.book.id }) else { return }
            self.library.books[idx].quotes.insert(quote, at: 0)
            self.book = self.library.books[idx]
            self.persist()
            self.applySort()
        }
    }

    func updateQuote(_ quote: Quote) {
        mutateAfterDismiss { [weak self] in
            guard let self, let bIdx = self.library.books.firstIndex(where: { $0.id == self.book.id }) else { return }
            if let qIdx = self.library.books[bIdx].quotes.firstIndex(where: { $0.id == quote.id }) {
                self.library.books[bIdx].quotes[qIdx] = quote
                self.book = self.library.books[bIdx]
                self.persist()
                self.applySort()
            }
        }
    }

    func deleteQuotes(at offsets: IndexSet) {
        guard let bIdx = library.books.firstIndex(where: { $0.id == book.id }) else { return }
        library.books[bIdx].quotes.remove(atOffsets: offsets)
        book = library.books[bIdx]
        persist()
        applySort()
    }

    func applySort() {
        var qs = book.quotes
        switch quoteSort {
        case .addedDesc: qs.sort { $0.addedDate > $1.addedDate }
        case .addedAsc:  qs.sort { $0.addedDate < $1.addedDate }
        case .pageAsc:   qs.sort { ($0.page ?? Int.max) < ($1.page ?? Int.max) }
        case .pageDesc:  qs.sort { ($0.page ?? Int.min) > ($1.page ?? Int.min) }
        }
        book.quotes = qs
    }

    private func persist() {
        do { try storage.saveLibrary(library) } catch { debugLog("Save error: \(error)") }
    }
}
