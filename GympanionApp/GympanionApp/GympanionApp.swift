// GympanionApp/GympanionApp.swift
import SwiftUI
import ConnectIQ

@main
struct GympanionApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let container = AppContainer.shared

    init() {
        GarminManager.shared.initialize()
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
