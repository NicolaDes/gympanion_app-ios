// GympanionApp/presentation/features/workouts/WorkoutsViewModel.swift
import Foundation

enum SendState: Equatable {
    case idle
    case sending
    case sent
    case error(String)
}

@Observable
final class WorkoutsViewModel {
    // Workout data
    var listState: UiState<[Workout]> = .idle
    var detailState: UiState<Workout> = .idle

    // Watch connection
    var isWatchConnected: Bool = false
    var connectedDeviceId: String? = nil

    // Send lifecycle
    var sendState: SendState = .idle

    private let provider: WorkoutProvider
    private let useCase: ManageWorkoutsUseCase
    private let syncUseCase: SyncWorkoutToWatchUseCase

    init(provider: WorkoutProvider,
         useCase: ManageWorkoutsUseCase,
         syncUseCase: SyncWorkoutToWatchUseCase) {
        self.provider = provider
        self.useCase = useCase
        self.syncUseCase = syncUseCase
    }

    // MARK: - Workout Loading (static provider)

    func loadWorkouts() {
        let workouts = provider.getAllWorkouts()
        listState = .success(workouts)
    }

    func loadWorkout(id: String) {
        if let workout = provider.getWorkout(byId: id) {
            detailState = .success(workout)
        } else {
            detailState = .error("Workout not found")
        }
    }

    // MARK: - Watch Connection

    func observeDevices() async {
        for await devices in syncUseCase.connectedDevices() {
            let connected = !devices.isEmpty
            isWatchConnected = connected
            connectedDeviceId = devices.first
        }
    }

    // MARK: - Send to Watch

    func sendToWatch(workout: Workout) async {
        guard let deviceId = connectedDeviceId else {
            sendState = .error("No watch connected")
            return
        }

        sendState = .sending
        let result = await syncUseCase(deviceId: deviceId, workout: workout)

        switch result {
        case .success:
            sendState = .sent
            // Revert to idle after 2 seconds
            try? await Task.sleep(for: .seconds(2))
            if sendState == .sent {
                sendState = .idle
            }
        case .failure(let error):
            sendState = .error(error.localizedDescription)
        }
    }

    func resetSendState() {
        sendState = .idle
    }

    // MARK: - Future: DB-backed operations (kept for swap path)

    func loadWorkoutsFromDB() async {
        listState = .loading
        for await workouts in useCase.getAllWorkouts() {
            listState = .success(workouts)
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
