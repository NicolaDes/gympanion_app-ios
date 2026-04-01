// GympanionApp/domain/repository/ExerciseRepository.swift
import Foundation

protocol ExerciseRepository {
    func getAllExercises() -> AsyncStream<[Exercise]>
    func getExerciseById(_ id: String) -> AsyncStream<Exercise?>
    func createExercise(_ exercise: Exercise) async -> Result<Exercise, Error>
    func updateExercise(_ exercise: Exercise) async -> Result<Exercise, Error>
    func deleteExercise(id: String) async -> Result<Void, Error>
    func syncExercises() async -> Result<Void, Error>
}
