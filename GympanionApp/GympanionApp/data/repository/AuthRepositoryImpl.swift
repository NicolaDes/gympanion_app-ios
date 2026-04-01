// GympanionApp/data/repository/AuthRepositoryImpl.swift
import Foundation

final class AuthRepositoryImpl: AuthRepository {
    private let apiService: any ApiServiceProtocol
    private let keychainHelper: KeychainHelper
    private let tokenKey = "jwt_token"

    init(apiService: any ApiServiceProtocol, keychainHelper: KeychainHelper) {
        self.apiService = apiService
        self.keychainHelper = keychainHelper
    }

    func currentUser() -> AsyncStream<User?> {
        AsyncStream { continuation in
            let user = storedUser()
            continuation.yield(user)
            continuation.finish()
        }
    }

    func isAuthenticated() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            continuation.yield(keychainHelper.read(key: tokenKey) != nil)
            continuation.finish()
        }
    }

    func login(email: String, password: String) async -> Result<User, Error> {
        do {
            let token = try await apiService.login(email: email, password: password)
            keychainHelper.save(key: tokenKey, value: token)
            let user = userFromJWT(token) ?? placeholderUser(email: email)
            return .success(user)
        } catch {
            return .failure(error)
        }
    }

    func register(email: String, password: String, displayName: String) async -> Result<User, Error> {
        do {
            let token = try await apiService.register(email: email, password: password, displayName: displayName)
            keychainHelper.save(key: tokenKey, value: token)
            let user = userFromJWT(token) ?? placeholderUser(email: email, displayName: displayName)
            return .success(user)
        } catch {
            return .failure(error)
        }
    }

    func logout() async {
        keychainHelper.delete(key: tokenKey)
    }

    func refreshToken() async -> Result<Void, Error> {
        // No refresh endpoint defined yet — succeed silently if token exists
        if keychainHelper.read(key: tokenKey) != nil {
            return .success(())
        }
        return .failure(URLError(.userAuthenticationRequired))
    }

    // MARK: - Helpers

    private func storedUser() -> User? {
        guard let token = keychainHelper.read(key: tokenKey) else { return nil }
        return userFromJWT(token)
    }

    /// Decodes JWT payload (base64url) to extract user fields if present.
    private func userFromJWT(_ token: String) -> User? {
        let parts = token.split(separator: ".")
        guard parts.count == 3 else { return nil }
        var payload = String(parts[1])
        // Base64url → Base64
        payload = payload.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        let remainder = payload.count % 4
        if remainder > 0 { payload += String(repeating: "=", count: 4 - remainder) }
        guard let data = Data(base64Encoded: payload),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let id = json["sub"] as? String,
              let email = json["email"] as? String else { return nil }
        let displayName = json["name"] as? String ?? email
        return User(
            id: id,
            email: email,
            displayName: displayName,
            avatarUrl: nil,
            createdAt: Date(),
            preferences: UserPreferences(unitSystem: .metric, notificationsEnabled: true, garminSyncEnabled: false)
        )
    }

    private func placeholderUser(email: String, displayName: String? = nil) -> User {
        User(
            id: UUID().uuidString,
            email: email,
            displayName: displayName ?? email,
            avatarUrl: nil,
            createdAt: Date(),
            preferences: UserPreferences(unitSystem: .metric, notificationsEnabled: true, garminSyncEnabled: false)
        )
    }
}
