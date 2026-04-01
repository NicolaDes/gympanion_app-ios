// GympanionApp/presentation/features/sessions/SessionsViewModel.swift
import Foundation

@Observable
final class SessionsViewModel {
    var historyState: UiState<[Session]> = .idle
    var detailState: UiState<Session> = .idle

    private let ingestUseCase: IngestSessionUseCase
    private let repository: any SessionRepository

    init(ingestUseCase: IngestSessionUseCase, repository: any SessionRepository) {
        self.ingestUseCase = ingestUseCase
        self.repository = repository
    }

    func loadHistory() async {
        historyState = .loading
        for await sessions in repository.getAllSessions() {
            historyState = .success(sessions)
        }
    }

    func loadSession(id: String) async {
        detailState = .loading
        for await session in repository.getSessionById(id) {
            if let session {
                detailState = .success(session)
            } else {
                detailState = .error("Session not found")
            }
        }
    }
}
