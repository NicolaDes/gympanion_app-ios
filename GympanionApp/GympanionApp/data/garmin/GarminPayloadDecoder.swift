// GympanionApp/data/garmin/GarminPayloadDecoder.swift
import Foundation

enum GarminDecodeError: Error {
    case missingField(String)
    case invalidFormat
    case unsupportedVersion(Int)
    case unknownMessageType(String)
}

enum GarminMessage {
    case sessionResultV1(Session)
    case sessionResultV2(Session)
    case workoutReplaceResponse(accepted: Bool)
    case setComplete([String: Any])
    case error(code: String, maxSupported: Int)
    case liveStatus(LiveWorkoutStatus)
    case unknown([String: Any])
}

struct GarminPayloadDecoder {

    // MARK: - Message routing

    func route(payload: [String: Any]) -> GarminMessage {
        guard let type = payload["type"] as? String else {
            // No type field → v1 session result (legacy)
            if let session = try? decodeV1(payload: payload) {
                return .sessionResultV1(session)
            }
            return .unknown(payload)
        }

        switch type {
        case "session_result":
            if let session = try? decodeV2SessionResult(payload: payload) {
                return .sessionResultV2(session)
            }
            return .unknown(payload)
        case "workout_replace_response":
            let accepted = payload["accepted"] as? Bool ?? false
            return .workoutReplaceResponse(accepted: accepted)
        case "set_complete":
            return .setComplete(payload)
        case "error":
            let code = payload["code"] as? String ?? "unknown"
            let maxSupported = payload["maxSupported"] as? Int ?? 0
            return .error(code: code, maxSupported: maxSupported)
        case "liveStatus":
            if let status = decodeLiveStatus(payload: payload) {
                return .liveStatus(status)
            }
            return .unknown(payload)
        default:
            return .unknown(payload)
        }
    }

    // MARK: - V1 session decoder (renamed from decode(payload:))

