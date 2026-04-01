// GympanionApp/domain/model/Exercise.swift
import Foundation

enum ExerciseCategory: String, Codable, CaseIterable {
    case strength, cardio, flexibility, balance, plyometric, sport
}

enum MuscleGroup: String, Codable, CaseIterable {
    case chest, back, shoulders, biceps, triceps, forearms, core
    case glutes, quadriceps, hamstrings, calves, fullBody
}

struct ExerciseParams: Equatable {
    let sets: Int?
    let reps: Int?
    let durationSeconds: Int?
    let distanceMeters: Double?
    let weightKg: Double?
    let restSeconds: Int?
}

struct Exercise: Identifiable, Equatable {
    let id: String
    let name: String
    let description: String?
    let category: ExerciseCategory
    let primaryMuscleGroups: [MuscleGroup]
    let secondaryMuscleGroups: [MuscleGroup]
    let defaultParams: ExerciseParams
    let isCustom: Bool
    let createdAt: Date
    let updatedAt: Date
}
