// GympanionApp/presentation/features/exercises/ExercisesViewModel.swift
import Foundation

@Observable
final class ExercisesViewModel {
    var listState: UiState<[Exercise]> = .idle
    var detailState: UiState<Exercise> = .idle

    private let useCase: ManageExercisesUseCase

    init(useCase: ManageExercisesUseCase) {
        self.useCase = useCase
    }

    func loadExercises() async {
        listState = .loading
        for await exercises in useCase.getAllExercises() {
            listState = .success(exercises)
        }
    }

    func loadExercise(id: String) async {
        detailState = .loading
        for await exercise in useCase.getExerciseById(id) {
            if let exercise {
                detailState = .success(exercise)
            } else {
                detailState = .error("Exercise not found")
            }
        }
    }

    func createExercise(_ exercise: Exercise) async {
        let result = await useCase.createExercise(exercise)
        switch result {
        case .success(let created): detailState = .success(created)
        case .failure(let error): detailState = .error(error.localizedDescription)
        }
    }

    func updateExercise(_ exercise: Exercise) async {
        let result = await useCase.updateExercise(exercise)
        switch result {
        case .success(let updated): detailState = .success(updated)
        case .failure(let error): detailState = .error(error.localizedDescription)
        }
    }

    func deleteExercise(id: String) async {
        let result = await useCase.deleteExercise(id: id)
        if case .failure(let error) = result {
            listState = .error(error.localizedDescription)
        }
    }
}
