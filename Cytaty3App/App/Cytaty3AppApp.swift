// App/Cytaty3AppApp.swift
import SwiftUI

@main
struct Cytaty3AppApp: App {
    @StateObject private var router = AppRouter()
    @StateObject private var modal = ModalManager()

    private let storage: StorageService = StorageServiceJSON()
    private let network: NetworkService = GoogleBooksNetworkService(apiKey: "AIzaSyCyiWXe5jxx8NBvN0N8tu0eWGvZaDCxudo")
    private let imageCache = ImageCacheService()

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path) {
                LibraryView(
                    viewModel: LibraryViewModel(storage: storage),
                    network: network,
                    imageCache: imageCache
                )
                .navigationDestination(for: NavigationRoute.self) { route in
                    switch route {
                    case .bookDetail(let id):
                        BookDetailView(
                            viewModel: BookDetailViewModel(storage: storage, bookID: id),
                            imageCache: imageCache
                        )
                    }
                }
            }
            .environmentObject(router)
            .environmentObject(modal)
        }
    }
}
