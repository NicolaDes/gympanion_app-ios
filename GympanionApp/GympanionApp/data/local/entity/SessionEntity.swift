// GympanionApp/data/local/entity/SessionEntity.swift
import Foundation
import SwiftData

@Model
final class SessionEntity {
    @Attribute(.unique) var id: String
    var workoutId: String
    var workoutName: String
    var startedAt: Date
    var completedAt: Date?
    var notes: String?
    var garminDeviceId: String?

    init(id: String, workoutId: String, workoutName: String, startedAt: Date,
         completedAt: Date? = nil, notes: String? = nil, garminDeviceId: String? = nil) {
        self.id = id
        self.workoutId = workoutId
        self.workoutName = workoutName
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.notes = notes
        self.garminDeviceId = garminDeviceId
    }
}
