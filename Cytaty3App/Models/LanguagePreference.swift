import Foundation

public enum LanguagePreference: Equatable, Codable {
    case any
    case code(String) // np. "pl", "en"

    public var langRestrictValue: String? {
        switch self {
        case .any: return nil
        case .code(let c): return c.lowercased()
        }
    }

    public var displayCode: String {
        switch self {
        case .any: return "ANY"
        case .code(let c): return c.uppercased()
        }
    }
}
