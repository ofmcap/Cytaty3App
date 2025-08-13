// ViewModels/LibraryViewModel.swift
import Foundation

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published private(set) var books: [Book] = []
    @Published var searchText: String = ""
    @Published var sortOption: SortOption = .addedDesc

    enum SortOption { case addedDesc, titleAsc, authorAsc }

    private let storage: StorageService
    private var library: LibraryRoot = LibraryRoot()

    init(storage: StorageService) {
        self.storage = storage
        load()
    }

    func load() {
        do {
            library = try storage.loadLibrary()
            apply()
        } catch {
            debugLog("Load error: \(error)")
            library = LibraryRoot(schemaVersion: storage.currentSchemaVersion, books: [])
            books = []
        }
    }

    func apply() {
        var list = library.books
        switch sortOption {
        case .addedDesc:
            list.sort { $0.addedDate > $1.addedDate }
        case .titleAsc:
            list.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .authorAsc:
            list.sort { ($0.authors.first ?? "").localizedCaseInsensitiveCompare($1.authors.first ?? "") == .orderedAscending }
        }
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            list = list.filter {
                $0.title.lowercased().contains(q) ||
                $0.authors.joined(separator: " ").lowercased().contains(q)
            }
        }
        self.books = list
    }

    func addBook(_ book: Book) {
        mutateAfterDismiss { [weak self] in
            guard let self else { return }
            self.library.books.insert(book, at: 0) // nowe na górze
            self.persistAndApply()
        }
    }

    func deleteBooks(at offsets: IndexSet) {
        library.books.remove(atOffsets: offsets)
        persistAndApply()
    }

    func updateBook(_ book: Book) {
        guard let idx = library.books.firstIndex(where: { $0.id == book.id }) else { return }
        mutateAfterDismiss { [weak self] in
            self?.library.books[idx] = book
            self?.persistAndApply()
        }
    }

    func book(by id: String) -> Book? {
        library.books.first(where: { $0.id == id })
    }

    private func persistAndApply() {
        do { try storage.saveLibrary(library) } catch { debugLog("Save error: \(error)") }
        apply()
    }
}
