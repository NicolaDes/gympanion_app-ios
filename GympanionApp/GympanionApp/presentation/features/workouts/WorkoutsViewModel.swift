// GympanionApp/presentation/features/workouts/WorkoutsViewModel.swift
import Foundation

@Observable
final class WorkoutsViewModel {
    var listState: UiState<[Workout]> = .idle
    var detailState: UiState<Workout> = .idle

    private let useCase: ManageWorkoutsUseCase

    init(useCase: ManageWorkoutsUseCase) {
        self.useCase = useCase
    }

    func loadWorkouts() async {
        listState = .loading
        for await workouts in useCase.getAllWorkouts() {
            listState = .success(workouts)
        }
    }

    func loadWorkout(id: String) async {
        detailState = .loading
        for await workout in useCase.getWorkoutById(id) {
            if let workout {
                detailState = .success(workout)
            } else {
                detailState = .error("Workout not found")
            }
        }
    }

    func createWorkout(_ workout: Workout) async {
        let result = await useCase.createWorkout(workout)
        switch result {
        case .success(let created): detailState = .success(created)
        case .failure(let error): detailState = .error(error.localizedDescription)
        }
    }

    func updateWorkout(_ workout: Workout) async {
        let result = await useCase.updateWorkout(workout)
        switch result {
        case .success(let updated): detailState = .success(updated)
        case .failure(let error): detailState = .error(error.localizedDescription)
        }
    }

    func deleteWorkout(id: String) async {
        let result = await useCase.deleteWorkout(id: id)
        if case .failure(let error) = result {
            listState = .error(error.localizedDescription)
        }
    }
}
