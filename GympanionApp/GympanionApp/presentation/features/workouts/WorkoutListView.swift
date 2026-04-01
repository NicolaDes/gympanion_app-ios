// GympanionApp/presentation/features/workouts/WorkoutListView.swift
import SwiftUI

struct WorkoutListView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        List {
            Text("Workouts will appear here")
        }
        .navigationTitle("Workouts")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add") { router.navigate(to: .workoutBuilder(nil)) }
            }
        }
    }
}
