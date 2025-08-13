// Models/LibraryRoot.swift
import Foundation

public struct LibraryRoot: Codable {
    public var schemaVersion: Int
    public var books: [Book]

    public init(schemaVersion: Int = 2, books: [Book] = []) {
        self.schemaVersion = schemaVersion
        self.books = books
    }
}
