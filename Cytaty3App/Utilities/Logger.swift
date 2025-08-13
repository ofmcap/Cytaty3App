// Utilities/Logger.swift
import Foundation
func debugLog(_ message: String) {
    #if DEBUG
    print("[DEBUG] \(message)")
    #endif
}
