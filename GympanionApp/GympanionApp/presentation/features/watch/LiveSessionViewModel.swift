// GympanionApp/presentation/features/watch/LiveSessionViewModel.swift
import Foundation

enum ExerciseProgressState {
    case completed
    case current
    case upcoming
}

@Observable
@MainActor
final class LiveSessionViewModel {
    private let liveWorkoutService: LiveWorkoutService

    init(liveWorkoutService: LiveWorkoutService) {
        self.liveWorkoutService = liveWorkoutService
    }

    var status: LiveWorkoutStatus? {
        liveWorkoutService.currentStatus
    }

    var isActive: Bool {
        status != nil
    }

    var isConnectionLost: Bool {
        liveWorkoutService.connectionLost
    }

    var isPaused: Bool {
        status?.phase == .paused
    }

    var workoutName: String {
        status?.workout.name ?? "\u{2014}"
    }

    var exerciseName: String {
        status?.exerciseName ?? "\u{2014}"
    }

    var phaseText: String {
        guard let phase = status?.phase else { return "" }
        switch phase {
        case .work: return "WORK"
        case .rest: return "REST"
        case .idle: return "READY"
        case .blockComplete: return "BLOCK DONE"
        case .finished: return "DONE"
        case .paused: return "PAUSED"
        case .exited: return "ENDED"
        }
    }

    var completedSetsText: String {
        guard let s = status else { return "0" }
        return "\(s.completedSets)"
    }

    var completedRepsText: String {
        guard let s = status else { return "0" }
        return "\(s.completedReps)"
    }

    var heartRateText: String? {
        guard let hr = status?.heartRate else { return nil }
        return "\(hr)"
    }

    var currentSetText: String {
        guard let s = status else { return "\u{2014}" }
        return "Set \(s.currentSetIndex + 1)"
    }

    var sessionElapsedText: String? {
        guard let elapsed = status?.sessionElapsedSec else { return nil }
        let minutes = elapsed / 60
        let seconds = elapsed % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var exercises: [LiveExerciseSummary] {
        status?.workout.exercises ?? []
    }

    func progressState(for index: Int) -> ExerciseProgressState {
        guard let s = status else { return .upcoming }
        if index < s.currentExerciseIndex { return .completed }
        if index == s.currentExerciseIndex { return .current }
        return .upcoming
    }
}
