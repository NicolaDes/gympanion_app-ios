// GympanionApp/domain/model/WorkoutBlock.swift
import Foundation

struct BlockSetParams: Equatable {
    let setIndex: Int
    let reps: Int?
    let weightKg: Double?
    let durationSeconds: Int?
    let distanceMeters: Double?
    let restSeconds: Int?
}

// MARK: - EMOM types

struct EmomSetDef: Equatable {
    let exerciseId: String
    let exerciseName: String
    let reps: Int?
    let weightKg: Double?
    let durationSeconds: Int?
    let distanceMeters: Double?
}

struct EmomRound: Equatable {
    let roundIndex: Int
    let sets: [EmomSetDef]
}

// MARK: - Sequential types

struct SequentialExerciseDef: Identifiable, Equatable {
    let id: String
    let name: String
    let sets: [BlockSetParams]
}

// MARK: - AMRAP types

struct AmrapSetDef: Equatable {
    let exerciseId: String
    let exerciseName: String
    let reps: Int?
    let weightKg: Double?
    let durationSeconds: Int?
    let distanceMeters: Double?
}

// MARK: - WorkoutBlock enum

enum WorkoutBlock: Equatable {
    case sequential(name: String?, exercises: [SequentialExerciseDef])
    case emom(name: String?, intervalSeconds: Int, rounds: [EmomRound])
    case amrap(name: String?, timeCapSeconds: Int, sets: [AmrapSetDef])
}
