// GympanionApp/domain/model/Analytics.swift
import Foundation

struct ProgressPoint: Equatable {
    let date: Date
    let value: Double
    let unit: String
}

struct PersonalRecord: Identifiable, Equatable {
    let id: String
    let exerciseId: String
    let exerciseName: String
    let value: Double
    let unit: String
    let achievedAt: Date
    let sessionId: String
}

struct Analytics: Equatable {
    let totalSessions: Int
    let totalVolumeKg: Double
    let totalDurationMinutes: Int
    let weeklyActivity: [ProgressPoint]
    let personalRecords: [PersonalRecord]
    let exerciseProgress: [String: [ProgressPoint]]   // exerciseId → progress
}
