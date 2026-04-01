// GympanionApp/presentation/features/auth/LoginView.swift
import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @Environment(AppContainer.self) private var container
    @Environment(AppRouter.self) private var router

    var body: some View {
        VStack(spacing: 16) {
            Text("Gympanion").font(.largeTitle)
            TextField("Email", text: $email).textFieldStyle(.roundedBorder)
            SecureField("Password", text: $password).textFieldStyle(.roundedBorder)
            Button("Login") {
                Task { await AuthViewModel(useCase: container.authUseCase).login(email: email, password: password) }
            }
                .buttonStyle(.borderedProminent)
            Button("Register") { router.navigate(to: .register) }
        }
        .padding()
        .navigationTitle("Login")
    }
}
