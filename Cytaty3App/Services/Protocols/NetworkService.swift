// Services/Protocols/NetworkService.swift
import Foundation

public protocol NetworkService {
    // Paginowana wersja wyszukiwania (Google Books: startIndex, maxResults)
    func searchBooks(query: String, startIndex: Int, maxResults: Int) async throws -> [BookSearchResult]
    func cancelSearch()
}

// Wygodna nakładka — zgodność wsteczna dla miejsc, które nie potrzebują paginacji
public extension NetworkService {
    func searchBooks(query: String) async throws -> [BookSearchResult] {
        try await searchBooks(query: query, startIndex: 0, maxResults: 20)
    }
}
