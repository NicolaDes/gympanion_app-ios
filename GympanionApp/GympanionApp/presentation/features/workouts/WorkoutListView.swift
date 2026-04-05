// GympanionApp/presentation/features/workouts/WorkoutListView.swift
import SwiftUI

struct WorkoutListView: View {
    @Environment(AppRouter.self) private var router
    @Environment(AppContainer.self) private var container
    @State private var viewModel: WorkoutsViewModel?

    var body: some View {
        Group {
            if let viewModel {
                workoutList(vm: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Workouts")
        .onAppear {
            if viewModel == nil {
                viewModel = container.workoutsViewModel
            }
            viewModel?.loadWorkouts()
        }
    }

    @ViewBuilder
    private func workoutList(vm: WorkoutsViewModel) -> some View {
        switch vm.listState {
        case .idle, .loading:
            ProgressView()
        case .success(let workouts):
            List(workouts) { workout in
                Button {
                    router.navigate(to: .workoutDetail(workout.id))
                } label: {
                    workoutRow(workout)
                }
                .buttonStyle(.plain)
            }
        case .error(let message):
            ContentUnavailableView {
                Label("Error", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            }
        }
    }

    @ViewBuilder
    private func workoutRow(_ workout: Workout) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(workout.name)
                .font(.headline)

            if let description = workout.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                Label("\(workout.exercises.count) exercises", systemImage: "figure.strengthtraining.traditional")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if workout.estimatedDurationMinutes > 0 {
                    Label("\(workout.estimatedDurationMinutes) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let blocks = workout.blocks, !blocks.isEmpty {
                HStack(spacing: 6) {
                    ForEach(Array(blockTypeTags(blocks).enumerated()), id: \.offset) { _, tag in
                        Text(tag)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.accentColor.opacity(0.1))
                            .foregroundStyle(Color.accentColor)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func blockTypeTags(_ blocks: [WorkoutBlock]) -> [String] {
        var tags: [String] = []
        for block in blocks {
            switch block {
            case .sequential: if !tags.contains("Sequential") { tags.append("Sequential") }
            case .emom:       if !tags.contains("EMOM") { tags.append("EMOM") }
            case .amrap:      if !tags.contains("AMRAP") { tags.append("AMRAP") }
            }
        }
        return tags
    }
}
