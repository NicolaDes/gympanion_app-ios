// GympanionApp/data/remote/dto/ExerciseDto.swift
import Foundation

struct ExerciseParamsDto: Codable {
    let sets: Int?
    let reps: Int?
    let durationSeconds: Int?
    let distanceMeters: Double?
    let weightKg: Double?
    let restSeconds: Int?
}

struct ExerciseDto: Codable {
    let id: String
    let name: String
    let description: String?
    let category: String
    let primaryMuscleGroups: [String]
    let secondaryMuscleGroups: [String]
    let defaultParams: ExerciseParamsDto?
    let isCustom: Bool
    let createdAt: Date
    let updatedAt: Date
}
