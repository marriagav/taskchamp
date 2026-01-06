import SwiftUI
import taskchampShared

/// Global settings view for critical alerts.
/// Shows authorization status, master toggle, and default volume preset.
struct CriticalAlertGlobalSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) private var openURL

    @State private var criticalAlertsEnabled: Bool = true
    @State private var defaultVolumePreset: TCCriticalAlertVolumePreset = .full
    @State private var authorizationStatus: CriticalAlertAuthorizationStatus = .notDetermined

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Authorization Status")
                        Spacer()
                        statusBadge(for: authorizationStatus)
                    }

                    if authorizationStatus == .denied {
                        Button {
                            openSystemSettings()
                        } label: {
                            Label("Open Settings", systemImage: "gear")
                        }
                    } else if authorizationStatus == .notDetermined {
                        Button {
                            requestAuthorization()
                        } label: {
                            Label("Request Permission", systemImage: "bell.badge")
                        }
                    }
                } header: {
                    Text("Permission")
                } footer: {
                    if authorizationStatus == .denied {
                        Text("Critical alerts are denied. Enable them in System Settings > Notifications > Taskchamp.")
                    } else if authorizationStatus == .authorized {
                        Text("Critical alerts can bypass Do Not Disturb and silent mode.")
                    } else {
                        // swiftlint:disable:next line_length
                        Text("Critical alerts require special permission to bypass Do Not Disturb. Note: Production apps require Apple approval.")
                    }
                }

                Section {
                    Toggle(isOn: $criticalAlertsEnabled) {
                        Label {
                            Text("Enable Critical Alerts")
                        } icon: {
                            Image(systemName: "bell.badge.fill")
                                .foregroundStyle(criticalAlertsEnabled ? .red : .secondary)
                        }
                    }
                    .disabled(authorizationStatus != .authorized)
                    .onChange(of: criticalAlertsEnabled) { _, newValue in
                        NotificationService.shared.criticalAlertsEnabled = newValue
                    }
                } header: {
                    Text("Global Toggle")
                } footer: {
                    Text("When disabled, all critical alerts will be delivered as regular notifications.")
                }

                Section {
                    Picker("Default Volume", selection: $defaultVolumePreset) {
                        ForEach(TCCriticalAlertVolumePreset.allCases, id: \.self) { preset in
                            Text(preset.displayName).tag(preset)
                        }
                    }
                    .disabled(authorizationStatus != .authorized || !criticalAlertsEnabled)
                    .onChange(of: defaultVolumePreset) { _, newValue in
                        NotificationService.shared.defaultCriticalAlertVolumePreset = newValue
                    }
                } header: {
                    Text("Default Volume Preset")
                } footer: {
                    Text("This volume preset will be used as the default when creating new critical alerts.")
                }

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        InfoRow(
                            icon: "exclamationmark.triangle.fill",
                            iconColor: .orange,
                            title: "What are Critical Alerts?",
                            // swiftlint:disable:next line_length
                            description: "Critical alerts play sound even when your device is muted or in Do Not Disturb mode."
                        )
                        InfoRow(
                            icon: "bell.badge.fill",
                            iconColor: .red,
                            title: "When to Use",
                            description: "Use critical alerts for time-sensitive reminders that you cannot miss."
                        )
                        InfoRow(
                            icon: "speaker.wave.3.fill",
                            iconColor: .blue,
                            title: "Volume Control",
                            description: "You can adjust the volume for each critical alert independently."
                        )
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("About Critical Alerts")
                }
            }
            .navigationTitle("Critical Alerts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .bold()
                }
            }
            .onAppear {
                loadCurrentSettings()
            }
            .onReceive(
                NotificationCenter.default.publisher(for: .TCCriticalAlertAuthorizationChanged)
            ) { notification in
                if let status = notification.object as? CriticalAlertAuthorizationStatus {
                    authorizationStatus = status
                }
            }
        }
    }

    private func loadCurrentSettings() {
        criticalAlertsEnabled = NotificationService.shared.criticalAlertsEnabled
        defaultVolumePreset = NotificationService.shared.defaultCriticalAlertVolumePreset
        authorizationStatus = NotificationService.shared.criticalAlertStatus
    }

    private func requestAuthorization() {
        NotificationService.shared.requestCriticalAlertAuthorization { _, _ in
            Task { @MainActor in
                await NotificationService.shared.updateCriticalAlertStatus()
            }
        }
    }

    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }

    @ViewBuilder
    private func statusBadge(for status: CriticalAlertAuthorizationStatus) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor(for: status))
                .frame(width: 8, height: 8)
            Text(status.displayName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func statusColor(for status: CriticalAlertAuthorizationStatus) -> Color {
        switch status {
        case .authorized:
            return .green
        case .denied:
            return .red
        case .notDetermined:
            return .orange
        }
    }
}

private struct InfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