    func decodeV1(payload: [String: Any]) throws -> Session {
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
            garminDeviceId: deviceId,
            blockResults: nil,
            totalDurationSeconds: nil
        )
    }

    // Keep backward-compatible method signature
    func decode(payload: [String: Any]) throws -> Session {
        try decodeV1(payload: payload)
    }

    // MARK: - V2 session result decoder

    func decodeV2SessionResult(payload: [String: Any]) throws -> Session {
        guard let workoutId = payload["workoutId"] as? String else {
            throw GarminDecodeError.missingField("workoutId")
        }
        let sessionId = payload["sessionId"] as? String ?? UUID().uuidString
        let deviceId = payload["deviceId"] as? String

        let startedAtSec = payload["startedAt"] as? Double ?? Date().timeIntervalSince1970
        let startedAt = Date(timeIntervalSince1970: startedAtSec)

        var completedAt: Date?
        if let completedAtSec = payload["completedAt"] as? Double {
            completedAt = Date(timeIntervalSince1970: completedAtSec)
        }

        let totalDurationSec = payload["totalDurationSec"] as? Int

        var blockResults: [BlockResult] = []
        if let rawBlocks = payload["blocks"] as? [[String: Any]] {
            for rawBlock in rawBlocks {
                if let result = try? decodeBlockResult(rawBlock) {
                    blockResults.append(result)
                }
            }
        }

        return Session(
            id: sessionId,
            workoutId: workoutId,
            workoutName: "",  // v2 result doesn't carry workout name — look up from local DB
            startedAt: startedAt,
            completedAt: completedAt,
            sets: [:],  // v2 uses blockResults instead
            notes: nil,
            garminDeviceId: deviceId,
            blockResults: blockResults.isEmpty ? nil : blockResults,
            totalDurationSeconds: totalDurationSec
        )
    }

    // MARK: - Block result decoding

    private func decodeBlockResult(_ raw: [String: Any]) throws -> BlockResult {
        guard let type = raw["type"] as? String else {
            throw GarminDecodeError.missingField("type")
        }
        guard let bi = raw["bi"] as? Int else {
            throw GarminDecodeError.missingField("bi")
        }

        switch type {
        case "sequential":
            return try decodeSequentialBlockResult(raw, blockIndex: bi)
        case "emom":
            return try decodeEmomBlockResult(raw, blockIndex: bi)
        case "amrap":
            return try decodeAmrapBlockResult(raw, blockIndex: bi)
        default:
            throw GarminDecodeError.unknownMessageType(type)
        }
    }

    private func decodeSequentialBlockResult(_ raw: [String: Any], blockIndex: Int) throws -> BlockResult {
        guard let rawExercises = raw["exercises"] as? [[String: Any]] else {
            throw GarminDecodeError.missingField("exercises")
        }

        let exercises = rawExercises.compactMap { rawEx -> ExerciseResult? in
            guard let exId = rawEx["exId"] as? String,
                  let rawSets = rawEx["sets"] as? [[String: Any]] else { return nil }
            let sets = rawSets.compactMap { decodeSetResult($0) }
            return ExerciseResult(exerciseId: exId, sets: sets)
        }

        return .sequential(blockIndex: blockIndex, exercises: exercises)
    }

    private func decodeEmomBlockResult(_ raw: [String: Any], blockIndex: Int) throws -> BlockResult {
        guard let intervalSec = raw["intervalSec"] as? Int else {
            throw GarminDecodeError.missingField("intervalSec")
        }
        guard let rawRounds = raw["rounds"] as? [[String: Any]] else {
            throw GarminDecodeError.missingField("rounds")
        }

        let rounds = rawRounds.compactMap { rawRound -> EmomRoundResult? in
            guard let ri = rawRound["ri"] as? Int,
                  let ttc = rawRound["timeToCompleteSec"] as? Int,
                  let trem = rawRound["timeRemainingSec"] as? Int,
                  let rawSets = rawRound["sets"] as? [[String: Any]] else { return nil }
            let sets = rawSets.compactMap { decodeSetResult($0) }
            return EmomRoundResult(
                roundIndex: ri,
                timeToCompleteSeconds: ttc,
                timeRemainingSeconds: trem,
                sets: sets
            )
        }

        return .emom(blockIndex: blockIndex, intervalSeconds: intervalSec, rounds: rounds)
    }

    private func decodeAmrapBlockResult(_ raw: [String: Any], blockIndex: Int) throws -> BlockResult {
        guard let timeCapSec = raw["timeCapSec"] as? Int else {
            throw GarminDecodeError.missingField("timeCapSec")
        }
        guard let roundsCompleted = raw["roundsCompleted"] as? Int else {
            throw GarminDecodeError.missingField("roundsCompleted")
        }
        let partialReps = raw["partialReps"] as? Int ?? 0

        guard let rawRounds = raw["rounds"] as? [[String: Any]] else {
            throw GarminDecodeError.missingField("rounds")
        }

        let rounds = rawRounds.compactMap { rawRound -> AmrapRoundResult? in
            guard let ri = rawRound["ri"] as? Int,
                  let durMs = rawRound["durMs"] as? Int,
                  let rawSets = rawRound["sets"] as? [[String: Any]] else { return nil }
            let sets = rawSets.compactMap { decodeSetResult($0) }
            return AmrapRoundResult(
                roundIndex: ri,
                durationMs: durMs,
                isPartial: rawRound["partial"] as? Bool ?? false,
                sets: sets
            )
        }

        return .amrap(
            blockIndex: blockIndex,
            timeCapSeconds: timeCapSec,
            roundsCompleted: roundsCompleted,
            partialReps: partialReps,
            rounds: rounds
        )
    }

    // MARK: - Live status decoding

    func decodeLiveStatus(payload: [String: Any]) -> LiveWorkoutStatus? {
        guard let exerciseName = payload["exerciseName"] as? String,
              let currentExerciseIndex = payload["currentExerciseIndex"] as? Int,
              let currentSetIndex = payload["currentSetIndex"] as? Int,
              let completedSets = payload["completedSets"] as? Int,
              let completedReps = payload["completedReps"] as? Int,
              let phaseRaw = payload["phase"] as? Int,
              let phase = LiveSessionPhase(rawValue: phaseRaw),
              let workoutDict = payload["workout"] as? [String: Any],
              let workoutId = workoutDict["id"] as? String,
              let workoutName = workoutDict["name"] as? String else {
            return nil
        }

        let heartRateRaw = payload["heartRate"] as? Int
        let heartRate = (heartRateRaw != nil && heartRateRaw! > 0) ? heartRateRaw : nil

        var exercises: [LiveExerciseSummary] = []
        if let rawExercises = workoutDict["exercises"] as? [[String: Any]] {
            exercises = rawExercises.compactMap { dict -> LiveExerciseSummary? in
                guard let name = dict["name"] as? String else { return nil }
                let targetSets = dict["targetSets"] as? Int ?? 0
                let targetReps = dict["targetReps"] as? Int ?? 0
                return LiveExerciseSummary(name: name, targetSets: targetSets, targetReps: targetReps)
            }
        }

        let plan = LiveWorkoutPlan(id: workoutId, name: workoutName, exercises: exercises)

        return LiveWorkoutStatus(
            exerciseName: exerciseName,
            currentExerciseIndex: currentExerciseIndex,
            currentSetIndex: currentSetIndex,
            completedSets: completedSets,
            completedReps: completedReps,
            heartRate: heartRate,
            phase: phase,
            workout: plan,
            receivedAt: Date()
        )
    }

    // MARK: - Set result decoding

    private func decodeSetResult(_ raw: [String: Any]) -> SetResult? {
        guard let si = raw["si"] as? Int else { return nil }

        let completedAtSec = raw["completedAt"] as? Double ?? Date().timeIntervalSince1970
        let avgHr = raw["avgHr"] as? Int
        let peakHr = raw["peakHr"] as? Int

        return SetResult(
            setIndex: si,
            reps: raw["reps"] as? Int,
            weightKg: raw["wKg"] as? Double,
            durationMs: raw["durMs"] as? Int ?? 0,
            distanceMeters: raw["distM"] as? Double,
            avgHeartRate: avgHr != nil && avgHr! > 0 ? avgHr : nil,
            peakHeartRate: peakHr != nil && peakHr! > 0 ? peakHr : nil,
            completedAt: Date(timeIntervalSince1970: completedAtSec),
            skipped: raw["skipped"] as? Bool ?? false
        )
    }
}
