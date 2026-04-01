// GympanionApp/data/garmin/GarminDataSource.swift
import Foundation
import ConnectIQ

final class GarminDataSource {
    private let manager: GarminManager
    private let encoder = GarminPayloadEncoder()
    private let decoder = GarminPayloadDecoder()

    init(manager: GarminManager = .shared) {
        self.manager = manager
    }

    // MARK: - Send

    func sendWorkout(_ workout: Workout, toDevice deviceId: String) async -> Result<Void, Error> {
        guard manager.isConnectIqAvailable() else {
            return .failure(GarminError.connectIqUnavailable)
        }
        guard let device = manager.devices.first(where: { $0.friendlyName == deviceId }) else {
            return .failure(GarminError.deviceNotFound(deviceId))
        }
        let payload = encoder.encode(workout: workout)
        let app = IQApp(uuid: kGarminWatchAppUUID as NSUUID as UUID,
                        store: kGarminStoreUUID as NSUUID as UUID,
                        device: device)
        return await withCheckedContinuation { continuation in
            ConnectIQ.sharedInstance().sendMessage(payload, to: app, progress: nil) { result in
                if result == .success {
                    continuation.resume(returning: .success(()))
                } else {
                    continuation.resume(returning: .failure(GarminError.transmissionFailed("\(result)")))
                }
            }
        }
    }

    // MARK: - Receive

    /// Raw dictionary messages from any registered watch app.
    func receiveMessageStream() -> AsyncStream<[String: Any]> {
        manager.messageStream()
    }

    /// Decoded Session objects (only messages that match the session schema).
    func receiveSessionStream() -> AsyncStream<Session> {
        AsyncStream { continuation in
            Task {
                for await raw in self.manager.messageStream() {
                    if let session = try? self.decoder.decode(payload: raw) {
                        continuation.yield(session)
                    }
                }
                continuation.finish()
            }
        }
    }
}

// MARK: - Errors

enum GarminError: LocalizedError {
    case connectIqUnavailable
    case deviceNotFound(String)
    case transmissionFailed(String)

    var errorDescription: String? {
        switch self {
        case .connectIqUnavailable:      return "Garmin ConnectIQ is not available on this device."
        case .deviceNotFound(let name):  return "Device '\(name)' not found."
        case .transmissionFailed(let m): return "Transmission failed: \(m)"
        }
    }
}
