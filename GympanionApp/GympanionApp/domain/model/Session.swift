// GympanionApp/domain/model/Session.swift
import Foundation

struct SetRecord: Equatable {
    let setNumber: Int
    let reps: Int?
    let weightKg: Double?
    let durationSeconds: Int?
    let distanceMeters: Double?
    let completedAt: Date
}

struct Session: Identifiable, Equatable {
    let id: String
    let workoutId: String
    let workoutName: String
    let startedAt: Date
    let completedAt: Date?
    let sets: [String: [SetRecord]]   // exerciseId → set records (v1)
    let notes: String?
    let garminDeviceId: String?
    let blockResults: [BlockResult]?  // v2 block-aware results, nil for v1
    let totalDurationSeconds: Int?    // v2: wall-clock duration
}
