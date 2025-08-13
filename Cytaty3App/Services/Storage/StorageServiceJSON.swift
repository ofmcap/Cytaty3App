// Services/Storage/StorageServiceJSON.swift
import Foundation

public final class StorageServiceJSON: StorageService {
    public let currentSchemaVersion: Int = 2

    private let fileURL: URL
    private let fm = FileManager.default
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(filename: String = "library.json") {
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = docs.appendingPathComponent(filename)
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder.dateDecodingStrategy = .iso8601
    }

    public func loadLibrary() throws -> LibraryRoot {
        if !fm.fileExists(atPath: fileURL.path) {
            return LibraryRoot(schemaVersion: currentSchemaVersion, books: [])
        }
        let data = try Data(contentsOf: fileURL)
        let version = try Self.peekSchemaVersion(from: data) ?? 1
        let migratedData: Data
        if version != currentSchemaVersion {
            migratedData = try SchemaMigration.migrateIfNeeded(data: data, fromVersion: version, toVersion: currentSchemaVersion)
        } else {
            migratedData = data
        }
        var library = try decoder.decode(LibraryRoot.self, from: migratedData)
        if library.schemaVersion != currentSchemaVersion {
            library.schemaVersion = currentSchemaVersion
            try saveLibrary(library)
        }
        return library
    }

    public func saveLibrary(_ library: LibraryRoot) throws {
        var lib = library
        lib.schemaVersion = currentSchemaVersion
        let data = try encoder.encode(lib)
        let tempURL = fileURL.appendingPathExtension("tmp")
        try data.write(to: tempURL, options: .atomic)
        if fm.fileExists(atPath: fileURL.path) {
            _ = try fm.replaceItemAt(fileURL, withItemAt: tempURL)
        } else {
            try fm.moveItem(at: tempURL, to: fileURL)
        }
    }

    private static func peekSchemaVersion(from data: Data) throws -> Int? {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json?["schemaVersion"] as? Int
    }
}
