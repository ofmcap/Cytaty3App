// Tests/StorageServiceJSONTests.swift
import XCTest
@testable import Cytaty3App

final class StorageServiceJSONTests: XCTestCase {

    func testSaveAndLoadLibrary() throws {
        let svc = StorageServiceJSON(filename: "test_library.json")
        let q = Quote(content: "Lorem ipsum", page: 12)
        let b = Book(title: "Książka", authors: ["Autor"], quotes: [q], addedDate: Date())
        let root = LibraryRoot(schemaVersion: svc.currentSchemaVersion, books: [b])

        try svc.saveLibrary(root)
        let loaded = try svc.loadLibrary()

        XCTAssertEqual(loaded.books.count, 1)
        XCTAssertEqual(loaded.books[0].title, "Książka")
        XCTAssertEqual(loaded.books[0].authors.first, "Autor")
        XCTAssertEqual(loaded.books[0].quotes.count, 1)
    }
}
