// Views/SearchBooksView.swift
import SwiftUI

struct SearchBooksView: View {
    let network: NetworkService
    let onPick: (BookSearchResult) -> Void

    @StateObject private var vm: SearchBooksViewModel

    init(network: NetworkService, onPick: @escaping (BookSearchResult) -> Void) {
        self.network = network
        self.onPick = onPick
        _vm = StateObject(wrappedValue: SearchBooksViewModel(network: network))
    }

    var body: some View {
        NavigationStack {
            List {
                if let err = vm.errorText, vm.results.isEmpty {
                    Text(err).foregroundColor(.red)
                }

                ForEach(vm.results) { r in
                    Button {
                        onPick(r)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(r.title).font(.headline)
                            Text(r.authors.joined(separator: ", "))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .onAppear {
                        // Auto-dociąganie gdy dojeżdżamy do końca listy
                        if r.id == vm.results.last?.id {
                            vm.loadMore()
                        }
                    }
                }

                // Wiersz paginacji: Pokaż więcej / Ładowanie… / Retry
                if vm.hasMore || vm.isLoadingMore || (vm.errorText != nil && !vm.results.isEmpty) {
                    HStack {
                        if vm.isLoadingMore {
                            ProgressView().padding(.trailing, 8)
                            Text("Ładowanie...")
                        } else if vm.errorText != nil {
                            Button("Spróbuj ponownie") {
                                vm.loadMore()
                            }
                        } else {
                            Button("Pokaż więcej") {
                                vm.loadMore()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Szukaj książek")
            .searchable(text: $vm.query, placement: .navigationBarDrawer(displayMode: .always))
            .onChange(of: vm.query) { newValue in
                vm.onQueryChange(newValue)
            }
            .overlay(alignment: .center) {
                if vm.isLoadingFirstPage {
                    ProgressView().controlSize(.large)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    // zamknięcie realizowane przez wybór wyniku — przycisk ukryty
                    Button("Zamknij") {
                        onPick(.init(id: "", title: "", authors: [], publishYear: nil, isbn: nil, coverURL: nil))
                    }
                    .opacity(0)
                }
            }
        }
    }
}
