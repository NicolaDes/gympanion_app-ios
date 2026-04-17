// GympanionApp/presentation/common/navigation/RootView.swift
import SwiftUI

struct RootView: View {
    @Environment(AppContainer.self) private var container
    @State private var router = AppRouter()

    var body: some View {
        NavigationStack(path: $router.path) {
            MainTabView()
                .navigationDestination(for: AppRoute.self) { route in
                    destination(for: route)
                }
        }
        .environment(router)
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .login: LoginView()
        case .register: RegisterView()
        case .exerciseList: ExerciseListView()
        case .exerciseDetail(let id): ExerciseDetailView(exerciseId: id)
        case .exerciseEditor(let id): ExerciseEditorView(exerciseId: id)
        case .workoutList: WorkoutListView()
        case .workoutDetail(let id): WorkoutDetailView(workoutId: id)
        case .workoutBuilder(let id): WorkoutBuilderView(workoutId: id)
        case .sessionHistory: SessionHistoryView()
        case .sessionDetail(let id): SessionDetailView(sessionId: id)
        case .dashboard: DashboardView()
        case .exerciseProgress(let id): ExerciseProgressView(exerciseId: id)
        case .prList: PRListView()
        case .feed: FeedView()
        case .profile(let id): ProfileView(userId: id)
        case .watchSync: WatchSyncView(syncUseCase: container.syncWorkoutToWatchUseCase)
        case .liveSession: LiveSessionView()
        }
    }
}
