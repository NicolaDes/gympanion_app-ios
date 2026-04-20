// GympanionApp/data/garmin/LiveWorkoutService.swift
import Foundation

/// Read-only projection of live workout state for presentation layer consumers.
/// Narrower than the full service so ViewModels can be unit-tested with a fake.
@MainActor
protocol LiveWorkoutStatusPublishing: AnyObject {
    var currentStatus: LiveWorkoutStatus? { get }
}

/// Listens to the Garmin message stream for liveStatus messages and publishes
/// the current workout status. Views observe `currentStatus` to show/hide
/// the live workout banner and detail screen.
///
/// Lives in the Data layer because it depends on GarminDataSource.
@Observable
@MainActor
final class LiveWorkoutService: LiveWorkoutStatusPublishing {
    private(set) var currentStatus: LiveWorkoutStatus?
    private(set) var connectionLost: Bool = false

    private let garminDataSource: GarminDataSource
    private var listenTask: Task<Void, Never>?
    private var staleTimeoutTask: Task<Void, Never>?
    private var connectionTimeoutTask: Task<Void, Never>?

    /// Stale status is cleared after 10 minutes with no updates.
    /// Covers the case where the watch app crashes without sending FINISHED.
    private static let staleTimeoutSeconds: TimeInterval = 600

    /// Connection is considered lost after 60 seconds with no messages.
    /// This preserves the last known state but shows a visual indicator.
    private static let connectionTimeoutSeconds: TimeInterval = 60

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
                self.handleStatus(status)
            }
        }
    }

    /// Stops listening and clears status. Call on app termination if needed.
    func stopListening() {
        listenTask?.cancel()
        staleTimeoutTask?.cancel()
        connectionTimeoutTask?.cancel()
        currentStatus = nil
        connectionLost = false
    }

    private func handleStatus(_ status: LiveWorkoutStatus) {
        // Any message proves the watch is alive
        connectionLost = false
        resetConnectionTimeout()

        switch status.phase {
        case .finished:
            currentStatus = nil
            cancelAllTimers()

        case .exited:
            currentStatus = status
            cancelAllTimers()
            // Show "ENDED" for 2 seconds, then clear
            staleTimeoutTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else { return }
                self?.currentStatus = nil
            }

        default:
            currentStatus = status
            resetStaleTimeout()
        }
    }

    private func resetConnectionTimeout() {
        connectionTimeoutTask?.cancel()
        connectionTimeoutTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(Self.connectionTimeoutSeconds))
            guard !Task.isCancelled else { return }
            self?.connectionLost = true
        }
    }

    private func resetStaleTimeout() {
        staleTimeoutTask?.cancel()
        staleTimeoutTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(Self.staleTimeoutSeconds))
            guard !Task.isCancelled else { return }
            self?.currentStatus = nil
            self?.connectionLost = false
        }
    }

    private func cancelAllTimers() {
        staleTimeoutTask?.cancel()
        connectionTimeoutTask?.cancel()
    }
}
