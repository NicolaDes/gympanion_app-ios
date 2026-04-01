// GympanionApp/data/garmin/GarminManager.swift
import Foundation
import ConnectIQ

/// UUID of the CIQ watch app — replace with the UUID from your Connect IQ Store app page.
/// From gympanion_watch/manifest.xml  <iq:application id="...">
let kGarminWatchAppUUID = UUID(uuidString: "f98a251f-fbbe-4b0b-85de-d893670af9fe")!
let kGarminStoreUUID    = UUID(uuidString: "f98a251f-fbbe-4b0b-85de-d893670af9fe")!
/// Must match the CFBundleURLSchemes entry in Info.plist → URL Types.
let kGarminUrlScheme    = "gympanion-garmin"

extension Notification.Name {
    static let garminDevicesUpdated = Notification.Name("garminDevicesUpdated")
}

/// Separate @Observable container for the debug log so SwiftUI can track it
/// without fighting NSObject + ObservableObject constraints.
@Observable
final class GarminDebugLog {
    static let shared = GarminDebugLog()
    private init() {}
    var entries: [String] = []
    func clear() { entries.removeAll() }
}

final class GarminManager: NSObject {
    static let shared = GarminManager()

    /// Devices returned by Garmin Connect Mobile after `showDeviceSelection()`.
    private(set) var devices: [IQDevice] = []

    nonisolated(unsafe) private var continuations: [UUID: AsyncStream<[String: Any]>.Continuation] = [:]
    private let lock = NSLock()

    private override init() {}

    // MARK: - Lifecycle

    func initialize() {
        log("🔧 Initializing SDK with scheme '\(kGarminUrlScheme)'")
        ConnectIQ.sharedInstance().initialize(withUrlScheme: kGarminUrlScheme, uiOverrideDelegate: nil)
        log("✅ SDK initialized")
    }

    /// Opens Garmin Connect Mobile so the user can pick which devices to share.
    /// GCM calls back via the registered URL scheme — forward that URL to `handleOpenURL(_:)`.
    func showDeviceSelection() {
        log("📲 Opening GCM device selection…")
        ConnectIQ.sharedInstance().showDeviceSelection()
    }

    /// Call from `.onOpenURL` in GympanionApp.
    /// Parses the device list returned by GCM and registers delegates for each device.
    func handleOpenURL(_ url: URL) {
        log("🔗 URL received: \(url.absoluteString)")
        let parsed = ConnectIQ.sharedInstance().parseDeviceSelectionResponse(from: url) as? [IQDevice] ?? []
        log("📱 Parsed \(parsed.count) device(s)")
        for d in parsed { log("   • \(d.friendlyName) [\(d.modelName)] uuid=\(d.uuid)") }
        devices = parsed
        registerDelegates()
        NotificationCenter.default.post(name: .garminDevicesUpdated, object: nil)
    }

    // MARK: - Helpers

    private func registerDelegates() {
        log("🔌 Registering delegates for \(devices.count) device(s)")
        for device in devices {
            ConnectIQ.sharedInstance().register(forDeviceEvents: device, delegate: self)
            let app = IQApp(uuid: kGarminWatchAppUUID as NSUUID as UUID,
                            store: kGarminStoreUUID as NSUUID as UUID,
                            device: device)
            ConnectIQ.sharedInstance().register(forAppMessages: app, delegate: self)
            log("   ✅ Registered for '\(device.friendlyName)'")
        }
    }

    /// Development helper: register a device by its Garmin Unit ID (the 10-digit decimal
    /// number shown in Garmin Connect → device info page).
    /// Converts Unit ID → UUID using the ConnectIQ convention:
    ///   00000000-0000-0000-0000-00XXXXXXXXXX  (unit ID as 10 hex digits, zero-padded)
    func registerDeviceByUnitId(_ unitIdString: String, modelName: String = "fr265", friendlyName: String = "Forerunner 265") {
        guard let unitId = UInt64(unitIdString) else {
            log("❌ Invalid Unit ID '\(unitIdString)' — must be a plain decimal number")
            return
        }
        // Pad to 12 hex chars (48 bits) to fill the last UUID group
        let hex = String(format: "%012X", unitId)
        let uuidString = "00000000-0000-0000-0000-\(hex)"
        log("🔢 Unit ID \(unitId) → UUID \(uuidString)")

        guard let uuid = UUID(uuidString: uuidString),
              let device = IQDevice(id: uuid, modelName: modelName, friendlyName: friendlyName) else {
            log("❌ IQDevice init failed for uuid=\(uuidString)")
            return
        }
        log("🔧 Registering '\(friendlyName)' [\(modelName)] uuid=\(uuid)")
        devices = [device]
        registerDelegates()
        NotificationCenter.default.post(name: .garminDevicesUpdated, object: nil)
    }

    func isConnectIqAvailable() -> Bool { !devices.isEmpty }

    var connectedDevices: [String] { devices.map { $0.friendlyName } }

    // MARK: - Logging

    func log(_ message: String) {
        let entry = "[\(timestamp())] \(message)"
        print("[GarminManager] \(entry)")
        DispatchQueue.main.async { GarminDebugLog.shared.entries.append(entry) }
    }

    func clearLog() {
        DispatchQueue.main.async { GarminDebugLog.shared.clear() }
    }

    private func timestamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f.string(from: Date())
    }

    // MARK: - Raw message stream (fan-out to all subscribers)

    func messageStream() -> AsyncStream<[String: Any]> {
        let id = UUID()
        return AsyncStream { [weak self] continuation in
            self?.lock.lock()
            self?.continuations[id] = continuation
            self?.lock.unlock()

            continuation.onTermination = { [weak self] _ in
                self?.lock.lock()
                self?.continuations.removeValue(forKey: id)
                self?.lock.unlock()
            }
        }
    }

    private func broadcast(_ message: [String: Any]) {
        lock.lock()
        let snapshot = Array(continuations.values)
        lock.unlock()
        for cont in snapshot { cont.yield(message) }
    }
}

// MARK: - IQDeviceEventDelegate

extension GarminManager: IQDeviceEventDelegate {
    func deviceStatusChanged(_ device: IQDevice, status: IQDeviceStatus) {
        let statusName: String
        switch status {
        case .connected:        statusName = "connected"
        case .notConnected:     statusName = "not connected"
        case .notFound:         statusName = "not found"
        case .bluetoothNotReady: statusName = "bluetooth not ready"
        default:                statusName = "unknown(\(status.rawValue))"
        }
        log("📡 Device '\(device.friendlyName)' status → \(statusName)")
    }
}

// MARK: - IQAppMessageDelegate

extension GarminManager: IQAppMessageDelegate {
    func receivedMessage(_ message: Any, from app: IQApp) {
        log("📨 Message received from app \(app.uuid) on '\(app.device.friendlyName)': \(message)")
        let dict: [String: Any] = (message as? [String: Any]) ?? ["value": "\(message)"]
        broadcast(dict)
    }
}
