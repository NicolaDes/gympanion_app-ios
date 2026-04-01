// GympanionApp/data/garmin/GarminPayloadEncoder.swift
import Foundation

struct GarminPayloadEncoder {
    func encode(workout: Workout) -> [String: Any] {
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
}
