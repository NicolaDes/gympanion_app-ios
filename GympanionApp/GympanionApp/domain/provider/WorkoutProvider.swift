// GympanionApp/domain/provider/WorkoutProvider.swift
import Foundation

protocol WorkoutProvider {
    func getAllWorkouts() -> [Workout]
    func getWorkout(byId id: String) -> Workout?
}
