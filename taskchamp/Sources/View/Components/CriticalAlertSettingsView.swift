import SwiftUI
import taskchampShared

/// A view that displays critical alert settings for a task reminder.
/// This view is always visible under the priority selector in task creation/editing views.
public struct CriticalAlertSettingsView: View {
    @Binding var criticalAlert: TCCriticalAlert?
    @Binding var hasDueDate: Bool

    @State private var isEnabled: Bool = false
    @State private var volumePreset: TCCriticalAlertVolumePreset = .full
    @State private var customVolume: Float = 1.0
    @State private var criticalAlertStatus: CriticalAlertAuthorizationStatus = .notDetermined

    private var canEnableCriticalAlert: Bool {
        hasDueDate && criticalAlertStatus == .authorized
    }

    private var disabledReason: String? {
        if criticalAlertStatus == .denied {
            return "Critical alerts are denied. Enable in Settings."
        } else if criticalAlertStatus == .notDetermined {
            return "Critical alert permission not requested."
        } else if !hasDueDate {
            return "Set a due date to enable critical alerts."
        }
        return nil
    }

    public init(criticalAlert: Binding<TCCriticalAlert?>, hasDueDate: Binding<Bool>) {
        self._criticalAlert = criticalAlert
        self._hasDueDate = hasDueDate
    }

    public var body: some View {
        Section {
            // Critical Alert Toggle
            Toggle(isOn: $isEnabled) {
                Label {
                    Text("Critical Alert")
                } icon: {
                    Image(systemName: isEnabled ? "bell.badge.fill" : "bell.badge")
                        .foregroundStyle(isEnabled ? .red : .secondary)
                }
            }
            .disabled(!canEnableCriticalAlert)
            .onChange(of: isEnabled) { _, _ in
                updateCriticalAlert()
            }

            // Volume Preset Selector - only enabled when toggle is ON
            if isEnabled && canEnableCriticalAlert {
                Picker("Volume", selection: $volumePreset) {
                    ForEach(TCCriticalAlertVolumePreset.allCases, id: \.self) { preset in
                        Text(preset.displayName).tag(preset)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: volumePreset) { _, newValue in
                    if newValue != .custom {
                        customVolume = newValue.volumeValue
                    }
                    updateCriticalAlert()
                }

                // Custom Volume Slider - only visible when Custom is selected
                if volumePreset == .custom {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "speaker.wave.1")
                                .foregroundStyle(.secondary)
                            Slider(value: $customVolume, in: 0.1...1.0, step: 0.05) {
                                Text("Volume")
                            }
                            .onChange(of: customVolume) { _, _ in
                                updateCriticalAlert()
                            }
                            Image(systemName: "speaker.wave.3")
                                .foregroundStyle(.secondary)
                            Text("\(Int(customVolume * 100))%")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(width: 45, alignment: .trailing)
                        }
                    }
                }
            }

            // Disabled reason or explanation
            if let reason = disabledReason {
                Text(reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if isEnabled {
                Text("Critical alerts sound even when muted or in Do Not Disturb.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            HStack {
                Text("Critical Alert")
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.caption)
            }
        }
        .onAppear {
            loadCurrentState()
            criticalAlertStatus = NotificationService.shared.criticalAlertStatus
        }
        .onReceive(
            NotificationCenter.default.publisher(for: .TCCriticalAlertAuthorizationChanged)
        ) { notification in
            if let status = notification.object as? CriticalAlertAuthorizationStatus {
                criticalAlertStatus = status
            }
        }
    }

    private func loadCurrentState() {
        if let alert = criticalAlert {
            isEnabled = alert.isEnabled
            volumePreset = alert.volumePreset
            customVolume = alert.customVolume
        } else {
            isEnabled = false
            volumePreset = NotificationService.shared.defaultCriticalAlertVolumePreset
            customVolume = volumePreset.volumeValue
        }
    }

    private func updateCriticalAlert() {
        if isEnabled {
            criticalAlert = TCCriticalAlert(
                isEnabled: true,
                volumePreset: volumePreset,
                customVolume: customVolume
            )
        } else {
            criticalAlert = nil
        }
    }
}
