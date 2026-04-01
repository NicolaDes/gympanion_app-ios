// GympanionApp/domain/model/User.swift
import Foundation

enum UnitSystem: String, Codable {
    case metric, imperial
}

struct UserPreferences: Equatable {
    let unitSystem: UnitSystem
    let notificationsEnabled: Bool
    let garminSyncEnabled: Bool
}

struct User: Identifiable, Equatable {
    let id: String
    let email: String
    let displayName: String
    let avatarUrl: String?
    let createdAt: Date
    let preferences: UserPreferences
}
