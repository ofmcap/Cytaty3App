// Tests/ViewModelsTests.swift
import XCTest
@testable import Cytaty3App

final class ViewModelsTests: XCTestCase {
    func testLibraryAddBook() throws {
        let svc = StorageServiceJSON(filename: "vm_test_library.json")
        let vm = LibraryViewModel(storage: svc)
        let book = Book(title: "Nowa", authors: ["Autor"], addedDate: Date())
        vm.addBook(book)
        let exp = expectation(description: "mutate")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)
        XCTAssertTrue(vm.books.contains(where: { $0.title == "Nowa" }))
    }
}
