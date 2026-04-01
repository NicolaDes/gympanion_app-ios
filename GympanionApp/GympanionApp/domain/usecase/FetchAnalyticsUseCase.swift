// GympanionApp/domain/usecase/FetchAnalyticsUseCase.swift
import Foundation

final class FetchAnalyticsUseCase {
    private let repository: any SessionRepository

    init(repository: any SessionRepository) {
        self.repository = repository
    }

    func callAsFunction(from: Date, to: Date) async -> Result<Analytics, Error> {
        await repository.getAnalytics(from: from, to: to)
    }
}
