// GympanionApp/domain/usecase/ManageExercisesUseCase.swift
import Foundation

final class ManageExercisesUseCase {
    private let repository: any ExerciseRepository

    init(repository: any ExerciseRepository) {
        self.repository = repository
    }

    func getAllExercises() -> AsyncStream<[Exercise]> {
        repository.getAllExercises()
    }

    func getExerciseById(_ id: String) -> AsyncStream<Exercise?> {
        repository.getExerciseById(id)
    }

    func createExercise(_ exercise: Exercise) async -> Result<Exercise, Error> {
        await repository.createExercise(exercise)
    }

    func updateExercise(_ exercise: Exercise) async -> Result<Exercise, Error> {
        await repository.updateExercise(exercise)
    }

    func deleteExercise(id: String) async -> Result<Void, Error> {
        await repository.deleteExercise(id: id)
    }
}
