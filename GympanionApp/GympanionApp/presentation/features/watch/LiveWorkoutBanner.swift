// GympanionApp/presentation/features/watch/LiveWorkoutBanner.swift
import SwiftUI

struct LiveWorkoutBanner: View {
    let status: LiveWorkoutStatus
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Pulsing activity indicator
                Circle()
                    .fill(phaseColor)
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(status.workout.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(status.exerciseName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    HStack(spacing: 8) {
                        Text("\(status.completedSets) sets")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Text("\u{00B7}")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Text("\(status.completedReps) reps")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        if let hr = status.heartRate {
                            Text("\u{00B7}")
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            Label("\(hr)", systemImage: "heart.fill")
                                .font(.caption2)
                                .foregroundStyle(.red)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }

    private var phaseColor: Color {
        switch status.phase {
        case .work: return .green
        case .rest: return .orange
        case .idle: return .gray
        default: return .gray
        }
    }
}
