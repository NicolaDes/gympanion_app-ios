import XCTest
@testable import GympanionApp

final class GarminPayloadDecoderTests: XCTestCase {
    let decoder = GarminPayloadDecoder()

    // MARK: - Message routing

    func testRouteSessionResultV2() {
        let payload: [String: Any] = [
            "v": 2,
            "type": "session_result",
            "workoutId": "w1",
            "sessionId": "s1",
            "startedAt": 1712345678.0,
            "completedAt": 1712349278.0,
            "totalDurationSec": 3600,
            "blocks": [
                [
                    "bi": 0,
                    "type": "sequential",
                    "exercises": [
                        [
                            "exId": "ex1",
                            "sets": [
                                [
                                    "si": 0,
                                    "reps": 5,
                                    "wKg": 70.0,
                                    "durMs": 32000,
                                    "avgHr": 145,
                                    "peakHr": 158,
                                    "completedAt": 1712345710.0
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]

        let message = decoder.route(payload: payload)

        guard case .sessionResultV2(let session) = message else {
            XCTFail("Expected sessionResultV2, got \(message)")
            return
        }

        XCTAssertEqual(session.workoutId, "w1")
        XCTAssertEqual(session.id, "s1")
        XCTAssertEqual(session.totalDurationSeconds, 3600)
        XCTAssertNotNil(session.blockResults)
        XCTAssertEqual(session.blockResults?.count, 1)

        guard case .sequential(let bi, let exercises) = session.blockResults?[0] else {
            XCTFail("Expected sequential block result")
            return
        }
        XCTAssertEqual(bi, 0)
        XCTAssertEqual(exercises.count, 1)
        XCTAssertEqual(exercises[0].exerciseId, "ex1")
        XCTAssertEqual(exercises[0].sets.count, 1)
        XCTAssertEqual(exercises[0].sets[0].weightKg, 70.0)
        XCTAssertEqual(exercises[0].sets[0].reps, 5)
        XCTAssertEqual(exercises[0].sets[0].durationMs, 32000)
        XCTAssertEqual(exercises[0].sets[0].avgHeartRate, 145)
        XCTAssertEqual(exercises[0].sets[0].peakHeartRate, 158)
        XCTAssertFalse(exercises[0].sets[0].skipped)
    }

    func testRouteEmomBlockResult() {
        let payload: [String: Any] = [
            "v": 2,
            "type": "session_result",
            "workoutId": "w2",
            "sessionId": "s2",
            "startedAt": 1712345678.0,
            "blocks": [
                [
                    "bi": 0,
                    "type": "emom",
                    "intervalSec": 120,
                    "rounds": [
                        [
                            "ri": 0,
                            "timeToCompleteSec": 95,
                            "timeRemainingSec": 25,
                            "sets": [
                                ["si": 0, "reps": 3, "wKg": 60.0, "durMs": 15000, "completedAt": 1712345700.0]
                            ]
                        ]
                    ]
                ]
            ]
        ]

        let message = decoder.route(payload: payload)
        guard case .sessionResultV2(let session) = message else {
            XCTFail("Expected sessionResultV2")
            return
        }

        guard case .emom(let bi, let intervalSec, let rounds) = session.blockResults?[0] else {
            XCTFail("Expected emom block result")
            return
        }
        XCTAssertEqual(bi, 0)
        XCTAssertEqual(intervalSec, 120)
        XCTAssertEqual(rounds.count, 1)
        XCTAssertEqual(rounds[0].timeToCompleteSeconds, 95)
        XCTAssertEqual(rounds[0].timeRemainingSeconds, 25)
        XCTAssertEqual(rounds[0].sets[0].reps, 3)
    }

    func testRouteAmrapBlockResult() {
        let payload: [String: Any] = [
            "v": 2,
            "type": "session_result",
            "workoutId": "w3",
            "sessionId": "s3",
            "startedAt": 1712345678.0,
            "blocks": [
                [
                    "bi": 0,
                    "type": "amrap",
                    "timeCapSec": 720,
                    "roundsCompleted": 4,
                    "partialReps": 7,
                    "rounds": [
                        [
                            "ri": 0,
                            "durMs": 180000,
                            "partial": false,
                            "sets": [
                                ["si": 0, "reps": 10, "wKg": 60.0, "durMs": 45000, "completedAt": 1712345700.0],
                                ["si": 1, "reps": 15, "durMs": 55000, "completedAt": 1712345750.0]
                            ]
                        ],
                        [
                            "ri": 4,
                            "durMs": 90000,
                            "partial": true,
                            "sets": [
                                ["si": 0, "reps": 7, "wKg": 60.0, "durMs": 90000, "skipped": false, "completedAt": 1712346000.0]
                            ]
                        ]
                    ]
                ]
            ]
        ]

        let message = decoder.route(payload: payload)
        guard case .sessionResultV2(let session) = message else {
            XCTFail("Expected sessionResultV2")
            return
        }

        guard case .amrap(let bi, let timeCapSec, let roundsCompleted, let partialReps, let rounds) = session.blockResults?[0] else {
            XCTFail("Expected amrap block result")
            return
        }
        XCTAssertEqual(bi, 0)
        XCTAssertEqual(timeCapSec, 720)
        XCTAssertEqual(roundsCompleted, 4)
        XCTAssertEqual(partialReps, 7)
        XCTAssertEqual(rounds.count, 2)
        XCTAssertFalse(rounds[0].isPartial)
        XCTAssertTrue(rounds[1].isPartial)
        XCTAssertEqual(rounds[0].sets.count, 2)
        XCTAssertEqual(rounds[1].sets.count, 1)
    }

    func testRouteWorkoutReplaceResponse() {
        let payload: [String: Any] = [
            "type": "workout_replace_response",
            "accepted": true
        ]

        let message = decoder.route(payload: payload)
        guard case .workoutReplaceResponse(let accepted) = message else {
            XCTFail("Expected workoutReplaceResponse")
            return
        }
        XCTAssertTrue(accepted)
    }

    func testRouteErrorMessage() {
        let payload: [String: Any] = [
            "type": "error",
            "code": "unsupported_version",
            "maxSupported": 2
        ]

        let message = decoder.route(payload: payload)
        guard case .error(let code, let maxSupported) = message else {
            XCTFail("Expected error")
            return
        }
        XCTAssertEqual(code, "unsupported_version")
        XCTAssertEqual(maxSupported, 2)
    }

    func testRouteV1SessionFallback() {
        let payload: [String: Any] = [
            "workoutId": "w1",
            "workoutName": "Test",
            "sessionId": "s1",
            "startedAt": 1712345678000.0,
            "sets": [
                "ex1": [
                    ["setNumber": 1, "reps": 5, "weightKg": 70.0, "completedAt": 1712345710000.0]
                ]
            ]
        ]

        let message = decoder.route(payload: payload)
        guard case .sessionResultV1(let session) = message else {
            XCTFail("Expected sessionResultV1, got \(message)")
            return
        }
        XCTAssertEqual(session.workoutId, "w1")
        XCTAssertEqual(session.workoutName, "Test")
        XCTAssertNil(session.blockResults)
        XCTAssertNil(session.totalDurationSeconds)
        XCTAssertEqual(session.sets.count, 1)
        XCTAssertEqual(session.sets["ex1"]?.count, 1)
    }

    func testRouteSetCompleteMessage() {
        let payload: [String: Any] = [
            "type": "set_complete",
            "exerciseName": "Squat",
            "setIndex": 0
        ]

        let message = decoder.route(payload: payload)
        guard case .setComplete(let raw) = message else {
            XCTFail("Expected setComplete")
            return
        }
        XCTAssertEqual(raw["exerciseName"] as? String, "Squat")
    }

    func testRouteUnknownType() {
        let payload: [String: Any] = [
            "type": "future_message_type",
            "data": 42
        ]

        let message = decoder.route(payload: payload)
        guard case .unknown = message else {
            XCTFail("Expected unknown")
            return
        }
    }

    // MARK: - V2 edge cases

    func testV2SessionWithSkippedSet() {
        let payload: [String: Any] = [
            "v": 2,
            "type": "session_result",
            "workoutId": "w1",
            "startedAt": 1712345678.0,
            "blocks": [
                [
                    "bi": 0,
                    "type": "sequential",
                    "exercises": [
                        [
                            "exId": "ex1",
                            "sets": [
                                ["si": 0, "reps": 5, "wKg": 70.0, "durMs": 30000, "completedAt": 1712345700.0],
                                ["si": 1, "skipped": true, "durMs": 0, "completedAt": 1712345710.0]
                            ]
                        ]
                    ]
                ]
            ]
        ]

        let message = decoder.route(payload: payload)
        guard case .sessionResultV2(let session) = message else {
            XCTFail("Expected sessionResultV2")
            return
        }

        guard case .sequential(_, let exercises) = session.blockResults?[0] else {
            XCTFail("Expected sequential block result")
            return
        }
        XCTAssertFalse(exercises[0].sets[0].skipped)
        XCTAssertTrue(exercises[0].sets[1].skipped)
    }

    func testV2SessionWithZeroHeartRateIsNil() {
        let payload: [String: Any] = [
            "v": 2,
            "type": "session_result",
            "workoutId": "w1",
            "startedAt": 1712345678.0,
            "blocks": [
                [
                    "bi": 0,
                    "type": "sequential",
                    "exercises": [
                        [
                            "exId": "ex1",
                            "sets": [
                                ["si": 0, "reps": 5, "durMs": 30000, "avgHr": 0, "peakHr": 0, "completedAt": 1712345700.0]
                            ]
                        ]
                    ]
                ]
            ]
        ]

        let message = decoder.route(payload: payload)
        guard case .sessionResultV2(let session) = message else {
            XCTFail("Expected sessionResultV2")
            return
        }
        guard case .sequential(_, let exercises) = session.blockResults?[0] else {
            XCTFail("Expected sequential")
            return
        }
        // HR of 0 should be treated as nil (sensor not reporting)
        XCTAssertNil(exercises[0].sets[0].avgHeartRate)
        XCTAssertNil(exercises[0].sets[0].peakHeartRate)
    }

    // MARK: - Backward compat

    func testDecodeMethodStillWorks() throws {
        let payload: [String: Any] = [
            "workoutId": "w1",
            "workoutName": "Test",
            "sessionId": "s1",
            "startedAt": 1712345678000.0,
            "sets": [:]
        ]

        let session = try decoder.decode(payload: payload)
        XCTAssertEqual(session.workoutId, "w1")
        XCTAssertNil(session.blockResults)
    }
}
