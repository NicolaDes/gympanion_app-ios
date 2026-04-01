// GympanionApp/data/repository/GarminRepositoryImpl.swift
import Foundation

final class GarminRepositoryImpl: GarminRepository {
    private let dataSource: GarminDataSource
    private let manager: GarminManager

    init(dataSource: GarminDataSource = GarminDataSource(), manager: GarminManager = .shared) {
        self.dataSource = dataSource
        self.manager = manager
    }

    func connectedDevices() -> AsyncStream<[String]> {
        AsyncStream { continuation in
            Task { @MainActor in
                continuation.yield(self.manager.connectedDevices)
                continuation.finish()
            }
        }
    }

    func sendWorkoutToDevice(deviceId: String, workout: Workout) async -> Result<Void, Error> {
        await dataSource.sendWorkout(workout, toDevice: deviceId)
    }

    func receiveSessionFromDevice() -> AsyncStream<Session> {
        dataSource.receiveSessionStream()
    }

    func isConnectIqAvailable() -> Bool {
        // Safe to call synchronously from main thread; returns false off main thread.
        if Thread.isMainThread {
            return manager.isConnectIqAvailable()
        }
        return false
    }
}
