// GympanionApp/data/repository/SessionRepositoryImpl.swift
import Foundation

final class SessionRepositoryImpl: SessionRepository {
    private let apiService: any ApiServiceProtocol
    private let dao: SessionDao

    init(apiService: any ApiServiceProtocol, dao: SessionDao) {
        self.apiService = apiService
        self.dao = dao
    }

    func getAllSessions() -> AsyncStream<[Session]> {
        AsyncStream { continuation in
            let local = (try? dao.fetchAll()) ?? []
            continuation.yield(local.map { $0.toDomain() })
            continuation.finish()
        }
    }

    func getSessionById(_ id: String) -> AsyncStream<Session?> {
        AsyncStream { continuation in
            let entity = try? dao.fetchById(id)
            continuation.yield(entity?.toDomain())
            continuation.finish()
        }
    }

    func createSession(_ session: Session) async -> Result<Session, Error> {
        do {
            try dao.insert(session.toEntity())
            return .success(session)
        } catch {
            return .failure(error)
        }
    }

    func updateSession(_ session: Session) async -> Result<Session, Error> {
        do {
            try dao.delete(id: session.id)
            try dao.insert(session.toEntity())
            return .success(session)
        } catch {
            return .failure(error)
        }
    }

    func deleteSession(id: String) async -> Result<Void, Error> {
        do {
            try dao.delete(id: id)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    func getAnalytics(from: Date, to: Date) async -> Result<Analytics, Error> {
        do {
            let all = try dao.fetchAll()
            let filtered = all.filter {
                $0.startedAt >= from && $0.startedAt <= to
            }
            let sessions = filtered.map { $0.toDomain() }
            let analytics = computeAnalytics(from: sessions)
            return .success(analytics)
        } catch {
            return .failure(error)
        }
    }

    func syncSessions() async -> Result<Void, Error> {
        do {
            let dtos = try await apiService.fetchSessions()
            for dto in dtos {
                try? dao.delete(id: dto.id)
                try dao.insert(dto.toEntity())
            }
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    // MARK: - Analytics computation

    private func computeAnalytics(from sessions: [Session]) -> Analytics {
        let totalSessions = sessions.count
        var totalVolumeKg = 0.0
        var totalDurationMinutes = 0
        var allPRs: [PersonalRecord] = []

        for session in sessions {
            if let completed = session.completedAt {
                let minutes = Int(completed.timeIntervalSince(session.startedAt) / 60)
                totalDurationMinutes += minutes
            }
            for (exerciseId, sets) in session.sets {
                for set in sets {
                    if let weight = set.weightKg, let reps = set.reps {
                        totalVolumeKg += weight * Double(reps)
                    }
                }
                let maxWeight = session.sets[exerciseId]?.compactMap { $0.weightKg }.max() ?? 0
                if maxWeight > 0 {
                    allPRs.append(PersonalRecord(
                        id: UUID().uuidString,
                        exerciseId: exerciseId,
                        exerciseName: exerciseId,
                        value: maxWeight,
                        unit: "kg",
                        achievedAt: session.startedAt,
                        sessionId: session.id
                    ))
                }
            }
        }

        // Weekly activity: count sessions per week day
        let calendar = Calendar.current
        var weeklyMap: [Date: Int] = [:]
        for session in sessions {
            let day = calendar.startOfDay(for: session.startedAt)
            weeklyMap[day, default: 0] += 1
        }
        let weeklyActivity = weeklyMap.map { ProgressPoint(date: $0.key, value: Double($0.value), unit: "sessions") }
            .sorted { $0.date < $1.date }

        return Analytics(
            totalSessions: totalSessions,
            totalVolumeKg: totalVolumeKg,
            totalDurationMinutes: totalDurationMinutes,
            weeklyActivity: weeklyActivity,
            personalRecords: allPRs,
            exerciseProgress: [:]
        )
    }
}

// MARK: - Mapping helpers

private extension SessionEntity {
    func toDomain() -> Session {
        Session(
            id: id,
            workoutId: workoutId,
            workoutName: workoutName,
            startedAt: startedAt,
            completedAt: completedAt,
            sets: [:],
            notes: notes,
            garminDeviceId: garminDeviceId,
            blockResults: nil,
            totalDurationSeconds: nil
        )
    }
}

private extension Session {
    func toEntity() -> SessionEntity {
        SessionEntity(
            id: id,
            workoutId: workoutId,
            workoutName: workoutName,
            startedAt: startedAt,
            completedAt: completedAt,
            notes: notes,
            garminDeviceId: garminDeviceId
        )
    }
}

private extension SessionDto {
    func toEntity() -> SessionEntity {
        SessionEntity(
            id: id,
            workoutId: workoutId,
            workoutName: workoutName,
            startedAt: startedAt,
            completedAt: completedAt,
            notes: notes,
            garminDeviceId: garminDeviceId
        )
    }
}
