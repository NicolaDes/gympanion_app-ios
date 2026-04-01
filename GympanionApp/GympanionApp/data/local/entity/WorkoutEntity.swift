// GympanionApp/data/local/entity/WorkoutEntity.swift
import Foundation
import SwiftData

@Model
final class WorkoutEntity {
    @Attribute(.unique) var id: String
    var name: String
    var workoutDescription: String?
    var estimatedDurationMinutes: Int
    var createdAt: Date
    var updatedAt: Date

    init(id: String, name: String, estimatedDurationMinutes: Int,
         description: String? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.workoutDescription = description
        self.estimatedDurationMinutes = estimatedDurationMinutes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
