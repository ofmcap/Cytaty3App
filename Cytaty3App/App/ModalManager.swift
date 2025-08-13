// App/ModalManager.swift
import SwiftUI

@MainActor
final class ModalManager: ObservableObject {
    @Published var isPresentingAddQuoteFullScreen: Bool = false
    @Published var editingQuote: Quote? = nil
    @Published var navGate: Bool = false

    func openAddQuote() {
        guard !navGate else { return }
        navGate = true
        isPresentingAddQuoteFullScreen = true
        debugLog("willPresent AddQuote")
    }

    func dismissAddQuote() {
        isPresentingAddQuoteFullScreen = false
        debugLog("willDismiss AddQuote")
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 220_000_000)
            self.navGate = false
            debugLog("didDismiss AddQuote")
        }
    }

    func openEditQuote(_ quote: Quote) {
        guard !navGate else { return }
        navGate = true
        editingQuote = quote
        debugLog("willPresent EditQuote")
    }

    func dismissEditQuote() {
        editingQuote = nil
        debugLog("willDismiss EditQuote")
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 220_000_000)
            self.navGate = false
            debugLog("didDismiss EditQuote")
        }
    }
}

@MainActor
func mutateAfterDismiss(_ action: @escaping () -> Void) {
    Task { @MainActor in
        debugLog("willMutate")
        try? await Task.sleep(nanoseconds: 220_000_000)
        action()
        debugLog("didMutate")
    }
}
