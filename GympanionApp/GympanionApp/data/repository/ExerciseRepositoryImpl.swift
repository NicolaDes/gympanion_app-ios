// GympanionApp/data/repository/ExerciseRepositoryImpl.swift
import Foundation

final class ExerciseRepositoryImpl: ExerciseRepository {
    private let apiService: any ApiServiceProtocol
    private let dao: ExerciseDao

    init(apiService: any ApiServiceProtocol, dao: ExerciseDao) {
        self.apiService = apiService
        self.dao = dao
    }

    func getAllExercises() -> AsyncStream<[Exercise]> {
        AsyncStream { continuation in
            let local = (try? dao.fetchAll()) ?? []
            continuation.yield(local.map { $0.toDomain() })
            continuation.finish()
        }
    }

    func getExerciseById(_ id: String) -> AsyncStream<Exercise?> {
        AsyncStream { continuation in
            let entity = try? dao.fetchById(id)
            continuation.yield(entity?.toDomain())
            continuation.finish()
        }
    }

    func createExercise(_ exercise: Exercise) async -> Result<Exercise, Error> {
        do {
            let entity = ExerciseEntity(
                id: exercise.id,
                name: exercise.name,
                category: exercise.category.rawValue,
                isCustom: exercise.isCustom,
                description: exercise.description,
                primaryMuscleGroups: exercise.primaryMuscleGroups.map { $0.rawValue },
                secondaryMuscleGroups: exercise.secondaryMuscleGroups.map { $0.rawValue },
                createdAt: exercise.createdAt,
                updatedAt: exercise.updatedAt
            )
            try dao.insert(entity)
            return .success(exercise)
        } catch {
            return .failure(error)
        }
    }

    func updateExercise(_ exercise: Exercise) async -> Result<Exercise, Error> {
        do {
            try dao.delete(id: exercise.id)
            let entity = ExerciseEntity(
                id: exercise.id,
                name: exercise.name,
                category: exercise.category.rawValue,
                isCustom: exercise.isCustom,
                description: exercise.description,
                primaryMuscleGroups: exercise.primaryMuscleGroups.map { $0.rawValue },
                secondaryMuscleGroups: exercise.secondaryMuscleGroups.map { $0.rawValue },
                createdAt: exercise.createdAt,
                updatedAt: Date()
            )
            try dao.insert(entity)
            return .success(exercise)
        } catch {
            return .failure(error)
        }
    }

    func deleteExercise(id: String) async -> Result<Void, Error> {
        do {
            try dao.delete(id: id)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    func syncExercises() async -> Result<Void, Error> {
        do {
            let dtos = try await apiService.fetchExercises()
            for dto in dtos {
                try? dao.delete(id: dto.id)
                try dao.insert(dto.toEntity())
            }
            return .success(())
        } catch {
            return .failure(error)
        }
    }
}

// MARK: - Mapping helpers

private extension ExerciseEntity {
    func toDomain() -> Exercise {
        Exercise(
            id: id,
            name: name,
            description: exerciseDescription,
            category: ExerciseCategory(rawValue: category) ?? .strength,
            primaryMuscleGroups: primaryMuscleGroups.compactMap { MuscleGroup(rawValue: $0) },
            secondaryMuscleGroups: secondaryMuscleGroups.compactMap { MuscleGroup(rawValue: $0) },
            defaultParams: ExerciseParams(sets: nil, reps: nil, durationSeconds: nil, distanceMeters: nil, weightKg: nil, restSeconds: nil),
            isCustom: isCustom,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

private extension ExerciseDto {
    func toEntity() -> ExerciseEntity {
        ExerciseEntity(
            id: id,
            name: name,
            category: category,
            isCustom: isCustom,
            description: description,
            primaryMuscleGroups: primaryMuscleGroups,
            secondaryMuscleGroups: secondaryMuscleGroups,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
