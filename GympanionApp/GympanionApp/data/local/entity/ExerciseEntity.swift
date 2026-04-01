// GympanionApp/data/local/entity/ExerciseEntity.swift
import Foundation
import SwiftData

@Model
final class ExerciseEntity {
    @Attribute(.unique) var id: String
    var name: String
    var exerciseDescription: String?
    var category: String
    var primaryMuscleGroups: [String]
    var secondaryMuscleGroups: [String]
    var isCustom: Bool
    var createdAt: Date
    var updatedAt: Date

    init(id: String, name: String, category: String, isCustom: Bool,
         description: String? = nil, primaryMuscleGroups: [String] = [],
         secondaryMuscleGroups: [String] = [], createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.exerciseDescription = description
        self.category = category
        self.primaryMuscleGroups = primaryMuscleGroups
        self.secondaryMuscleGroups = secondaryMuscleGroups
        self.isCustom = isCustom
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
