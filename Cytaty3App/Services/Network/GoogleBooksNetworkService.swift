// Services/Network/GoogleBooksNetworkService.swift
import Foundation

public final class GoogleBooksNetworkService: NetworkService {
    private var searchTask: Task<[BookSearchResult], Error>?
    private let apiKey: String
    private let session: URLSession

    public init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    // Paginacja: startIndex / maxResults
    public func searchBooks(query: String, startIndex: Int, maxResults: Int) async throws -> [BookSearchResult] {
        // Anulujemy poprzednie wyszukiwanie tylko przy starcie nowego zapytania (pierwsza strona),
        // aby nie przerywać ładowania kolejnych stron.
        if startIndex == 0 {
            searchTask?.cancel()
        }

        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }

        searchTask = Task {
            // Debounce tylko dla pierwszej strony
            if startIndex == 0 {
                try await Task.sleep(nanoseconds: 300_000_000) // 300 ms
            }
            if Task.isCancelled { return [] }

            var comps = URLComponents(string: "https://www.googleapis.com/books/v1/volumes")!
            comps.queryItems = [
                .init(name: "q", value: titleAuthorQuery(from: q)),
                .init(name: "printType", value: "books"),
                .init(name: "maxResults", value: String(max(1, min(maxResults, 40)))),
                .init(name: "startIndex", value: String(max(0, startIndex))),
                .init(name: "key", value: apiKey)
            ]
            let url = comps.url!
            #if DEBUG
            // print("GoogleBooks q=\(comps.percentEncodedQuery ?? "")")
            #endif
            let (data, _) = try await session.data(from: url)

            struct APIResponse: Decodable {
                struct Item: Decodable {
                    struct VolumeInfo: Decodable {
                        let title: String?
                        let authors: [String]?
                        let publishedDate: String?
                        let industryIdentifiers: [Identifier]?
                        let imageLinks: ImageLinks?
                        struct Identifier: Decodable { let type: String; let identifier: String }
                        struct ImageLinks: Decodable { let smallThumbnail: String?; let thumbnail: String? }
                    }
                    let id: String
                    let volumeInfo: VolumeInfo
                }
                let items: [Item]?
            }

            let resp = try JSONDecoder().decode(APIResponse.self, from: data)
            let results: [BookSearchResult] = (resp.items ?? []).map { item in
                let v = item.volumeInfo
                let year = Self.parseYear(from: v.publishedDate)
                let isbn = v.industryIdentifiers?.first(where: { $0.type.contains("ISBN") })?.identifier
                let rawCover = v.imageLinks?.thumbnail ?? v.imageLinks?.smallThumbnail
                let cover = Self.enforceHTTPS(rawCover)
                return BookSearchResult(
                    id: item.id,
                    title: v.title ?? "Brak tytułu",
                    authors: v.authors ?? [],
                    publishYear: year,
                    isbn: isbn,
                    coverURL: cover
                )
            }
            return results
        }

        return try await searchTask!.value
    }

    public func cancelSearch() {
        searchTask?.cancel()
        searchTask = nil
    }

    private static func parseYear(from publishedDate: String?) -> Int? {
        guard let s = publishedDate else { return nil }
        if s.count >= 4, let y = Int(s.prefix(4)) { return y }
        return nil
    }

    private static func enforceHTTPS(_ urlString: String?) -> String? {
        guard let s = urlString, var comps = URLComponents(string: s) else { return urlString }
        if comps.scheme?.lowercased() == "http" {
            comps.scheme = "https"
            return comps.string
        }
        return urlString
    }
}

// MARK: - Query Builder (tylko intitle/inauthor, bez OR)

