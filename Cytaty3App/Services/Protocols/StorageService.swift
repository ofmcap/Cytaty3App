// Services/Protocols/StorageService.swift
import Foundation

public protocol StorageService {
    func loadLibrary() throws -> LibraryRoot
    func saveLibrary(_ library: LibraryRoot) throws
    var currentSchemaVersion: Int { get }
}
