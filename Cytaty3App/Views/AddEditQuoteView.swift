// Views/AddEditQuoteView.swift
import SwiftUI

struct AddEditQuoteView: View {
    enum Mode: Equatable { case add, edit(Quote) }

    let mode: Mode
    let onComplete: (Quote?) -> Void

    @StateObject private var vm: AddEditQuoteViewModel

    init(mode: Mode, onComplete: @escaping (Quote?) -> Void) {
        self.mode = mode
        self.onComplete = onComplete
        switch mode {
        case .add: _vm = StateObject(wrappedValue: AddEditQuoteViewModel(quote: nil))
        case .edit(let q): _vm = StateObject(wrappedValue: AddEditQuoteViewModel(quote: q))
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text("QUOTE_CONTENT_LABEL").font(.subheadline).foregroundColor(.secondary)
                WrappedTextView(text: $vm.content)
                    .frame(minHeight: 200, maxHeight: 300)

                HStack {
                    TextField(String(localized: "QUOTE_PAGE_PLACEHOLDER"), text: $vm.page)
                        .keyboardType(.numberPad)
                    TextField(String(localized: "QUOTE_CHAPTER_PLACEHOLDER"), text: $vm.chapter)
                }

                TextField(String(localized: "QUOTE_TAGS_PLACEHOLDER"), text: $vm.tagsText)
                TextField(String(localized: "QUOTE_NOTE_PLACEHOLDER"), text: $vm.note)

                Spacer()
            }
            .padding()
            .navigationTitle(modeTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "CANCEL")) { onComplete(nil) }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "SAVE")) { onComplete(vm.buildQuote()) }
                        .disabled(vm.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private var modeTitle: String {
        switch mode {
        case .add: return String(localized: "QUOTE_TITLE_ADD")
        case .edit: return String(localized: "QUOTE_TITLE_EDIT")
        }
    }
}
