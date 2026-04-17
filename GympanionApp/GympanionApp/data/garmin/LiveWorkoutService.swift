// GympanionApp/data/garmin/LiveWorkoutService.swift
import Foundation

/// Listens to the Garmin message stream for liveStatus messages and publishes
/// the current workout status. Views observe `currentStatus` to show/hide
/// the live workout banner and detail screen.
///
/// Lives in the Data layer because it depends on GarminDataSource.
@Observable
@MainActor
final class LiveWorkoutService {
    private(set) var currentStatus: LiveWorkoutStatus?

    private let garminDataSource: GarminDataSource
    private var listenTask: Task<Void, Never>?
    private var timeoutTask: Task<Void, Never>?

    /// Stale status is cleared after 10 minutes with no updates.
    /// Covers the case where the watch app crashes without sending FINISHED.
    private static let staleTimeoutSeconds: TimeInterval = 600

    init(garminDataSource: GarminDataSource) {
        self.garminDataSource = garminDataSource
    }

    /// Begins listening for liveStatus messages from the watch.
    /// Call once during app startup. Safe to call multiple times — subsequent
    /// calls cancel the previous listener.
    func startListening() {
        listenTask?.cancel()
        listenTask = Task { [weak self] in
            guard let self else { return }
            for await message in self.garminDataSource.receiveMessageStream() {
                guard !Task.isCancelled else { break }
                guard case .liveStatus(let status) = message else { continue }
                if status.phase == .finished {
                    self.currentStatus = nil
                    self.timeoutTask?.cancel()
                } else {
                    self.currentStatus = status
                    self.resetTimeout()
                }
            }
        }
    }

    /// Stops listening and clears status. Call on app termination if needed.
    func stopListening() {
        listenTask?.cancel()
        timeoutTask?.cancel()
        currentStatus = nil
    }

    private func resetTimeout() {
        timeoutTask?.cancel()
        timeoutTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(Self.staleTimeoutSeconds))
            guard !Task.isCancelled else { return }
            self?.currentStatus = nil
        }
    }
}
