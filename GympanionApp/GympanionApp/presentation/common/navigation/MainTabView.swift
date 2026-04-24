// GympanionApp/presentation/common/navigation/MainTabView.swift
import SwiftUI

struct MainTabView: View {
    @Environment(AppContainer.self) private var container
    @Environment(AppRouter.self) private var router

    var body: some View {
        TabView {
            WorkoutListView()
                .tabItem { Label("Workouts", systemImage: "dumbbell") }

            ExerciseListView()
                .tabItem { Label("Exercises", systemImage: "figure.strengthtraining.traditional") }

            SessionHistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }

            DashboardView()
                .tabItem { Label("Analytics", systemImage: "chart.bar") }

            ProfileView(userId: nil)
                .tabItem { Label("Profile", systemImage: "person.circle") }

            WatchSyncView(viewModel: container.makeWatchSyncViewModel())
                .tabItem { Label("Watch", systemImage: "applewatch") }
        }
        .safeAreaInset(edge: .top) {
            if let status = container.liveWorkoutService.currentStatus {
                LiveWorkoutBanner(status: status) {
                    router.navigate(to: .liveSession)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: status)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: container.liveWorkoutService.currentStatus != nil)
    }
}
