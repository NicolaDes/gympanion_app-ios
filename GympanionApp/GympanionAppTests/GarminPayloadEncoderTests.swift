import XCTest
@testable import GympanionApp

final class GarminPayloadEncoderTests: XCTestCase {
    let encoder = GarminPayloadEncoder()

    func testEncodeV2SequentialBlock() {
        let workout = Workout(
            id: "w1", name: "Test", description: nil,
            exercises: [],
            estimatedDurationMinutes: 30,
            createdAt: Date(), updatedAt: Date(),
            blocks: [
                .sequential(name: "Strength", exercises: [
                    SequentialExerciseDef(id: "ex1", name: "Squat", sets: [
                        BlockSetParams(setIndex: 0, reps: 5, weightKg: 70.0, durationSeconds: nil, distanceMeters: nil, restSeconds: 90),
                        BlockSetParams(setIndex: 1, reps: 5, weightKg: 80.0, durationSeconds: nil, distanceMeters: nil, restSeconds: 90),
                    ])
                ])
            ]
        )

        let payload = encoder.encode(workout: workout)

        XCTAssertEqual(payload["v"] as? Int, 2)
        XCTAssertEqual(payload["type"] as? String, "workout")
        XCTAssertEqual(payload["id"] as? String, "w1")

        let blocks = payload["blocks"] as? [[String: Any]]
        XCTAssertEqual(blocks?.count, 1)

        let block = blocks?[0]
        XCTAssertEqual(block?["type"] as? String, "sequential")
        XCTAssertEqual(block?["name"] as? String, "Strength")

        let exercises = block?["exercises"] as? [[String: Any]]
        XCTAssertEqual(exercises?.count, 1)
        XCTAssertEqual(exercises?[0]["id"] as? String, "ex1")

        let sets = exercises?[0]["sets"] as? [[String: Any]]
        XCTAssertEqual(sets?.count, 2)
        XCTAssertEqual(sets?[0]["wKg"] as? Double, 70.0)
        XCTAssertEqual(sets?[0]["si"] as? Int, 0)
        XCTAssertEqual(sets?[0]["restSec"] as? Int, 90)
        XCTAssertEqual(sets?[1]["wKg"] as? Double, 80.0)
    }

    func testEncodeV2EmomBlock() {
        let workout = Workout(
            id: "w2", name: "EMOM Test", description: nil,
            exercises: [],
            estimatedDurationMinutes: 10,
            createdAt: Date(), updatedAt: Date(),
            blocks: [
                .emom(name: "E2MOM", intervalSeconds: 120, rounds: [
                    EmomRound(roundIndex: 0, sets: [
                        EmomSetDef(exerciseId: "ex1", exerciseName: "Clean", reps: 3, weightKg: 60.0, durationSeconds: nil, distanceMeters: nil)
                    ]),
                    EmomRound(roundIndex: 1, sets: [
                        EmomSetDef(exerciseId: "ex2", exerciseName: "Row", reps: 5, weightKg: 50.0, durationSeconds: nil, distanceMeters: nil)
                    ])
                ])
            ]
        )

        let payload = encoder.encode(workout: workout)
        XCTAssertEqual(payload["v"] as? Int, 2)

        let blocks = payload["blocks"] as? [[String: Any]]
        let block = blocks?[0]

        XCTAssertEqual(block?["type"] as? String, "emom")
        XCTAssertEqual(block?["intervalSec"] as? Int, 120)
        XCTAssertEqual(block?["name"] as? String, "E2MOM")

        let rounds = block?["rounds"] as? [[String: Any]]
        XCTAssertEqual(rounds?.count, 2)
        XCTAssertEqual(rounds?[0]["ri"] as? Int, 0)

        let sets = rounds?[0]["sets"] as? [[String: Any]]
        XCTAssertEqual(sets?[0]["exId"] as? String, "ex1")
        XCTAssertEqual(sets?[0]["reps"] as? Int, 3)
        XCTAssertEqual(sets?[0]["wKg"] as? Double, 60.0)
    }

