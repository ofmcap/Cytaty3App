import Foundation
import SwiftUI

@MainActor
final class SearchBooksViewModel: ObservableObject {
    private let network: NetworkService
    private let pageSize = 10

    @Published var query: String = ""
    @Published var results: [BookSearchResult] = []
    @Published var errorText: String?
    @Published var isLoadingFirstPage = false
    @Published var isLoadingMore = false

    // Preferencje językowe
    @AppStorage("preferredLanguageCode") private var preferredLanguageCode: String = "" // "" = Any
    @Published var preferredLanguage: LanguagePreference = .any

    private(set) var nextStartIndex: Int = 0
    private(set) var hasMore: Bool = false

    init(network: NetworkService) {
        self.network = network
        preferredLanguage = preferredLanguageCode.isEmpty ? .any : .code(preferredLanguageCode)
    }

    func setPreferredLanguage(_ lang: LanguagePreference) {
        preferredLanguage = lang
        switch lang {
        case .any: preferredLanguageCode = ""
        case .code(let c): preferredLanguageCode = c.lowercased()
        }
    }

    func onQueryChange(_ newValue: String) {
        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count < 2 {
            network.cancelSearch()
            results = []
            errorText = nil
            isLoadingFirstPage = false
            isLoadingMore = false
            nextStartIndex = 0
            hasMore = false
            return
        }
        Task { await loadFirstPage() }
    }

    func loadFirstPage() async {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard q.count >= 2 else { return }

        isLoadingFirstPage = true
        isLoadingMore = false
        errorText = nil
        nextStartIndex = 0
        hasMore = false

        do {
            let res = try await network.searchBooks(
                query: q,
                startIndex: 0,
                maxResults: pageSize,
                preferredLanguage: preferredLanguage
            )
            if Task.isCancelled { return }
            var seen = Set<String>()
            let unique = res.filter { seen.insert($0.id).inserted }
            results = unique
            nextStartIndex = results.count
            hasMore = res.count == pageSize
        } catch is CancellationError {
        } catch let urlErr as URLError where urlErr.code == .cancelled {
        } catch {
            if results.isEmpty {
                errorText = "Błąd wyszukiwania: \(error.localizedDescription)"
            }
        }
        isLoadingFirstPage = false
    }

    func loadMore() {
        guard hasMore, !isLoadingMore, !isLoadingFirstPage else { return }
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard q.count >= 2 else { return }

        isLoadingMore = true
        errorText = nil

        Task {
            do {
                let more = try await network.searchBooks(
                    query: q,
                    startIndex: nextStartIndex,
                    maxResults: pageSize,
                    preferredLanguage: preferredLanguage
                )
                if Task.isCancelled { return }
                let existing = Set(results.map { $0.id })
                let filtered = more.filter { !existing.contains($0.id) }
                results.append(contentsOf: filtered)
                nextStartIndex += more.count
                hasMore = more.count == pageSize
            } catch is CancellationError {
            } catch let urlErr as URLError where urlErr.code == .cancelled {
            } catch {
                errorText = "Nie udało się pobrać kolejnych wyników. Spróbuj ponownie."
            }
            isLoadingMore = false
        }
    }
}
