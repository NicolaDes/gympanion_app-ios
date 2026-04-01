// GympanionApp/domain/repository/AuthRepository.swift
import Foundation

protocol AuthRepository {
    func currentUser() -> AsyncStream<User?>
    func login(email: String, password: String) async -> Result<User, Error>
    func register(email: String, password: String, displayName: String) async -> Result<User, Error>
    func logout() async
    func refreshToken() async -> Result<Void, Error>
    func isAuthenticated() -> AsyncStream<Bool>
}
