// GympanionApp/presentation/features/workouts/WorkoutBuilderView.swift
import SwiftUI

struct WorkoutBuilderView: View {
    let workoutId: String?

    var body: some View {
        Text("TODO: Workout builder")
            .navigationTitle(workoutId == nil ? "New Workout" : "Edit Workout")
    }
}
