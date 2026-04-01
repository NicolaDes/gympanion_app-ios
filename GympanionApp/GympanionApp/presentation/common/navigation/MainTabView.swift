// GympanionApp/presentation/common/navigation/MainTabView.swift
import SwiftUI

struct MainTabView: View {
    @Environment(AppContainer.self) private var container

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

            WatchSyncView(syncUseCase: container.syncWorkoutToWatchUseCase)
                .tabItem { Label("Watch", systemImage: "applewatch") }
        }
    }
}