extension GoogleBooksNetworkService {
    /// Buduje parametr `q` przeszukujący wyłącznie tytuły i/lub autorów,
    /// bez pełnotekstowego fallbacku i bez operatora OR.
    /// Reguły:
    /// - "autor: tytuł" lub "autor - tytuł" → intitle:"pełny tytuł" + inauthor:autor
    /// - Fraza w cudzysłowie → intitle:"fraza"
    /// - 3+ słów: jeśli pierwsze wygląda na nazwisko → intitle:"reszta" + inauthor:first
    /// - 2 słowa:
    ///   * jeśli oba kapitalizowane (wyglądają na imię+nazwisko) → inauthor:"oba słowa"
    ///   * inaczej → intitle:"oba słowa"
    /// - 1 słowo → intitle:słowo
    func titleAuthorQuery(from raw: String) -> String {
        let input = normalizeWhitespace(raw)
        guard !input.isEmpty else { return "" }

        // 1) Heurystyka separatorów
        if let (author, title) = splitAuthorTitle(input) {
            let titleFrag = buildIntitlePhrase(title)
            let authorFrag = "inauthor:\(sanitizeSingle(author))"
            return "\(titleFrag)+\(authorFrag)"
        }

        // 2) Jeżeli cała fraza w cudzysłowie – traktuj jako dokładny tytuł
        if let quoted = extractFullQuotedPhrase(input) {
            return buildIntitlePhrase(quoted)
        }

        // 3) Tokenizacja
        let tokens = simpleTokens(from: input)
        if tokens.isEmpty { return "" }

        // 4) Heurystyki bez separatorów
        if tokens.count >= 3, looksLikeSurname(tokens[0]) {
            // Autor + tytuł (reszta)
            let author = tokens[0]
            let titleRest = tokens.dropFirst().joined(separator: " ")
            let titleFrag = buildIntitlePhrase(titleRest)
            let authorFrag = "inauthor:\(sanitizeSingle(author))"
            return "\(titleFrag)+\(authorFrag)"
        }

        if tokens.count == 2 {
            if bothLookLikeNames(tokens) {
                // Imię + Nazwisko → autor
                let authorFull = tokens.joined(separator: " ")
                return "inauthor:\(quoteIfNeeded(authorFull))"
            } else {
                // Dwuwyrazowy tytuł
                let titleFull = tokens.joined(separator: " ")
                return buildIntitlePhrase(titleFull)
            }
        }

        if tokens.count == 1 {
            // Jedno słowo – domyślnie tytuł
            return "intitle:\(sanitizeSingle(tokens[0]))"
        }

        // 5) Domyślnie: pełna fraza jako tytuł
        return buildIntitlePhrase(tokens.joined(separator: " "))
    }

    // MARK: - Helpers

    private func normalizeWhitespace(_ s: String) -> String {
        s.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
         .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func splitAuthorTitle(_ s: String) -> (author: String, title: String)? {
        if let r = s.range(of: ":") {
            let a = s[..<r.lowerBound].trimmingCharacters(in: .whitespaces)
            let t = s[r.upperBound...].trimmingCharacters(in: .whitespaces)
            if !a.isEmpty, !t.isEmpty { return (a, t) }
        }
        if let r = s.range(of: " - ") {
            let a = s[..<r.lowerBound].trimmingCharacters(in: .whitespaces)
            let t = s[r.upperBound...].trimmingCharacters(in: .whitespaces)
            if !a.isEmpty, !t.isEmpty { return (a, t) }
        }
        return nil
    }

    private func extractFullQuotedPhrase(_ s: String) -> String? {
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2, trimmed.first == "\"", trimmed.last == "\"" else { return nil }
        let inner = String(trimmed.dropFirst().dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
        return inner.isEmpty ? nil : inner
    }

    private func simpleTokens(from s: String) -> [String] {
        // Prosta tokenizacja bez zaawansowanych reguł; zachowujemy kolejność.
        s.split(whereSeparator: { $0.isWhitespace }).map { String($0) }
            .filter { !$0.isEmpty }
    }

    private func looksLikeSurname(_ token: String) -> Bool {
        // Prosta heurystyka: zaczyna się wielką literą i ma >=2 znaki, nie jest spójnikiem
        guard token.count >= 2 else { return false }
        guard let first = token.first, first.isUppercase else { return false }
        let lowered = token.lowercased()
        let stopwords = ["i", "oraz", "the", "and", "of", "de", "van", "von"]
        return !stopwords.contains(lowered)
    }

    private func bothLookLikeNames(_ tokens: [String]) -> Bool {
        guard tokens.count == 2 else { return false }
        return looksLikeSurname(tokens[0]) && looksLikeSurname(tokens[1])
    }

    private func buildIntitlePhrase(_ phrase: String) -> String {
        "intitle:\(quoteIfNeeded(phrase))"
    }

    private func quoteIfNeeded(_ s: String) -> String {
        s.contains(" ") ? "\"\(s)\"" : s
    }

    private func sanitizeSingle(_ s: String) -> String {
        // Pojedynczych słów nie cytujemy.
        s.replacingOccurrences(of: "\"", with: "")
    }
}
