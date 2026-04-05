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

    // MARK: - Providers
    private let workoutProvider: WorkoutProvider

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

    // MARK: - ViewModels (shared)
    /// Shared ViewModel for workout list + detail. Both screens observe the same instance
    /// so watch connection state and data stay in sync during navigation.
    var workoutsViewModel: WorkoutsViewModel {
        if let _workoutsViewModel { return _workoutsViewModel }
        let vm = WorkoutsViewModel(
            provider: workoutProvider,
            useCase: manageWorkoutsUseCase,
            syncUseCase: syncWorkoutToWatchUseCase
        )
        _workoutsViewModel = vm
        return vm
    }
    private var _workoutsViewModel: WorkoutsViewModel?

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

        // Providers
        workoutProvider = StaticWorkoutProvider()

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
