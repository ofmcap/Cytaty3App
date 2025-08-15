import SwiftUI

public struct LanguagePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    public let selection: (LanguagePreference) -> Void

    @State private var search: String = ""
    @State private var allLanguages: [LanguageItem] = []
    @State private var recentLanguages: [LanguageItem] = []

    private let recents = RecentlyUsedLanguageStore.shared

    public init(selection: @escaping (LanguagePreference) -> Void) {
        self.selection = selection
    }

    public var body: some View {
        NavigationView {
            List {
                // Any
                Section {
                    Button {
                        // Najpierw zamknięcie, później mutacja stanu u klienta
                        dismiss()
                        mutateAfterDismiss { selection(.any) }
                    } label: {
                        HStack {
                            Text(String(localized: "LANG_ANY"))
                            Spacer()
                        }
                    }
                    .accessibilityLabel(Text("LANG_ANY"))
                }

                // Recently used
                if search.trimmed.isEmpty, !recentLanguages.isEmpty {
                    Section(header: Text("RECENT_LANGUAGES")) {
                        ForEach(recentLanguages) { item in
                            LanguageRow(
                                item: item,
                                isSelected: false
                            ) {
                                select(code: item.code)
                            }
                        }
                        Button(role: .destructive) {
                            recents.clear()
                            recentLanguages = []
                        } label: {
                            Label(String(localized: "CLEAR_RECENTS"), systemImage: "trash")
                        }
                        .accessibilityLabel(Text("CLEAR_RECENTS"))
                    }
                }

                // All languages
                Section(header: Text("ALL_LANGUAGES")) {
                    ForEach(filteredAll) { item in
                        LanguageRow(
                            item: item,
                            isSelected: false
                        ) {
                            select(code: item.code)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(Text("LANG_PICKER_TITLE"))
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $search,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text("LANG_SEARCH_PLACEHOLDER")
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "CLOSE")) { dismiss() }
                }
            }
            .onAppear {
                loadData()
            }
        }
    }

    private var filteredAll: [LanguageItem] {
        guard !search.trimmed.isEmpty else { return allLanguages }
        return allLanguages.filter { $0.matches(search) }
    }

    private func select(code: String) {
        recents.add(code: code)
        dismiss()
        mutateAfterDismiss { selection(.code(code)) }
    }

    private func loadData() {
        let all = LanguageItem.iso639_1All()
        allLanguages = all
        recentLanguages = recents.load()
            .compactMap { code in all.first(where: { $0.code.caseInsensitiveCompare(code) == .orderedSame }) }
    }
}

// MARK: - Row

private struct LanguageRow: View {
    let item: LanguageItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(item.displayName)
                    .foregroundColor(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                        .accessibilityHidden(true)
                } else {
                    Text(item.code.uppercased())
                        .foregroundColor(.secondary)
                }
            }
        }
        .accessibilityLabel(Text(item.accessibilityLabel))
        .accessibilityHint(Text("LANGUAGE_CHIP_HINT"))
    }
}

// MARK: - Helpers

private struct LanguageItem: Identifiable, Equatable {
    let code: String   // ISO-639-1, np. "pl"
    let name: String   // z Locale, np. "Polish"
    var id: String { code }

    var displayName: String {
        "\(name) (\(code.uppercased()))"
    }

    var accessibilityLabel: String {
        // "Język: Polish" / "Language: Polish"
        String(localized: "LANGUAGE_CHIP_LABEL %@", defaultValue: "Language: %@")
            .replacingOccurrences(of: "%@", with: name)
    }

    func matches(_ query: String) -> Bool {
        let q = query.folding(options: .diacriticInsensitive, locale: .current).lowercased()
        let n = name.folding(options: .diacriticInsensitive, locale: .current).lowercased()
        return n.contains(q) || code.lowercased().contains(q)
    }

    static func iso639_1All() -> [LanguageItem] {
        // iOS 16+: Locale.LanguageCode.isoLanguageCodes → [Locale.LanguageCode]
        // Używamy .identifier, filtrujemy 2‑literowe kody i sortujemy po nazwie.
        let codes = Locale.LanguageCode.isoLanguageCodes
            .map { $0.identifier }
            .filter { $0.count == 2 }

        let current = Locale.current
        let items = codes.map { code -> LanguageItem in
            let name = current.localizedString(forLanguageCode: code)?.capitalized(with: current) ?? code.uppercased()
            return LanguageItem(code: code, name: name)
        }

        let unique = Dictionary(grouping: items, by: { $0.code.lowercased() }).compactMap { $0.value.first }
        return unique.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}

// MARK: - String helpers (file scope)

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
