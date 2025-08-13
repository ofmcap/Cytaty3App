// Models/Quote.swift
import Foundation

public struct Quote: Identifiable, Codable, Equatable {
    public let id: String
    public var content: String
    public var page: Int?
    public var chapter: String?
    public var tags: [String]
    public var note: String?
    public var addedDate: Date

    public init(
        id: String = UUID().uuidString,
        content: String,
        page: Int? = nil,
        chapter: String? = nil,
        tags: [String] = [],
        note: String? = nil,
        addedDate: Date = Date()
    ) {
        self.id = id
        self.content = content
        self.page = page
        self.chapter = chapter
        self.tags = tags
        self.note = note
        self.addedDate = addedDate
    }
}