    func testEncodeV2AmrapBlock() {
        let workout = Workout(
            id: "w3", name: "AMRAP Test", description: nil,
            exercises: [],
            estimatedDurationMinutes: 12,
            createdAt: Date(), updatedAt: Date(),
            blocks: [
                .amrap(name: "AMRAP 12", timeCapSeconds: 720, sets: [
                    AmrapSetDef(exerciseId: "ex1", exerciseName: "Deadlift", reps: 10, weightKg: 60.0, durationSeconds: nil, distanceMeters: nil),
                    AmrapSetDef(exerciseId: "ex2", exerciseName: "Box Jump", reps: 15, weightKg: nil, durationSeconds: nil, distanceMeters: nil)
                ])
            ]
        )

        let payload = encoder.encode(workout: workout)
        XCTAssertEqual(payload["v"] as? Int, 2)

        let blocks = payload["blocks"] as? [[String: Any]]
        let block = blocks?[0]

        XCTAssertEqual(block?["type"] as? String, "amrap")
        XCTAssertEqual(block?["timeCapSec"] as? Int, 720)
        XCTAssertEqual(block?["name"] as? String, "AMRAP 12")

        let sets = block?["sets"] as? [[String: Any]]
        XCTAssertEqual(sets?.count, 2)
        XCTAssertEqual(sets?[0]["exId"] as? String, "ex1")
        XCTAssertEqual(sets?[0]["reps"] as? Int, 10)
        // Box Jump has no weight — wKg should be absent
        XCTAssertNil(sets?[1]["wKg"])
    }

    func testEncodeV1FallbackWhenNoBlocks() {
        let workout = Workout(
            id: "w4", name: "V1 Test", description: nil,
            exercises: [],
            estimatedDurationMinutes: 30,
            createdAt: Date(), updatedAt: Date(),
            blocks: nil
        )

        let payload = encoder.encode(workout: workout)
        XCTAssertNil(payload["v"])  // v1 has no version field
        XCTAssertNotNil(payload["exercises"])
        XCTAssertEqual(payload["id"] as? String, "w4")
    }

    func testEncodeV1FallbackWhenEmptyBlocks() {
        let workout = Workout(
            id: "w5", name: "V1 Empty Blocks", description: nil,
            exercises: [],
            estimatedDurationMinutes: 30,
            createdAt: Date(), updatedAt: Date(),
            blocks: []
        )

        let payload = encoder.encode(workout: workout)
        XCTAssertNil(payload["v"])  // empty blocks falls back to v1
        XCTAssertNotNil(payload["exercises"])
    }

    func testEncodeV2MultipleBlocks() {
        let workout = Workout(
            id: "w6", name: "Multi-Block", description: nil,
            exercises: [],
            estimatedDurationMinutes: 45,
            createdAt: Date(), updatedAt: Date(),
            blocks: [
                .sequential(name: "Warmup", exercises: [
                    SequentialExerciseDef(id: "ex1", name: "Light Row", sets: [
                        BlockSetParams(setIndex: 0, reps: nil, weightKg: nil, durationSeconds: 300, distanceMeters: nil, restSeconds: nil)
                    ])
                ]),
                .emom(name: nil, intervalSeconds: 60, rounds: [
                    EmomRound(roundIndex: 0, sets: [
                        EmomSetDef(exerciseId: "ex2", exerciseName: "Burpee", reps: 10, weightKg: nil, durationSeconds: nil, distanceMeters: nil)
                    ])
                ]),
                .amrap(name: nil, timeCapSeconds: 600, sets: [
                    AmrapSetDef(exerciseId: "ex3", exerciseName: "KB Swing", reps: 20, weightKg: 24.0, durationSeconds: nil, distanceMeters: nil)
                ])
            ]
        )

        let payload = encoder.encode(workout: workout)
        let blocks = payload["blocks"] as? [[String: Any]]
        XCTAssertEqual(blocks?.count, 3)
        XCTAssertEqual(blocks?[0]["type"] as? String, "sequential")
        XCTAssertEqual(blocks?[1]["type"] as? String, "emom")
        XCTAssertEqual(blocks?[2]["type"] as? String, "amrap")
        // nameless blocks should not have name key
        XCTAssertNil(blocks?[1]["name"])
        XCTAssertNil(blocks?[2]["name"])
    }
}
