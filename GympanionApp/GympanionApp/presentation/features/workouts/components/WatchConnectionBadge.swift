// GympanionApp/presentation/features/workouts/components/WatchConnectionBadge.swift
import SwiftUI

struct WatchConnectionBadge: View {
    let isConnected: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isConnected ? "applewatch.radiowaves.left.and.right" : "applewatch.slash")
                .font(.caption2)
            Text(isConnected ? "Watch Connected" : "Watch Disconnected")
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(isConnected ? Color.green.opacity(0.15) : Color.gray.opacity(0.15))
        .foregroundStyle(isConnected ? .green : .secondary)
        .clipShape(Capsule())
    }
}

#Preview("Connected") {
    WatchConnectionBadge(isConnected: true)
}

#Preview("Disconnected") {
    WatchConnectionBadge(isConnected: false)
}
