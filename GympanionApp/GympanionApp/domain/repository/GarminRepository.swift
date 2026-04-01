// GympanionApp/domain/repository/GarminRepository.swift
import Foundation

protocol GarminRepository {
    func connectedDevices() -> AsyncStream<[String]>
    func sendWorkoutToDevice(deviceId: String, workout: Workout) async -> Result<Void, Error>
    func receiveSessionFromDevice() -> AsyncStream<Session>
    func isConnectIqAvailable() -> Bool
}
