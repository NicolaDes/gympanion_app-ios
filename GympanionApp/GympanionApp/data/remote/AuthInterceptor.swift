// GympanionApp/data/remote/AuthInterceptor.swift
import Foundation

struct AuthInterceptor {
    private let keychainKey = "jwt_token"

    func apply(to request: URLRequest) -> URLRequest {
        var req = request
        if let token = KeychainHelper.shared.read(key: keychainKey) {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return req
    }
}
