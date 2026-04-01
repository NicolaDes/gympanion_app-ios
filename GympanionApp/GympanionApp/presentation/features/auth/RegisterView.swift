// GympanionApp/presentation/features/auth/RegisterView.swift
import SwiftUI

struct RegisterView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @Environment(AppContainer.self) private var container
    @Environment(AppRouter.self) private var router

    var body: some View {
        VStack(spacing: 16) {
            TextField("Display Name", text: $displayName).textFieldStyle(.roundedBorder)
            TextField("Email", text: $email).textFieldStyle(.roundedBorder)
            SecureField("Password", text: $password).textFieldStyle(.roundedBorder)
            Button("Register") {
                Task { await AuthViewModel(useCase: container.authUseCase).register(email: email, password: password, displayName: displayName) }
            }
                .buttonStyle(.borderedProminent)
            Button("Back to Login") { router.pop() }
        }
        .padding()
        .navigationTitle("Register")
    }
}
