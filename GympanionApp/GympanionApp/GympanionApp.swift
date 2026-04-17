// GympanionApp/GympanionApp.swift
import SwiftUI
import ConnectIQ

@main
struct GympanionApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let container = AppContainer.shared

    init() {
        GarminManager.shared.initialize()
        // Start listening for live workout status from watch
        Task { @MainActor in
            AppContainer.shared.liveWorkoutService.startListening()
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(container)
                .onOpenURL { url in
                    // Required so Garmin Connect can pass the device list back to the app.
                    GarminManager.shared.handleOpenURL(url)
                }
        }
    }
}
