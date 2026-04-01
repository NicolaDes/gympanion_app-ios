// GympanionApp/domain/usecase/AuthUseCase.swift
import Foundation

final class AuthUseCase {
    private let repository: any AuthRepository

    init(repository: any AuthRepository) {
        self.repository = repository
    }

    func currentUser() -> AsyncStream<User?> {
        repository.currentUser()
    }

    func isAuthenticated() -> AsyncStream<Bool> {
        repository.isAuthenticated()
    }

    func login(email: String, password: String) async -> Result<User, Error> {
        await repository.login(email: email, password: password)
    }

    func register(email: String, password: String, displayName: String) async -> Result<User, Error> {
        await repository.register(email: email, password: password, displayName: displayName)
    }

    func logout() async {
        await repository.logout()
    }
}
