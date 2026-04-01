// GympanionApp/data/remote/dto/SessionDto.swift
import Foundation

struct SetRecordDto: Codable {
    let setNumber: Int
    let reps: Int?
    let weightKg: Double?
    let durationSeconds: Int?
    let distanceMeters: Double?
    let completedAt: Date
}

struct SessionDto: Codable {
    let id: String
    let workoutId: String
    let workoutName: String
    let startedAt: Date
    let completedAt: Date?
    let sets: [String: [SetRecordDto]]
    let notes: String?
    let garminDeviceId: String?
}
