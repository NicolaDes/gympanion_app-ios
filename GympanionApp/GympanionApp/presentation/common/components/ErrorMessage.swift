// GympanionApp/presentation/common/components/ErrorMessage.swift
import SwiftUI

struct ErrorMessage: View {
    let message: String
    var retryAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 12) {
            Text(message)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
            if let retry = retryAction {
                Button("Retry", action: retry)
            }
        }
        .padding()
    }
}
