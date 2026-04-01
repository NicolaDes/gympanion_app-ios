// GympanionApp/presentation/common/components/GympanionTopBar.swift
import SwiftUI

struct GympanionTopBar: View {
    let title: String
    var trailingAction: (() -> Void)? = nil
    var trailingLabel: String? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
            if let label = trailingLabel, let action = trailingAction {
                Button(label, action: action)
            }
        }
        .padding()
    }
}
