// GympanionApp/domain/repository/SessionRepository.swift
import Foundation

protocol SessionRepository {
    func getAllSessions() -> AsyncStream<[Session]>
    func getSessionById(_ id: String) -> AsyncStream<Session?>
    func createSession(_ session: Session) async -> Result<Session, Error>
    func updateSession(_ session: Session) async -> Result<Session, Error>
    func deleteSession(id: String) async -> Result<Void, Error>
    func getAnalytics(from: Date, to: Date) async -> Result<Analytics, Error>
    func syncSessions() async -> Result<Void, Error>
}
