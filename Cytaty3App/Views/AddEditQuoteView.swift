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
                Text("Treść cytatu").font(.subheadline).foregroundColor(.secondary)
                WrappedTextView(text: $vm.content)
                    .frame(minHeight: 200, maxHeight: 300)

                HStack {
                    TextField("Strona", text: $vm.page)
                        .keyboardType(.numberPad)
                    TextField("Rozdział", text: $vm.chapter)
                }

                TextField("Tagi (oddzielone przecinkami)", text: $vm.tagsText)
                TextField("Notatka (opcjonalnie)", text: $vm.note)

                Spacer()
            }
            .padding()
            .navigationTitle(modeTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") { onComplete(nil) }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Zapisz") { onComplete(vm.buildQuote()) }
                        .disabled(vm.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private var modeTitle: String {
        switch mode { case .add: return "Nowy cytat"; case .edit: return "Edytuj cytat" }
    }
}
