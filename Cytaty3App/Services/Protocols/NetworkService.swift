// Services/Protocols/NetworkService.swift
import Foundation

public protocol NetworkService {
    func searchBooks(
        query: String,
        startIndex: Int,
        maxResults: Int,
        preferredLanguage: LanguagePreference
    ) async throws -> [BookSearchResult]

    func cancelSearch()
}

// Backward compatibility + convenience overloads
public extension NetworkService {
    // Stara sygnatura (bez języka) – domyślnie Any
    func searchBooks(query: String, startIndex: Int, maxResults: Int) async throws -> [BookSearchResult] {
        try await searchBooks(
            query: query,
            startIndex: startIndex,
            maxResults: maxResults,
            preferredLanguage: .any
        )
    }

    // Wygodna wersja „bez paginacji” – start 0, 20 wyników, język Any
    func searchBooks(query: String) async throws -> [BookSearchResult] {
        try await searchBooks(
            query: query,
            startIndex: 0,
            maxResults: 20,
            preferredLanguage: .any
        )
    }
}
