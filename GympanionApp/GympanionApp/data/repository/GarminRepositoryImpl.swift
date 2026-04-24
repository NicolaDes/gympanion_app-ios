// GympanionApp/data/repository/GarminRepositoryImpl.swift
import Foundation

final class GarminRepositoryImpl: GarminRepository {
    private let dataSource: GarminDataSource
    private let manager: GarminManager
    private let dedupFilter: GarminMessageDedupFilter?

    init(dataSource: GarminDataSource = GarminDataSource(),
         manager: GarminManager = .shared,
         dedupFilter: GarminMessageDedupFilter? = nil) {
        self.dataSource = dataSource
        self.manager = manager
        self.dedupFilter = dedupFilter
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
        AsyncStream { continuation in
            Task {
                for await session in self.dataSource.receiveSessionStream() {
                    if let filter = self.dedupFilter,
                       await filter.shouldAcceptSession(session) == false {
                        continue  // duplicate session_result replay — drop
                    }
                    continuation.yield(session)
                }
                continuation.finish()
            }
        }
    }

    func isConnectIqAvailable() -> Bool {
        if Thread.isMainThread {
            return manager.isConnectIqAvailable()
        }
        return false
    }
}
