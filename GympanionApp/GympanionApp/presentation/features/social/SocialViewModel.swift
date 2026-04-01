// GympanionApp/presentation/features/social/SocialViewModel.swift
import Foundation

@Observable
final class SocialViewModel {
    var feedState: UiState<[Session]> = .idle
    var profileState: UiState<User> = .idle

    private let authUseCase: AuthUseCase

    init(authUseCase: AuthUseCase) {
        self.authUseCase = authUseCase
    }

    func loadFeed() async {
        feedState = .loading
        // Social feed not yet available via API — show empty list
        feedState = .success([])
    }

    func loadProfile(userId: String?) async {
        profileState = .loading
        for await user in authUseCase.currentUser() {
            if let user {
                profileState = .success(user)
            } else {
                profileState = .error("Not logged in")
            }
        }
    }
}
