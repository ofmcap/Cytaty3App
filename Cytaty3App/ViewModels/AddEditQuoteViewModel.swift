// ViewModels/AddEditQuoteViewModel.swift
import Foundation

@MainActor
final class AddEditQuoteViewModel: ObservableObject {
    @Published var content: String
    @Published var page: String
    @Published var chapter: String
    @Published var tagsText: String
    @Published var note: String

    let originalQuote: Quote?

    init(quote: Quote? = nil) {
        self.originalQuote = quote
        self.content = quote?.content ?? ""
        self.page = quote?.page.map(String.init) ?? ""
        self.chapter = quote?.chapter ?? ""
        self.tagsText = quote?.tags.joined(separator: ", ") ?? ""
        self.note = quote?.note ?? ""
    }

    func buildQuote() -> Quote? {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let pageInt = Int(page)
        let tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if var q = originalQuote {
            q.content = trimmed
            q.page = pageInt
            q.chapter = chapter.isEmpty ? nil : chapter
            q.tags = tags
            q.note = note.isEmpty ? nil : note
            return q
        } else {
            return Quote(content: trimmed, page: pageInt, chapter: chapter.isEmpty ? nil : chapter, tags: tags, note: note.isEmpty ? nil : note, addedDate: Date())
        }
    }
}
