// GympanionApp/domain/model/LiveWorkoutStatus.swift
import Foundation

enum LiveSessionPhase: Int {
    case idle = 0
    case work = 1
    case rest = 2
    case finished = 3
    case blockComplete = 4
}

struct LiveExerciseSummary: Equatable {
    let name: String
    let targetSets: Int
    let targetReps: Int
}

struct LiveWorkoutPlan: Equatable {
    let id: String
    let name: String
    let exercises: [LiveExerciseSummary]
}

struct LiveWorkoutStatus: Equatable {
    let exerciseName: String
    let currentExerciseIndex: Int
    let currentSetIndex: Int
    let completedSets: Int
    let completedReps: Int
    let heartRate: Int?
    let phase: LiveSessionPhase
    let workout: LiveWorkoutPlan
    let receivedAt: Date
}
