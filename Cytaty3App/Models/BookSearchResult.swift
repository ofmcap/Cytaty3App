// Models/BookSearchResult.swift
import Foundation

public struct BookSearchResult: Identifiable, Equatable {
    public let id: String
    public let title: String
    public let authors: [String]
    public let publishYear: Int?
    public let isbn: String?
    public let coverURL: String?
}
