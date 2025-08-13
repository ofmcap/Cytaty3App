// Utilities/Debouncer.swift
import Foundation

actor Debouncer {
    private var task: Task<Void, Never>?
    func debounce(milliseconds: Int = 300, action: @escaping () -> Void) {
        task?.cancel()
        task = Task {
            try? await Task.sleep(nanoseconds: UInt64(milliseconds) * 1_000_000)
            if Task.isCancelled { return }
            action()
        }
    }
}
