// GympanionApp/presentation/features/watch/WatchSyncViewModel.swift
import Foundation

// MARK: - Typed watch messages

enum WatchMessageType {
    /// User completed a set on the watch.
    case setComplete(SetCompletePayload)
    /// User confirmed or discarded a workout pushed from the phone.
    case workoutReplaceResponse(accepted: Bool)
    /// Unknown / future message type — kept as raw dict.
    case unknown([String: Any])
}

struct SetCompletePayload {
    let exerciseName:   String
    let exerciseIndex:  Int
    let totalExercises: Int
    let setIndex:       Int
    let totalSets:      Int
    let durationMs:     Int
    let targetWeight:   Double
    let targetReps:     Int

    init?(dict: [String: Any]) {
        guard
            let name  = dict["exerciseName"]   as? String,
            let ei    = dict["exerciseIndex"]   as? Int,
            let te    = dict["totalExercises"]  as? Int,
            let si    = dict["setIndex"]        as? Int,
            let ts    = dict["totalSets"]       as? Int,
            let dur   = dict["durationMs"]      as? Int,
            let tw    = dict["targetWeight"]    as? Double,
            let tr    = dict["targetReps"]      as? Int
        else { return nil }
        exerciseName   = name
        exerciseIndex  = ei
        totalExercises = te
        setIndex       = si
        totalSets      = ts
        durationMs     = dur
        targetWeight   = tw
        targetReps     = tr
    }
}

struct WatchMessage: Identifiable {
    let id = UUID()
    let receivedAt = Date()
    let type: WatchMessageType

    init(raw: [String: Any]) {
        switch raw["type"] as? String {
        case "set_complete":
            if let payload = SetCompletePayload(dict: raw) {
                type = .setComplete(payload)
            } else {
                type = .unknown(raw)
            }
        case "workout_replace_response":
            let accepted = raw["accepted"] as? Bool ?? false
            type = .workoutReplaceResponse(accepted: accepted)
        default:
            type = .unknown(raw)
        }
    }

    var title: String {
        switch type {
        case .setComplete(let p):
            return "✅ Set complete — \(p.exerciseName)"
        case .workoutReplaceResponse(let accepted):
            return accepted ? "✅ Workout accepted" : "❌ Workout discarded"
        case .unknown:
            return "❓ Unknown message"
        }
    }

    var detail: String {
        switch type {
        case .setComplete(let p):
            let dur = String(format: "%.0fs", Double(p.durationMs) / 1000)
            return "Ex \(p.exerciseIndex + 1)/\(p.totalExercises)  ·  Set \(p.setIndex + 1)/\(p.totalSets)  ·  \(p.targetWeight) kg × \(p.targetReps) reps  ·  \(dur)"
        case .workoutReplaceResponse:
            return "Response to phone-pushed workout"
        case .unknown(let raw):
            return (try? JSONSerialization.data(withJSONObject: raw, options: .prettyPrinted))
                .flatMap { String(data: $0, encoding: .utf8) } ?? "\(raw)"
        }
    }
}

// MARK: - ViewModel

@Observable
final class WatchSyncViewModel {
    var devicesState: UiState<[String]> = .idle
    var syncState: UiState<Void> = .idle
    var messages: [WatchMessage] = []
    var isListening = false

    private let syncUseCase: SyncWorkoutToWatchUseCase
    private let dataSource: GarminDataSource

    init(syncUseCase: SyncWorkoutToWatchUseCase,
         dataSource: GarminDataSource = GarminDataSource()) {
        self.syncUseCase = syncUseCase
        self.dataSource  = dataSource
    }

    func loadDevices() async {
        devicesState = .loading
        for await devices in syncUseCase.connectedDevices() {
            devicesState = .success(devices)
        }
    }

    func connectDevices() {
        GarminManager.shared.showDeviceSelection()
    }

    func startListening() async {
        isListening = true
        for await raw in dataSource.receiveMessageStream() {
            messages.insert(WatchMessage(raw: raw), at: 0)
        }
        isListening = false
    }

    func syncWorkout(deviceId: String, workout: Workout) async {
        syncState = .loading
        let result = await syncUseCase(deviceId: deviceId, workout: workout)
        switch result {
        case .success:            syncState = .success(())
        case .failure(let error): syncState = .error(error.localizedDescription)
        }
    }
}
