// Services/Storage/RecentlyUsedLanguageStore.swift
import Foundation

@MainActor
final class RecentlyUsedLanguageStore {
    static let shared = RecentlyUsedLanguageStore()
    private init() {}

    private let key = "recent.languages"
    private let maxCount = 8
    private let defaults = UserDefaults.standard

    func load() -> [String] {
        (defaults.array(forKey: key) as? [String]) ?? []
    }

    func add(code: String) {
        var current = load().filter { $0.lowercased() != code.lowercased() }
        current.insert(code.lowercased(), at: 0)
        if current.count > maxCount {
            current = Array(current.prefix(maxCount))
        }
        defaults.set(current, forKey: key)
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }
}
