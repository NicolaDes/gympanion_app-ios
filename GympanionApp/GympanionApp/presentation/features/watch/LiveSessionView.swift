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
        .navigationTitle("Session Detail")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel == nil {
                viewModel = LiveSessionViewModel(publisher: container.liveWorkoutService)
            }
        }
        .onChange(of: viewModel?.isActive) { _, isActive in
            if isActive == false {
                router.pop()
            }
        }
    }

    // MARK: - Live content

    @ViewBuilder
    private func liveContent(vm: LiveSessionViewModel) -> some View {
        ScrollView {
            VStack(spacing: 32) {
                phasePill(vm: vm)
                if let hr = vm.heartRate {
                    heartRateBlock(bpm: hr)
                }
                elapsedBlock(vm: vm)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.top, 32)
        }
    }

    // MARK: - Phase pill

    @ViewBuilder
    private func phasePill(vm: LiveSessionViewModel) -> some View {
        let tint = color(for: vm.phaseColor)
        Text(vm.phaseLabel)
            .font(.caption)
            .fontWeight(.bold)
            .tracking(0.5)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(tint.opacity(0.15))
            .foregroundStyle(tint)
            .clipShape(Capsule())
    }

    private func color(for phaseColor: PhaseColor) -> Color {
        switch phaseColor {
        case .active: return .green
        case .rest:   return .orange
        case .paused: return .yellow
        case .idle:   return .gray
        case .done:   return .blue
        }
    }

    // MARK: - Heart rate block

    @ViewBuilder
    private func heartRateBlock(bpm: Int) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
                Text("\(bpm)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(bpm)))
            }
            Text("BPM")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Elapsed block

    @ViewBuilder
    private func elapsedBlock(vm: LiveSessionViewModel) -> some View {
        VStack(spacing: 4) {
            Text(vm.elapsedDisplay)
                .font(.system(size: 56, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(vm.elapsedSeconds ?? 0)))
                .animation(.easeInOut(duration: 0.25), value: vm.elapsedSeconds)
            Text("Elapsed")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Fallback

    private var noSessionContent: some View {
        ContentUnavailableView {
            Label("No Active Session", systemImage: "applewatch")
        } description: {
            Text("Start a workout on your Garmin watch to see live progress here.")
        }
    }
}
