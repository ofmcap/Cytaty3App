// Services/Tags/TagSuggestionService.swift
import Foundation

@MainActor
final class TagSuggestionService: ObservableObject {
    @Published private(set) var suggestions: [String] = []

    func updateSuggestions(from books: [Book], prefix: String) {
        let all = Set(books.flatMap { $0.quotes }.flatMap { $0.tags })
        if prefix.isEmpty {
            suggestions = Array(all).sorted()
        } else {
            let p = prefix.lowercased()
            suggestions = all.filter { $0.lowercased().hasPrefix(p) }.sorted()
        }
    }
}
