// GympanionApp/domain/model/Workout.swift
import Foundation

struct WorkoutExercise: Identifiable, Equatable {
    let id: String
    let exercise: Exercise
    let order: Int
    let params: ExerciseParams
    let notes: String?
}

struct Workout: Identifiable, Equatable {
    let id: String
    let name: String
    let description: String?
    let exercises: [WorkoutExercise]
    let estimatedDurationMinutes: Int
    let createdAt: Date
    let updatedAt: Date
    let blocks: [WorkoutBlock]?  // v2 block-based structure, nil for v1 workouts
}
