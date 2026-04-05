// GympanionApp/domain/model/SessionResult.swift
import Foundation

struct SetResult: Equatable {
    let setIndex: Int
    let reps: Int?
    let weightKg: Double?
    let durationMs: Int
    let distanceMeters: Double?
    let avgHeartRate: Int?
    let peakHeartRate: Int?
    let completedAt: Date
    let skipped: Bool
}

// MARK: - Block results

struct ExerciseResult: Equatable {
    let exerciseId: String
    let sets: [SetResult]
}

struct EmomRoundResult: Equatable {
    let roundIndex: Int
    let timeToCompleteSeconds: Int
    let timeRemainingSeconds: Int
    let sets: [SetResult]
}

struct AmrapRoundResult: Equatable {
    let roundIndex: Int
    let durationMs: Int
    let isPartial: Bool
    let sets: [SetResult]
}

enum BlockResult: Equatable {
    case sequential(blockIndex: Int, exercises: [ExerciseResult])
    case emom(blockIndex: Int, intervalSeconds: Int, rounds: [EmomRoundResult])
    case amrap(blockIndex: Int, timeCapSeconds: Int, roundsCompleted: Int, partialReps: Int, rounds: [AmrapRoundResult])
}
