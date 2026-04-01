// GympanionApp/presentation/features/analytics/AnalyticsViewModel.swift
import Foundation

@Observable
final class AnalyticsViewModel {
    var dashboardState: UiState<Analytics> = .idle
    var progressState: UiState<[ProgressPoint]> = .idle
    var prState: UiState<[PersonalRecord]> = .idle

    private let fetchAnalyticsUseCase: FetchAnalyticsUseCase

    init(fetchAnalyticsUseCase: FetchAnalyticsUseCase) {
        self.fetchAnalyticsUseCase = fetchAnalyticsUseCase
    }

    func loadDashboard(from: Date, to: Date) async {
        dashboardState = .loading
        let result = await fetchAnalyticsUseCase(from: from, to: to)
        switch result {
        case .success(let analytics):
            dashboardState = .success(analytics)
            prState = .success(analytics.personalRecords)
        case .failure(let error):
            dashboardState = .error(error.localizedDescription)
        }
    }

    func loadProgress(exerciseId: String) async {
        progressState = .loading
        guard case .success(let analytics) = dashboardState else {
            progressState = .error("Load dashboard first")
            return
        }
        let points = analytics.exerciseProgress[exerciseId] ?? []
        progressState = .success(points)
    }

    func loadPRs() async {
        guard case .success(let analytics) = dashboardState else {
            prState = .error("Load dashboard first")
            return
        }
        prState = .success(analytics.personalRecords)
    }
}
