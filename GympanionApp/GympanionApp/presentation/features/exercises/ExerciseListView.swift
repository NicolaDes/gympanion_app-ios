// GympanionApp/presentation/features/exercises/ExerciseListView.swift
import SwiftUI

struct ExerciseListView: View {
    @Environment(AppContainer.self) private var container
    @Environment(AppRouter.self) private var router

    var body: some View {
        List {
            Text("Exercises will appear here")
        }
        .navigationTitle("Exercises")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add") { router.navigate(to: .exerciseEditor(nil)) }
            }
        }
    }
}
