// GympanionApp/presentation/features/workouts/WorkoutDetailView.swift
import SwiftUI

struct WorkoutDetailView: View {
    let workoutId: String

    @Environment(AppContainer.self) private var container
    @State private var viewModel: WorkoutsViewModel?
    @State private var deviceTask: Task<Void, Never>?

    var body: some View {
        Group {
            if let viewModel {
                detailContent(vm: viewModel)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = container.workoutsViewModel
            }
            viewModel?.loadWorkout(id: workoutId)
            deviceTask = Task { await viewModel?.observeDevices() }
        }
        .onDisappear {
            deviceTask?.cancel()
            deviceTask = nil
        }
    }

    @ViewBuilder
    private func detailContent(vm: WorkoutsViewModel) -> some View {
        switch vm.detailState {
        case .idle, .loading:
            ProgressView()
        case .error(let message):
            ContentUnavailableView {
                Label("Error", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            }
        case .success(let workout):
            workoutDetail(workout: workout, vm: vm)
        }
    }

    @ViewBuilder
    private func workoutDetail(workout: Workout, vm: WorkoutsViewModel) -> some View {
        List {
            // Header section with description and watch badge
            Section {
                if let description = workout.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                WatchConnectionBadge(isConnected: vm.isWatchConnected)
            }

            // Block sections
            if let blocks = workout.blocks, !blocks.isEmpty {
                ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                    BlockSectionView(block: block)
                }
            } else {
                // Fallback: flat exercise list (v1 workouts without blocks)
                Section("Exercises") {
                    ForEach(workout.exercises) { we in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(we.exercise.name)
                                .font(.body)
                                .fontWeight(.medium)
                            Text(flatExerciseSummary(we.params))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle(workout.name)
        .safeAreaInset(edge: .bottom) {
            sendButton(workout: workout, vm: vm)
                .padding()
                .background(.ultraThinMaterial)
        }
    }

    @ViewBuilder
    private func sendButton(workout: Workout, vm: WorkoutsViewModel) -> some View {
        VStack(spacing: 8) {
            Button {
                Task { await vm.sendToWatch(workout: workout) }
            } label: {
                HStack(spacing: 8) {
                    switch vm.sendState {
                    case .idle:
                        Image(systemName: "applewatch.and.arrow.forward")
                        Text("Send to Watch")
                    case .sending:
                        ProgressView()
                            .controlSize(.small)
                        Text("Sending...")
                    case .sent:
                        Image(systemName: "checkmark.circle.fill")
                        Text("Sent!")
                    case .error:
                        Image(systemName: "applewatch.and.arrow.forward")
                        Text("Send to Watch")
                    }
                }
                .frame(maxWidth: .infinity)
                .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!vm.isWatchConnected || vm.sendState == .sending)

            // Error message
            if case .error(let message) = vm.sendState {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(message)
                }
                .font(.caption)
                .foregroundStyle(.red)
                .onTapGesture { vm.resetSendState() }
            }
        }
    }

    private func flatExerciseSummary(_ params: ExerciseParams) -> String {
        var parts: [String] = []
        if let sets = params.sets, let reps = params.reps {
            parts.append("\(sets)x\(reps)")
        }
        if let weight = params.weightKg {
            let formatted = weight.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "%.0f", weight) : String(format: "%.1f", weight)
            parts.append("@ \(formatted) kg")
        }
        if let rest = params.restSeconds {
            parts.append("rest \(rest)s")
        }
        return parts.joined(separator: " ")
    }
}
