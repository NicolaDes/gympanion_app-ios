// GympanionApp/presentation/features/watch/LiveSessionViewModel.swift
import Foundation

/// Presentation-layer colour classification for the session-phase pill.
/// The view maps each case to a concrete `SwiftUI.Color`.
enum PhaseColor {
    case active
    case rest
    case paused
    case idle
    case done
}

@Observable
@MainActor
final class LiveSessionViewModel {
    private let publisher: LiveWorkoutStatusPublishing

    init(publisher: LiveWorkoutStatusPublishing) {
        self.publisher = publisher
    }

    var isActive: Bool {
        publisher.currentStatus != nil
    }

    var phaseLabel: String {
        guard let phase = publisher.currentStatus?.phase else { return "" }
        switch phase {
        case .work: return "WORK"
        case .rest: return "REST"
        case .idle: return "READY"
        case .blockComplete: return "BLOCK DONE"
        case .paused: return "PAUSED"
        case .finished: return "DONE"
        case .exited: return "ENDED"
        }
    }

    var phaseColor: PhaseColor {
        guard let phase = publisher.currentStatus?.phase else { return .idle }
        switch phase {
        case .work: return .active
        case .rest, .blockComplete: return .rest
        case .paused: return .paused
        case .idle: return .idle
        case .finished, .exited: return .done
        }
    }

    var heartRate: Int? {
        publisher.currentStatus?.heartRate
    }

    var elapsedSeconds: Int? {
        publisher.currentStatus?.sessionElapsedSec
    }

    var elapsedDisplay: String {
        guard let total = elapsedSeconds, total >= 0 else { return "" }
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}
