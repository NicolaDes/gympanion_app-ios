// GympanionApp/domain/usecase/SyncWorkoutToWatchUseCase.swift
import Foundation

final class SyncWorkoutToWatchUseCase {
    private let repository: any GarminRepository

    init(repository: any GarminRepository) {
        self.repository = repository
    }

    func callAsFunction(deviceId: String, workout: Workout) async -> Result<Void, Error> {
        await repository.sendWorkoutToDevice(deviceId: deviceId, workout: workout)
    }

    func connectedDevices() -> AsyncStream<[String]> {
        repository.connectedDevices()
    }
}
