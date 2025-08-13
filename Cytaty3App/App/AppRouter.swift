// App/AppRouter.swift
import SwiftUI

@MainActor
final class AppRouter: ObservableObject {
    @Published var path: [NavigationRoute] = []
    func goToBookDetail(_ id: String) { path.append(.bookDetail(bookID: id)) }
    func pop() { if !path.isEmpty { path.removeLast() } }
}
