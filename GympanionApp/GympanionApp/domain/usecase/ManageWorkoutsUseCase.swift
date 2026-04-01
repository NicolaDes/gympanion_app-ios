// GympanionApp/domain/usecase/ManageWorkoutsUseCase.swift
import Foundation

final class ManageWorkoutsUseCase {
    private let repository: any WorkoutRepository

    init(repository: any WorkoutRepository) {
        self.repository = repository
    }

    func getAllWorkouts() -> AsyncStream<[Workout]> {
        repository.getAllWorkouts()
    }

    func getWorkoutById(_ id: String) -> AsyncStream<Workout?> {
        repository.getWorkoutById(id)
    }

    func createWorkout(_ workout: Workout) async -> Result<Workout, Error> {
        await repository.createWorkout(workout)
    }

    func updateWorkout(_ workout: Workout) async -> Result<Workout, Error> {
        await repository.updateWorkout(workout)
    }

    func deleteWorkout(id: String) async -> Result<Void, Error> {
        await repository.deleteWorkout(id: id)
    }
}
