// GympanionApp/domain/repository/WorkoutRepository.swift
import Foundation

protocol WorkoutRepository {
    func getAllWorkouts() -> AsyncStream<[Workout]>
    func getWorkoutById(_ id: String) -> AsyncStream<Workout?>
    func createWorkout(_ workout: Workout) async -> Result<Workout, Error>
    func updateWorkout(_ workout: Workout) async -> Result<Workout, Error>
    func deleteWorkout(id: String) async -> Result<Void, Error>
    func syncWorkouts() async -> Result<Void, Error>
}
