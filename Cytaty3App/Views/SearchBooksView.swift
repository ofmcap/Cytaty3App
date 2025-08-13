// Views/SearchBooksView.swift
import SwiftUI

struct SearchBooksView: View {
    let network: NetworkService
    let onPick: (BookSearchResult) -> Void

    @State private var query = ""
    @State private var results: [BookSearchResult] = []
    @State private var isLoading = false
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            List {
                if let err = errorText { Text(err).foregroundColor(.red) }
                ForEach(results) { r in
                    Button {
                        onPick(r)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(r.title).font(.headline)
                            Text(r.authors.joined(separator: ", "))
                                .font(.subheadline).foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Szukaj książek")
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always))
            .overlay { if isLoading { ProgressView().controlSize(.large) } }
            .onChange(of: query) { _ in Task { await search() } }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zamknij") { onPick(.init(id: "", title: "", authors: [], publishYear: nil, isbn: nil, coverURL: nil)) }
                        .opacity(0) // zamykamy przez wybór
                }
            }
        }
    }

    private func search() async {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { results = []; return }
        isLoading = true
        errorText = nil
        do {
            let res = try await network.searchBooks(query: trimmed)
            if Task.isCancelled { return }
            results = res
        } catch {
            errorText = "Błąd wyszukiwania: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
