// GympanionApp/presentation/common/navigation/AppRouter.swift
import SwiftUI

@Observable
final class AppRouter {
    var path = NavigationPath()
    var isAuthenticated = false

    func navigate(to route: AppRoute) {
        path.append(route)
    }

    func popToRoot() {
        path.removeLast(path.count)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}
