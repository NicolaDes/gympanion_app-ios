// GympanionAppTests/LiveSessionViewModelTests.swift
import XCTest
@testable import GympanionApp

@MainActor
final class LiveSessionViewModelTests: XCTestCase {

    // MARK: - Fixtures

    /// In-memory fake publisher that exposes whatever status the test sets.
    @MainActor
    final class FakePublisher: LiveWorkoutStatusPublishing {
        var currentStatus: LiveWorkoutStatus?
    }

    private func makeStatus(
        phase: LiveSessionPhase = .work,
        heartRate: Int? = 142,
        sessionElapsedSec: Int? = 65
    ) -> LiveWorkoutStatus {
        LiveWorkoutStatus(
            exerciseName: "Bench Press",
            currentExerciseIndex: 0,
            currentSetIndex: 0,
            completedSets: 0,
            completedReps: 0,
            heartRate: heartRate,
            phase: phase,
            workout: LiveWorkoutPlan(id: "w1", name: "Test Workout", exercises: []),
            sessionElapsedSec: sessionElapsedSec,
            receivedAt: Date(timeIntervalSince1970: 0)
        )
    }

    // MARK: - phaseLabel

    func testPhaseLabelMapsEachPhaseCase() {
        let fake = FakePublisher()
        let vm = LiveSessionViewModel(publisher: fake)

        let cases: [(LiveSessionPhase, String)] = [
            (.work, "WORK"),
            (.rest, "REST"),
            (.idle, "READY"),
            (.blockComplete, "BLOCK DONE"),
            (.paused, "PAUSED"),
            (.finished, "DONE"),
            (.exited, "ENDED"),
        ]

        for (phase, expected) in cases {
            fake.currentStatus = makeStatus(phase: phase)
            XCTAssertEqual(vm.phaseLabel, expected, "phaseLabel for \(phase)")
        }
    }

    // MARK: - phaseColor

    func testPhaseColorMapsEachPhaseCase() {
        let fake = FakePublisher()
        let vm = LiveSessionViewModel(publisher: fake)

        let cases: [(LiveSessionPhase, PhaseColor)] = [
            (.work, .active),
            (.rest, .rest),
            (.blockComplete, .rest),
            (.paused, .paused),
            (.idle, .idle),
            (.finished, .done),
            (.exited, .done),
        ]

        for (phase, expected) in cases {
            fake.currentStatus = makeStatus(phase: phase)
            XCTAssertEqual(vm.phaseColor, expected, "phaseColor for \(phase)")
        }
    }

    // MARK: - heartRate

    func testHeartRatePassthrough() {
        let fake = FakePublisher()
        let vm = LiveSessionViewModel(publisher: fake)

        // No status → nil
        XCTAssertNil(vm.heartRate)

        // Status with HR nil → nil
        fake.currentStatus = makeStatus(heartRate: nil)
        XCTAssertNil(vm.heartRate)

        // Status with HR value → passthrough
        fake.currentStatus = makeStatus(heartRate: 137)
        XCTAssertEqual(vm.heartRate, 137)
    }

    // MARK: - elapsedSeconds / elapsedDisplay

    func testElapsedSecondsPassthrough() {
        let fake = FakePublisher()
        let vm = LiveSessionViewModel(publisher: fake)

        XCTAssertNil(vm.elapsedSeconds)

        fake.currentStatus = makeStatus(sessionElapsedSec: nil)
        XCTAssertNil(vm.elapsedSeconds)

        fake.currentStatus = makeStatus(sessionElapsedSec: 65)
        XCTAssertEqual(vm.elapsedSeconds, 65)
    }

    func testElapsedDisplayFormatting() {
        let fake = FakePublisher()
        let vm = LiveSessionViewModel(publisher: fake)

        let cases: [(Int?, String)] = [
            (nil, ""),
            (0, "0:00"),
            (5, "0:05"),
            (65, "1:05"),
            (3599, "59:59"),
            (3600, "1:00:00"),
            (3725, "1:02:05"),
        ]

        for (seconds, expected) in cases {
            if let seconds {
                fake.currentStatus = makeStatus(sessionElapsedSec: seconds)
            } else {
                fake.currentStatus = nil
            }
            XCTAssertEqual(vm.elapsedDisplay, expected, "elapsedDisplay for \(String(describing: seconds))")
        }
    }

    // MARK: - isActive

    func testIsActiveTogglesWithStatus() {
        let fake = FakePublisher()
        let vm = LiveSessionViewModel(publisher: fake)

        XCTAssertFalse(vm.isActive)

        fake.currentStatus = makeStatus()
        XCTAssertTrue(vm.isActive)

        fake.currentStatus = nil
        XCTAssertFalse(vm.isActive)
    }
}
