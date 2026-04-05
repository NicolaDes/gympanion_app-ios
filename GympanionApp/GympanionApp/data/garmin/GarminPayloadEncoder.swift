// GympanionApp/data/garmin/GarminPayloadEncoder.swift
import Foundation

struct GarminPayloadEncoder {

    // Auto-selects v1 or v2 based on workout structure
    func encode(workout: Workout) -> [String: Any] {
        if let blocks = workout.blocks, !blocks.isEmpty {
            return encodeV2(workout: workout, blocks: blocks)
        }
        return encodeV1(workout: workout)
    }

    // MARK: - V1 encoder (existing logic, renamed)

    private func encodeV1(workout: Workout) -> [String: Any] {
        let exercises = workout.exercises.map { we -> [String: Any] in
            var entry: [String: Any] = [
                "id": we.exercise.id,
                "name": we.exercise.name,
                "order": we.order
            ]
            if let sets = we.params.sets { entry["sets"] = sets }
            if let reps = we.params.reps { entry["reps"] = reps }
            if let weight = we.params.weightKg { entry["weight"] = weight }
            if let duration = we.params.durationSeconds { entry["durationSeconds"] = duration }
            if let rest = we.params.restSeconds { entry["rest"] = rest }
            return entry
        }
        return [
            "id": workout.id,
            "name": workout.name,
            "estimatedDurationMinutes": workout.estimatedDurationMinutes,
            "exercises": exercises
        ]
    }

    // MARK: - V2 encoder

    private func encodeV2(workout: Workout, blocks: [WorkoutBlock]) -> [String: Any] {
        [
            "v": 2,
            "type": "workout",
            "id": workout.id,
            "name": workout.name,
            "blocks": blocks.map { encodeBlock($0) }
        ]
    }

    // MARK: - Block encoding

    private func encodeBlock(_ block: WorkoutBlock) -> [String: Any] {
        switch block {
        case .sequential(let name, let exercises):
            return encodeSequentialBlock(name: name, exercises: exercises)
        case .emom(let name, let intervalSeconds, let rounds):
            return encodeEmomBlock(name: name, intervalSeconds: intervalSeconds, rounds: rounds)
        case .amrap(let name, let timeCapSeconds, let sets):
            return encodeAmrapBlock(name: name, timeCapSeconds: timeCapSeconds, sets: sets)
        }
    }

    private func encodeSequentialBlock(name: String?, exercises: [SequentialExerciseDef]) -> [String: Any] {
        var dict: [String: Any] = [
            "type": "sequential",
            "exercises": exercises.map { ex -> [String: Any] in
                [
                    "id": ex.id,
                    "name": ex.name,
                    "sets": ex.sets.map { encodeSetParams($0) }
                ]
            }
        ]
        if let name = name { dict["name"] = name }
        return dict
    }

    private func encodeEmomBlock(name: String?, intervalSeconds: Int, rounds: [EmomRound]) -> [String: Any] {
        var dict: [String: Any] = [
            "type": "emom",
            "intervalSec": intervalSeconds,
            "rounds": rounds.map { round -> [String: Any] in
                [
                    "ri": round.roundIndex,
                    "sets": round.sets.map { set -> [String: Any] in
                        var d: [String: Any] = [
                            "exId": set.exerciseId,
                            "name": set.exerciseName
                        ]
                        if let reps = set.reps { d["reps"] = reps }
                        if let wKg = set.weightKg { d["wKg"] = wKg }
                        if let durSec = set.durationSeconds { d["durSec"] = durSec }
                        if let distM = set.distanceMeters { d["distM"] = distM }
                        return d
                    }
                ]
            }
        ]
        if let name = name { dict["name"] = name }
        return dict
    }

    private func encodeAmrapBlock(name: String?, timeCapSeconds: Int, sets: [AmrapSetDef]) -> [String: Any] {
        var dict: [String: Any] = [
            "type": "amrap",
            "timeCapSec": timeCapSeconds,
            "sets": sets.map { set -> [String: Any] in
                var d: [String: Any] = [
                    "exId": set.exerciseId,
                    "name": set.exerciseName
                ]
                if let reps = set.reps { d["reps"] = reps }
                if let wKg = set.weightKg { d["wKg"] = wKg }
                if let durSec = set.durationSeconds { d["durSec"] = durSec }
                if let distM = set.distanceMeters { d["distM"] = distM }
                return d
            }
        ]
        if let name = name { dict["name"] = name }
        return dict
    }

    // MARK: - Set params encoding

    private func encodeSetParams(_ params: BlockSetParams) -> [String: Any] {
        var dict: [String: Any] = ["si": params.setIndex]
        if let reps = params.reps { dict["reps"] = reps }
        if let wKg = params.weightKg { dict["wKg"] = wKg }
        if let durSec = params.durationSeconds { dict["durSec"] = durSec }
        if let distM = params.distanceMeters { dict["distM"] = distM }
        if let restSec = params.restSeconds { dict["restSec"] = restSec }
        return dict
    }
}
