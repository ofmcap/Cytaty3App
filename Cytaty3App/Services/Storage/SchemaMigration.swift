// Services/Storage/SchemaMigration.swift
import Foundation

enum SchemaMigration {
    // Prosta migracja v1 -> v2:
    // - Book.author:String -> Book.authors:[String]
    // - Book.addedDate:Date dodane (ustawiamy na "teraz" przy migracji)
    static func migrateIfNeeded(data: Data, fromVersion: Int, toVersion: Int) throws -> Data {
        var migrated = data
        var version = fromVersion

        while version < toVersion {
            switch version {
            case 1:
                migrated = try migrateV1toV2(migrated)
            default:
                break
            }
            version += 1
        }
        return migrated
    }

    private static func migrateV1toV2(_ data: Data) throws -> Data {
        // Minimalna migracja przez JSONSerialization
        guard var root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return data
        }
        var books = (root["books"] as? [[String: Any]]) ?? []
        let nowISO = ISO8601DateFormatter().string(from: Date())

        for i in books.indices {
            var b = books[i]
            if let author = b["author"] as? String {
                b["authors"] = [author]
                b.removeValue(forKey: "author")
            } else if b["authors"] == nil {
                b["authors"] = []
            }
            if b["addedDate"] == nil {
                b["addedDate"] = nowISO
            }
            books[i] = b
        }

        root["books"] = books
        root["schemaVersion"] = 2
        return try JSONSerialization.data(withJSONObject: root, options: .prettyPrinted)
    }
}
