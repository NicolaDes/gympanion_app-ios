// GympanionApp/di/AppContainer.swift
import Foundation
import SwiftData

@Observable
@MainActor
final class AppContainer {

    static let shared = AppContainer()

    // MARK: - Remote
    private let apiService: ApiService
    private let keychainHelper: KeychainHelper

    // MARK: - Local
    private let database: AppDatabase
    private let exerciseDao: ExerciseDao
    private let workoutDao: WorkoutDao
    private let sessionDao: SessionDao

    // MARK: - Garmin
    private let garminDataSource: GarminDataSource

    // MARK: - Repositories
    private let authRepo: any AuthRepository
    private let exerciseRepo: any ExerciseRepository
    private let workoutRepo: any WorkoutRepository
    let sessionRepo: any SessionRepository
    private let garminRepo: any GarminRepository

    // MARK: - Use Cases (exposed for ViewModels)
    let authUseCase: AuthUseCase
    let manageExercisesUseCase: ManageExercisesUseCase
    let manageWorkoutsUseCase: ManageWorkoutsUseCase
    let ingestSessionUseCase: IngestSessionUseCase
    let fetchAnalyticsUseCase: FetchAnalyticsUseCase
    let syncWorkoutToWatchUseCase: SyncWorkoutToWatchUseCase

    private init() {
        // Remote
        apiService = ApiService()
        keychainHelper = KeychainHelper.shared

        // Local
        database = AppDatabase.shared
        exerciseDao = ExerciseDao(modelContext: database.mainContext)
        workoutDao = WorkoutDao(modelContext: database.mainContext)
        sessionDao = SessionDao(modelContext: database.mainContext)

        // Garmin
        garminDataSource = GarminDataSource()

        // Repositories
        authRepo = AuthRepositoryImpl(apiService: apiService, keychainHelper: keychainHelper)
        exerciseRepo = ExerciseRepositoryImpl(apiService: apiService, dao: exerciseDao)
        workoutRepo = WorkoutRepositoryImpl(apiService: apiService, dao: workoutDao)
        sessionRepo = SessionRepositoryImpl(apiService: apiService, dao: sessionDao)
        garminRepo = GarminRepositoryImpl(dataSource: garminDataSource)

        // Use Cases
        authUseCase = AuthUseCase(repository: authRepo)
        manageExercisesUseCase = ManageExercisesUseCase(repository: exerciseRepo)
        manageWorkoutsUseCase = ManageWorkoutsUseCase(repository: workoutRepo)
        ingestSessionUseCase = IngestSessionUseCase(repository: sessionRepo)
        fetchAnalyticsUseCase = FetchAnalyticsUseCase(repository: sessionRepo)
        syncWorkoutToWatchUseCase = SyncWorkoutToWatchUseCase(repository: garminRepo)
    }
}
