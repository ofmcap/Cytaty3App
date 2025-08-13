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

    public func searchBooks(query: String) async throws -> [BookSearchResult] {
        searchTask?.cancel()
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }

        searchTask = Task {
            try await Task.sleep(nanoseconds: 300_000_000) // 300 ms debounce
            if Task.isCancelled { return [] }

            var comps = URLComponents(string: "https://www.googleapis.com/books/v1/volumes")!
            comps.queryItems = [
                .init(name: "q", value: q),
                .init(name: "printType", value: "books"),
                .init(name: "maxResults", value: "20"),
                .init(name: "key", value: apiKey)
            ]
            let url = comps.url!
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
                let cover = v.imageLinks?.thumbnail ?? v.imageLinks?.smallThumbnail
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
        // formaty typu "YYYY" lub "YYYY-MM-DD"
        if s.count >= 4, let y = Int(s.prefix(4)) { return y }
        return nil
    }
}
