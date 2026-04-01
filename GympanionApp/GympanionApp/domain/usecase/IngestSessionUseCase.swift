// GympanionApp/domain/usecase/IngestSessionUseCase.swift
import Foundation

final class IngestSessionUseCase {
    private let repository: any SessionRepository

    init(repository: any SessionRepository) {
        self.repository = repository
    }

    func callAsFunction(_ session: Session) async -> Result<Session, Error> {
        await repository.createSession(session)
    }
}
