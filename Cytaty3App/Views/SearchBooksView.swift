// Views/SearchBooksView.swift
import SwiftUI

struct SearchBooksView: View {
    let network: NetworkService
    let onPick: (BookSearchResult) -> Void

    @StateObject private var vm: SearchBooksViewModel
    @State private var showLangSheet = false

    init(network: NetworkService, onPick: @escaping (BookSearchResult) -> Void) {
        self.network = network
        self.onPick = onPick
        _vm = StateObject(wrappedValue: SearchBooksViewModel(network: network))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                content

                if let err = vm.errorText, !err.isEmpty {
                    ErrorBanner(message: err) {
                        if vm.results.isEmpty {
                            Task { await vm.loadFirstPage() }
                        } else {
                            vm.loadMore()
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                }
            }
            .navigationTitle(Text("SEARCH_TITLE"))
            .searchable(text: $vm.query, placement: .navigationBarDrawer(displayMode: .always), prompt: Text("SEARCH_PLACEHOLDER"))
            .onChange(of: vm.query) { newValue in
                vm.onQueryChange(newValue)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    LanguageChip(lang: vm.preferredLanguage) {
                        showLangSheet = true
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "CLOSE")) {
                        onPick(.init(id: "", title: "", authors: [], publishYear: nil, isbn: nil, coverURL: nil))
                    }
                    .opacity(0) // zachowanie istniejące
                }
            }
        }
        .sheet(isPresented: $showLangSheet) {
            LanguagePickerSheet { selected in
                // Picker samodzielnie zamyka i woła mutateAfterDismiss,
                // tu tylko ustawiamy preferencję i przeładowujemy pierwszą stronę.
                vm.setPreferredLanguage(selected)
                Task { await vm.loadFirstPage() }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if vm.query.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 {
            InformationalEmptyStateView(
                title: "SEARCH_START_TITLE",
                message: "SEARCH_START_MESSAGE",
                systemImage: "magnifyingglass.circle"
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else if vm.results.isEmpty && !vm.isLoadingFirstPage && vm.errorText == nil {
            NoResultsEmptyStateView(queryText: vm.query)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else {
            List {
                ForEach(vm.results) { r in
                    Button {
                        onPick(r)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(r.title).font(.headline).foregroundColor(.primary).lineLimit(2)
                            if !r.authors.isEmpty {
                                Text(r.authors.joined(separator: ", "))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            if let y = r.publishYear {
                                Text(String(y))
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(accessibilityLabel(for: r))
                    .accessibilityHint(Text("BOOK_ROW_HINT"))
                    .onAppear {
                        if r.id == vm.results.last?.id {
                            vm.loadMore()
                        }
                    }
                }

                // Paginacja / loader / retry w stopce listy
                if vm.hasMore || vm.isLoadingMore || (vm.errorText != nil && !vm.results.isEmpty) {
                    HStack {
                        if vm.isLoadingMore {
                            ProgressView().padding(.trailing, 8)
                            Text("LOADING_MORE")
                        } else if vm.errorText != nil {
                            Button("RETRY") { vm.loadMore() }
                        } else {
                            Button("SHOW_MORE") { vm.loadMore() }
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .listStyle(.plain)
            .overlay(alignment: .center) {
                if vm.isLoadingFirstPage && vm.results.isEmpty {
                    VStack(spacing: 12) {
                        ProgressView().controlSize(.large)
                        Text("LOADING")
                    }
                }
            }
        }
    }

    private func accessibilityLabel(for r: BookSearchResult) -> Text {
        let parts: [String] = [
            r.title,
            r.authors.joined(separator: ", "),
            r.publishYear.map { String($0) } ?? ""
        ].filter { !$0.isEmpty }
        return Text(parts.joined(separator: ", "))
    }
}

// MARK: - Lightweight components (local to this file)

private struct InformationalEmptyStateView: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let systemImage: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 44, weight: .semibold))
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
            Text(title).font(.title3).fontWeight(.semibold).multilineTextAlignment(.center)
            Text(message).font(.body).foregroundColor(.secondary).multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 40)
        .accessibilityElement(children: .combine)
    }
}

private struct NoResultsEmptyStateView: View {
    let queryText: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "books.vertical")
                .font(.system(size: 36, weight: .regular))
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
            Text("NO_RESULTS_TITLE")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            // Użycie LocalizedStringKey z interpolacją, zgodne z iOS 16
            Text("NO_RESULTS_MESSAGE \(queryText)")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("NO_RESULTS_TITLE"))
    }
}

private struct ErrorBanner: View {
    let message: String
    let retry: () -> Void
    @State private var isVisible = true

    var body: some View {
        if isVisible {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)
                    .accessibilityHidden(true)
                Text(message)
                    .font(.callout)
                    .foregroundColor(.primary)
                    .lineLimit(3)
                Spacer(minLength: 8)
                Button("RETRY", action: retry)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.mini)
                Button {
                    withAnimation { isVisible = false }
                } label: {
                    Image(systemName: "xmark").foregroundColor(.secondary)
                }
                .accessibilityLabel(Text("CLOSE"))
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(radius: 2)
            .transition(.move(edge: .top).combined(with: .opacity))
            .accessibilityElement(children: .combine)
        }
    }
}
