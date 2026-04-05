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
    func receiveRawMessageStream() -> AsyncStream<[String: Any]> {
        manager.messageStream()
    }

    /// All routed messages for callers that need to handle every type.
    func receiveMessageStream() -> AsyncStream<GarminMessage> {
        AsyncStream { continuation in
            Task {
                for await raw in self.manager.messageStream() {
                    let message = self.decoder.route(payload: raw)
                    continuation.yield(message)
                }
                continuation.finish()
            }
        }
    }

    /// Decoded Session objects from both v1 and v2 payloads.
    func receiveSessionStream() -> AsyncStream<Session> {
        AsyncStream { continuation in
            Task {
                for await raw in self.manager.messageStream() {
                    let message = self.decoder.route(payload: raw)
                    switch message {
                    case .sessionResultV1(let session), .sessionResultV2(let session):
                        continuation.yield(session)
                    default:
                        break  // other message types handled elsewhere
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
