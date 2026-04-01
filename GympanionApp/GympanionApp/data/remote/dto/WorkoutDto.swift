// GympanionApp/data/remote/dto/WorkoutDto.swift
import Foundation

struct WorkoutExerciseDto: Codable {
    let id: String
    let exerciseId: String
    let order: Int
    let params: ExerciseParamsDto?
    let notes: String?
}

struct WorkoutDto: Codable {
    let id: String
    let name: String
    let description: String?
    let exercises: [WorkoutExerciseDto]
    let estimatedDurationMinutes: Int
    let createdAt: Date
    let updatedAt: Date
}
