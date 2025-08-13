// Models/Book.swift
import Foundation

public struct Book: Identifiable, Codable, Equatable {
    public let id: String
    public var title: String
    public var authors: [String]          // wieloautorowość
    public var publishYear: Int?
    public var isbn: String?
    public var coverURL: String?          // z Google Books (zdalny)
    public var localCoverFilename: String?// zapisany lokalnie plik (opcjonalny)
    public var addedDate: Date            // do sortowania książek
    public var quotes: [Quote]

    public init(
        id: String = UUID().uuidString,
        title: String,
        authors: [String],
        publishYear: Int? = nil,
        isbn: String? = nil,
        coverURL: String? = nil,
        localCoverFilename: String? = nil,
        addedDate: Date = Date(),
        quotes: [Quote] = []
    ) {
        self.id = id
        self.title = title
        self.authors = authors
        self.publishYear = publishYear
        self.isbn = isbn
        self.coverURL = coverURL
        self.localCoverFilename = localCoverFilename
        self.addedDate = addedDate
        self.quotes = quotes
    }
}
