// GympanionApp/data/repository/WorkoutRepositoryImpl.swift
import Foundation

final class WorkoutRepositoryImpl: WorkoutRepository {
    private let apiService: any ApiServiceProtocol
    private let dao: WorkoutDao

    init(apiService: any ApiServiceProtocol, dao: WorkoutDao) {
        self.apiService = apiService
        self.dao = dao
    }

    func getAllWorkouts() -> AsyncStream<[Workout]> {
        AsyncStream { continuation in
            let local = (try? dao.fetchAll()) ?? []
            continuation.yield(local.map { $0.toDomain() })
            continuation.finish()
        }
    }

    func getWorkoutById(_ id: String) -> AsyncStream<Workout?> {
        AsyncStream { continuation in
            let entity = try? dao.fetchById(id)
            continuation.yield(entity?.toDomain())
            continuation.finish()
        }
    }

    func createWorkout(_ workout: Workout) async -> Result<Workout, Error> {
        do {
            try dao.insert(workout.toEntity())
            return .success(workout)
        } catch {
            return .failure(error)
        }
    }

    func updateWorkout(_ workout: Workout) async -> Result<Workout, Error> {
        do {
            try dao.delete(id: workout.id)
            try dao.insert(workout.toEntity())
            return .success(workout)
        } catch {
            return .failure(error)
        }
    }

    func deleteWorkout(id: String) async -> Result<Void, Error> {
        do {
            try dao.delete(id: id)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    func syncWorkouts() async -> Result<Void, Error> {
        do {
            let dtos = try await apiService.fetchWorkouts()
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

private extension WorkoutEntity {
    func toDomain() -> Workout {
        Workout(
            id: id,
            name: name,
            description: workoutDescription,
            exercises: [],
            estimatedDurationMinutes: estimatedDurationMinutes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            blocks: nil
        )
    }
}

private extension Workout {
    func toEntity() -> WorkoutEntity {
        WorkoutEntity(
            id: id,
            name: name,
            estimatedDurationMinutes: estimatedDurationMinutes,
            description: description,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

private extension WorkoutDto {
    func toEntity() -> WorkoutEntity {
        WorkoutEntity(
            id: id,
            name: name,
            estimatedDurationMinutes: estimatedDurationMinutes,
            description: description,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
