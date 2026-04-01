// GympanionApp/presentation/features/watch/WatchSyncView.swift
import SwiftUI

struct WatchSyncView: View {
    @State private var viewModel: WatchSyncViewModel
    @State private var listenTask: Task<Void, Never>?
    @State private var showManualEntry = false
    @State private var manualUUID = ""
    @State private var gcmReturnedNoDevices = false
    // Must be a @State stored property (not a local var) for @Observable tracking to persist
    @State private var debugLog = GarminDebugLog.shared

    init(syncUseCase: SyncWorkoutToWatchUseCase) {
        _viewModel = State(wrappedValue: WatchSyncViewModel(syncUseCase: syncUseCase))
    }

    var body: some View {
        content(vm: viewModel)
            .navigationTitle("Garmin Watch")
            .onAppear {
                Task { await viewModel.loadDevices() }
                listenTask = Task { await viewModel.startListening() }
            }
            .onDisappear {
                listenTask?.cancel()
                listenTask = nil
            }
    }

    @ViewBuilder
    private func content(vm: WatchSyncViewModel) -> some View {
        List {
            // ── Devices ───────────────────────────────────────────────
            Section {
                switch vm.devicesState {
                case .idle, .loading:
                    HStack { ProgressView(); Text("Scanning…").foregroundStyle(.secondary) }
                case .success(let devices) where devices.isEmpty:
                    VStack(alignment: .leading, spacing: 10) {
                        if gcmReturnedNoDevices {
                            Label("Garmin Connect returned no devices. Make sure your watch is paired in the Garmin Connect app, then try again.", systemImage: "exclamationmark.circle")
                                .foregroundStyle(.orange)
                                .font(.subheadline)
                        } else {
                            Text("No devices registered yet.")
                                .foregroundStyle(.secondary)
                        }
                        Button("Connect via Garmin Connect") {
                            gcmReturnedNoDevices = false
                            vm.connectDevices()
                        }
                        .buttonStyle(.borderedProminent)
                        Button("Register Device Manually") { showManualEntry = true }
                            .buttonStyle(.bordered)
                            .font(.subheadline)
                    }
                    .alert("Enter Garmin Unit ID", isPresented: $showManualEntry) {
                        TextField("e.g. 3761553371", text: $manualUUID)
                            .keyboardType(.numberPad)
                        Button("Register") {
                            GarminManager.shared.registerDeviceByUnitId(manualUUID)
                            Task { await vm.loadDevices() }
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("The 10-digit number shown in Garmin Connect → your device → Information page.")
                    }
                case .success(let devices):
                    ForEach(devices, id: \.self) { Label($0, systemImage: "applewatch") }
                case .error(let msg):
                    Label(msg, systemImage: "exclamationmark.triangle").foregroundStyle(.red)
                }
            } header: { Text("Connected Devices") }

            // ── Message log ───────────────────────────────────────────
            Section {
                if vm.messages.isEmpty {
                    Text(vm.isListening ? "Waiting for messages from watch…" : "Not listening")
                        .foregroundStyle(.secondary).font(.subheadline)
                } else {
                    ForEach(vm.messages) { msg in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(msg.title).font(.subheadline).fontWeight(.medium)
                                Spacer()
                                Text(msg.receivedAt, style: .time)
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                            Text(msg.detail).font(.caption).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            } header: {
                HStack {
                    Text("Incoming Messages")
                    Spacer()
                    if vm.isListening {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .foregroundStyle(.green).symbolEffect(.pulse)
                    }
                    if !vm.messages.isEmpty {
                        Button("Clear") { vm.messages.removeAll() }.font(.caption)
                    }
                }
            }

            // ── SDK debug log ─────────────────────────────────────────
            Section {
                if debugLog.entries.isEmpty {
                    Text("No events yet").foregroundStyle(.secondary).font(.caption)
                } else {
                    ForEach(debugLog.entries.indices, id: \.self) { i in
                        Text(debugLog.entries[i])
                            .font(.system(.caption2, design: .monospaced))
                    }
                }
            } header: {
                HStack {
                    Text("SDK Debug Log")
                    Spacer()
                    Button("Clear") { GarminManager.shared.clearLog() }.font(.caption)
                }
            }
        }
        .refreshable { await vm.loadDevices() }
        .onReceive(NotificationCenter.default.publisher(for: .garminDevicesUpdated)) { _ in
            Task {
                await viewModel.loadDevices()
                if case .success(let devices) = viewModel.devicesState, devices.isEmpty {
                    gcmReturnedNoDevices = true
                }
            }
        }
    }
}
