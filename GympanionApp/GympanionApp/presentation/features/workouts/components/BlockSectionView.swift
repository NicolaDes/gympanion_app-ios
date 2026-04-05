// GympanionApp/presentation/features/workouts/components/BlockSectionView.swift
import SwiftUI

struct BlockSectionView: View {
    let block: WorkoutBlock

    var body: some View {
        switch block {
        case .sequential(let name, let exercises):
            sequentialSection(name: name, exercises: exercises)
        case .emom(let name, let intervalSeconds, let rounds):
            emomSection(name: name, intervalSeconds: intervalSeconds, rounds: rounds)
        case .amrap(let name, let timeCapSeconds, let sets):
            amrapSection(name: name, timeCapSeconds: timeCapSeconds, sets: sets)
        }
    }

    // MARK: - Sequential

    @ViewBuilder
    private func sequentialSection(name: String?, exercises: [SequentialExerciseDef]) -> some View {
        Section {
            ForEach(exercises) { exercise in
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.body)
                        .fontWeight(.medium)
                    Text(sequentialSummary(exercise))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
        } header: {
            blockHeader(type: "Sequential", detail: name)
        }
    }

    private func sequentialSummary(_ exercise: SequentialExerciseDef) -> String {
        let setCount = exercise.sets.count
        // Use first set as representative (all sets typically share reps/weight)
        guard let first = exercise.sets.first else { return "\(setCount) sets" }

        var parts: [String] = ["\(setCount)"]

        if let reps = first.reps {
            parts[0] += "x\(reps)"
        }
        if let weight = first.weightKg {
            let formatted = weight.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "%.0f", weight) : String(format: "%.1f", weight)
            parts.append("@ \(formatted) kg")
        }
        if let rest = first.restSeconds {
            parts.append("rest \(rest)s")
        }
        return parts.joined(separator: " ")
    }

    // MARK: - EMOM

    @ViewBuilder
    private func emomSection(name: String?, intervalSeconds: Int, rounds: [EmomRound]) -> some View {
        Section {
            // Show the unique set patterns (often all rounds are the same)
            let uniquePatterns = emomUniquePatterns(rounds)
            ForEach(Array(uniquePatterns.enumerated()), id: \.offset) { _, pattern in
                VStack(alignment: .leading, spacing: 4) {
                    Text(pattern.name)
                        .font(.body)
                        .fontWeight(.medium)
                    Text(pattern.detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
        } header: {
            blockHeader(type: "EMOM", detail: name ?? "\(intervalSeconds)s x \(rounds.count) rounds")
        }
    }

    private struct EmomPattern: Equatable {
        let name: String
        let detail: String
    }

    private func emomUniquePatterns(_ rounds: [EmomRound]) -> [EmomPattern] {
        // Deduplicate identical rounds — show each unique set pattern once
        var seen: [EmomPattern] = []
        for round in rounds {
            for set in round.sets {
                var parts: [String] = []
                if let reps = set.reps { parts.append("\(reps) reps") }
                if let weight = set.weightKg {
                    let formatted = weight.truncatingRemainder(dividingBy: 1) == 0
                        ? String(format: "%.0f", weight) : String(format: "%.1f", weight)
                    parts.append("@ \(formatted) kg")
                }
                if let dur = set.durationSeconds { parts.append("\(dur)s") }
                let pattern = EmomPattern(name: set.exerciseName, detail: parts.joined(separator: " "))
                if !seen.contains(pattern) { seen.append(pattern) }
            }
        }
        return seen
    }

    // MARK: - AMRAP

    @ViewBuilder
    private func amrapSection(name: String?, timeCapSeconds: Int, sets: [AmrapSetDef]) -> some View {
        Section {
            ForEach(Array(sets.enumerated()), id: \.offset) { _, set in
                VStack(alignment: .leading, spacing: 4) {
                    Text(set.exerciseName)
                        .font(.body)
                        .fontWeight(.medium)
                    Text(amrapSetSummary(set))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
        } header: {
            blockHeader(type: "AMRAP", detail: name ?? "\(timeCapSeconds / 60) min")
        }
    }

    private func amrapSetSummary(_ set: AmrapSetDef) -> String {
        var parts: [String] = []
        if let reps = set.reps { parts.append("\(reps) reps") }
        if let weight = set.weightKg {
            let formatted = weight.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "%.0f", weight) : String(format: "%.1f", weight)
            parts.append("@ \(formatted) kg")
        }
        if let dur = set.durationSeconds { parts.append("\(dur)s") }
        return parts.isEmpty ? "—" : parts.joined(separator: " ")
    }

    // MARK: - Shared

    @ViewBuilder
    private func blockHeader(type: String, detail: String?) -> some View {
        HStack(spacing: 6) {
            Text(type)
                .font(.subheadline)
                .fontWeight(.semibold)
                .textCase(.uppercase)
            if let detail {
                Text("· \(detail)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
