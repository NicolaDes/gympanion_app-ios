// GympanionApp/data/garmin/GarminPayloadDecoder.swift
import Foundation

enum GarminDecodeError: Error {
    case missingField(String)
    case invalidFormat
}

struct GarminPayloadDecoder {
    func decode(payload: [String: Any]) throws -> Session {
        guard let workoutId = payload["workoutId"] as? String else {
            throw GarminDecodeError.missingField("workoutId")
        }
        guard let workoutName = payload["workoutName"] as? String else {
            throw GarminDecodeError.missingField("workoutName")
        }
        let sessionId = payload["sessionId"] as? String ?? UUID().uuidString
        let deviceId = payload["deviceId"] as? String
        let startedAtMs = payload["startedAt"] as? Double ?? Date().timeIntervalSince1970 * 1000
        let startedAt = Date(timeIntervalSince1970: startedAtMs / 1000)
        var completedAt: Date?
        if let completedAtMs = payload["completedAt"] as? Double {
            completedAt = Date(timeIntervalSince1970: completedAtMs / 1000)
        }

        var sets: [String: [SetRecord]] = [:]
        if let rawSets = payload["sets"] as? [String: [[String: Any]]] {
            for (exerciseId, rawRecords) in rawSets {
                sets[exerciseId] = rawRecords.compactMap { record -> SetRecord? in
                    guard let setNumber = record["setNumber"] as? Int else { return nil }
                    let completedAtMs = record["completedAt"] as? Double ?? Date().timeIntervalSince1970 * 1000
                    return SetRecord(
                        setNumber: setNumber,
                        reps: record["reps"] as? Int,
                        weightKg: record["weightKg"] as? Double,
                        durationSeconds: record["durationSeconds"] as? Int,
                        distanceMeters: record["distanceMeters"] as? Double,
                        completedAt: Date(timeIntervalSince1970: completedAtMs / 1000)
                    )
                }
            }
        }

        return Session(
            id: sessionId,
            workoutId: workoutId,
            workoutName: workoutName,
            startedAt: startedAt,
            completedAt: completedAt,
            sets: sets,
            notes: payload["notes"] as? String,
            garminDeviceId: deviceId
        )
    }
}
