// GympanionApp/presentation/features/exercises/ExerciseEditorView.swift
import SwiftUI

struct ExerciseEditorView: View {
    let exerciseId: String?

    var body: some View {
        Text("TODO: Exercise editor")
            .navigationTitle(exerciseId == nil ? "New Exercise" : "Edit Exercise")
    }
}
