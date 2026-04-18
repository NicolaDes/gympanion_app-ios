// GympanionApp/presentation/features/watch/LiveSessionView.swift
import SwiftUI

struct LiveSessionView: View {
    @Environment(AppContainer.self) private var container
    @Environment(AppRouter.self) private var router
    @State private var viewModel: LiveSessionViewModel?

    var body: some View {
        Group {
            if let viewModel, viewModel.isActive {
                liveContent(vm: viewModel)
            } else {
                noSessionContent
            }
        }
        .navigationTitle("Live Session")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel == nil {
                viewModel = LiveSessionViewModel(liveWorkoutService: container.liveWorkoutService)
            }
        }
        .onChange(of: viewModel?.isActive) { _, isActive in
            if isActive == false {
                router.pop()
            }
        }
    }

    @ViewBuilder
    private func liveContent(vm: LiveSessionViewModel) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                if vm.isConnectionLost {
                    connectionLostBanner
                }
                headerSection(vm: vm)
                currentExerciseCard(vm: vm)
                workoutProgressSection(vm: vm)
            }
            .padding()
            .opacity(vm.isConnectionLost ? 0.6 : 1.0)
        }
    }

    // MARK: - Connection Lost Banner

    private var connectionLostBanner: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.orange)
                .frame(width: 8, height: 8)
                .modifier(PulsingModifier())

            Text("Connection lost — waiting for watch...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Header

    @ViewBuilder
    private func headerSection(vm: LiveSessionViewModel) -> some View {
        VStack(spacing: 8) {
            Text(vm.workoutName)
                .font(.title2)
                .fontWeight(.bold)

            HStack(spacing: 16) {
                phaseBadge(vm: vm)

                if let elapsed = vm.sessionElapsedText {
                    Label(elapsed, systemImage: "clock")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let hr = vm.heartRateText {
                    Label(hr, systemImage: "heart.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    @ViewBuilder
    private func phaseBadge(vm: LiveSessionViewModel) -> some View {
        let phase = vm.status?.phase ?? .idle
        Text(vm.phaseText)
            .font(.caption)
            .fontWeight(.bold)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(phaseColor(phase).opacity(0.15))
            .foregroundStyle(phaseColor(phase))
            .clipShape(Capsule())
    }

    // MARK: - Current Exercise

    @ViewBuilder
    private func currentExerciseCard(vm: LiveSessionViewModel) -> some View {
        VStack(spacing: 8) {
            Text(vm.exerciseName)
                .font(.title3)
                .fontWeight(.semibold)

            Text(vm.currentSetText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                statItem(value: vm.completedSetsText, label: "Sets")
                statItem(value: vm.completedRepsText, label: "Reps")
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .monospacedDigit()

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Workout Progress

    @ViewBuilder
    private func workoutProgressSection(vm: LiveSessionViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Workout Progress")
                .font(.headline)
                .padding(.bottom, 4)

            ForEach(Array(vm.exercises.enumerated()), id: \.offset) { index, exercise in
                exerciseRow(exercise: exercise, state: vm.progressState(for: index))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func exerciseRow(exercise: LiveExerciseSummary, state: ExerciseProgressState) -> some View {
        HStack(spacing: 12) {
            stateIcon(state)

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.subheadline)
                    .fontWeight(state == .current ? .semibold : .regular)
                    .foregroundStyle(state == .completed ? .secondary : .primary)

                if exercise.targetSets > 0 || exercise.targetReps > 0 {
                    Text(exerciseSubtitle(exercise))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(state == .current ? Color.accentColor.opacity(0.08) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private func stateIcon(_ state: ExerciseProgressState) -> some View {
        switch state {
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.body)
        case .current:
            Image(systemName: "play.circle.fill")
                .foregroundStyle(Color.accentColor)
                .font(.body)
        case .upcoming:
            Image(systemName: "circle")
                .foregroundStyle(.tertiary)
                .font(.body)
        }
    }

    // MARK: - Helpers

    private func exerciseSubtitle(_ exercise: LiveExerciseSummary) -> String {
        var parts: [String] = []
        if exercise.targetSets > 0 { parts.append("\(exercise.targetSets) sets") }
        if exercise.targetReps > 0 { parts.append("\(exercise.targetReps) reps") }
        return parts.joined(separator: " \u{00D7} ")
    }

    private func phaseColor(_ phase: LiveSessionPhase) -> Color {
        switch phase {
        case .work: return .green
        case .rest: return .orange
        case .idle: return .gray
        case .blockComplete: return .blue
        case .finished: return .green
        case .paused: return .yellow
        case .exited: return .gray
        }
    }

    private var noSessionContent: some View {
        ContentUnavailableView {
            Label("No Active Session", systemImage: "applewatch")
        } description: {
            Text("Start a workout on your Garmin watch to see live progress here.")
        }
    }
}

// MARK: - Pulsing Animation

private struct PulsingModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .opacity(isPulsing ? 0.3 : 1.0)
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear { isPulsing = true }
    }
}
