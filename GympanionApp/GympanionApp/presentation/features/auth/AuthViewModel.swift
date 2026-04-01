// GympanionApp/presentation/features/auth/AuthViewModel.swift
import Foundation

@Observable
final class AuthViewModel {
    var loginState: UiState<User> = .idle
    var registerState: UiState<User> = .idle

    private let useCase: AuthUseCase

    init(useCase: AuthUseCase) {
        self.useCase = useCase
    }

    func login(email: String, password: String) async {
        loginState = .loading
        let result = await useCase.login(email: email, password: password)
        switch result {
        case .success(let user): loginState = .success(user)
        case .failure(let error): loginState = .error(error.localizedDescription)
        }
    }

    func register(email: String, password: String, displayName: String) async {
        registerState = .loading
        let result = await useCase.register(email: email, password: password, displayName: displayName)
        switch result {
        case .success(let user): registerState = .success(user)
        case .failure(let error): registerState = .error(error.localizedDescription)
        }
    }
}
