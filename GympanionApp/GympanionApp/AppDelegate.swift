// GympanionApp/AppDelegate.swift
import UIKit

/// Fallback URL handler for the Garmin ConnectIQ SDK.
///
/// The ConnectIQ SDK pre-dates SwiftUI's scene lifecycle. When Garmin Connect Mobile
/// returns the device-selection response, some iOS/GCM combinations deliver the URL
/// via the UIApplicationDelegate path rather than the scene delegate path (which
/// SwiftUI bridges to `onOpenURL`). This delegate catches that case so device
/// selection works reliably regardless of which path iOS uses.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        GarminManager.shared.handleOpenURL(url)
        return true
    }
}
