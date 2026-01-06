import SwiftUI
import taskchampShared

/// Settings view for configuring Apple Reminders capture
struct RemindersCaptureSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) private var openURL

    @State private var isEnabled: Bool = false
    @State private var authorizationStatus: RemindersAuthorizationStatus = .notDetermined
    @State private var availableLists: [RemindersList] = []
    @State private var selectedList: RemindersList?
    @State private var postImportAction: ReminderPostImportAction = .markComplete
    @State private var pendingCount: Int = 0
    @State private var isImporting: Bool = false
    @State private var lastImportResult: RemindersImportResult?
    @State private var showImportResultAlert: Bool = false

    private let service = RemindersCaptureService.shared

    var body: some View {
        NavigationStack {
            Form {
                // Permission Section
                Section {
                    HStack {
                        Text("Authorization Status")
                        Spacer()
                        statusBadge(for: authorizationStatus)
                    }

                    if authorizationStatus == .denied || authorizationStatus == .restricted {
                        Button {
                            openSystemSettings()
                        } label: {
                            Label("Open Settings", systemImage: "gear")
                        }
                    } else if authorizationStatus == .notDetermined {
                        Button {
                            requestAuthorization()
                        } label: {
                            Label("Grant Access", systemImage: "checkmark.circle")
                        }
                    }
                } header: {
                    Text("Permission")
                } footer: {
                    if authorizationStatus == .denied {
                        Text(
                            "Reminders access is denied. Enable it in System Settings > Privacy & Security > Reminders."
                        )
                    } else if authorizationStatus == .restricted {
                        Text("Reminders access is restricted on this device.")
                    } else if authorizationStatus == .authorized {
                        Text("Taskchamp can access your Reminders.")
                    } else {
                        Text("Taskchamp needs access to your Reminders to import tasks.")
                    }
                }

                // Enable Toggle Section
                Section {
                    Toggle(isOn: $isEnabled) {
                        Label {
                            Text("Enable Reminders Capture")
                        } icon: {
                            Image(systemName: "square.and.arrow.down")
                                .foregroundStyle(isEnabled ? .blue : .secondary)
                        }
                    }
                    .disabled(authorizationStatus != .authorized)
                    .onChange(of: isEnabled) { _, newValue in
                        service.isEnabled = newValue
                        if newValue {
                            Task {
                                await updatePendingCount()
                            }
                        }
                    }
                } header: {
                    Text("Capture")
                } footer: {
                    Text("When enabled, you can import incomplete reminders from a selected list into Taskchamp.")
                }

                // List Selection Section
                if isEnabled && authorizationStatus == .authorized {
                    Section {
                        Picker("Capture List", selection: $selectedList) {
                            Text("None").tag(nil as RemindersList?)
                            ForEach(availableLists) { list in
                                HStack {
                                    Circle()
                                        .fill(Color(cgColor: list.color ?? CGColor(gray: 0.5, alpha: 1)))
                                        .frame(width: 12, height: 12)
                                    Text(list.title)
                                }
                                .tag(list as RemindersList?)
                            }
                        }
                        .onChange(of: selectedList) { _, newValue in
                            if let list = newValue {
                                service.selectList(list)
                            } else {
                                service.clearListSelection()
                            }
                            Task {
                                await updatePendingCount()
                            }
                        }
                    } header: {
                        Text("Source List")
                    } footer: {
                        Text(
                            "Select the Reminders list to capture tasks from. Create a dedicated list like \"Taskchamp Inbox\" for best results."
                        )
                    }

                    // Post-Import Action Section
                    Section {
                        Picker("After Import", selection: $postImportAction) {
                            ForEach(ReminderPostImportAction.allCases, id: \.self) { action in
                                Text(action.displayName).tag(action)
                            }
                        }
                        .onChange(of: postImportAction) { _, newValue in
                            service.postImportAction = newValue
                        }
                    } header: {
                        Text("Post-Import Action")
                    } footer: {
                        switch postImportAction {
                        case .markComplete:
                            Text("Imported reminders will be marked as complete in Apple Reminders.")
                        case .delete:
                            Text("Imported reminders will be deleted from Apple Reminders.")
                        }
                    }

                    // Import Section
                    Section {
                        if pendingCount > 0 {
                            HStack {
                                Text("Pending Reminders")
                                Spacer()
                                Text("\(pendingCount)")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Button {
                            importReminders()
                        } label: {
                            HStack {
                                Label("Import Now", systemImage: "arrow.down.circle")
                                if isImporting {
                                    Spacer()
                                    ProgressView()
                                }
                            }
                        }
                        .disabled(selectedList == nil || isImporting || pendingCount == 0)
                    } header: {
                        Text("Manual Import")
                    } footer: {
                        if selectedList == nil {
                            Text("Select a capture list above to enable import.")
                        } else if pendingCount == 0 {
                            Text("No pending reminders to import from the selected list.")
                        } else {
                            Text(
                                "Tap to import \(pendingCount) reminder\(pendingCount == 1 ? "" : "s") into Taskchamp."
                            )
                        }
                    }
                }

                // Info Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        InfoRow(
                            icon: "mic.fill",
                            iconColor: .blue,
                            title: "Use with Siri",
                            description: "Say \"Hey Siri, remind me to...\" and your reminders will appear here for import."
                        )
                        InfoRow(
                            icon: "arrow.triangle.2.circlepath",
                            iconColor: .green,
                            title: "Automatic Background Import",
                            description: "Reminders are automatically imported when you open the app."
                        )
                        InfoRow(
                            icon: "checkmark.circle.fill",
                            iconColor: .orange,
                            title: "No Duplicates",
                            description: "Already imported reminders will be skipped to prevent duplicates."
                        )
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("About Reminders Capture")
                }
            }
            .navigationTitle("Reminders Capture")
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
            .onReceive(NotificationCenter.default.publisher(for: .TCRemindersAuthorizationChanged)) { notification in
                if let status = notification.object as? RemindersAuthorizationStatus {
                    authorizationStatus = status
                    if status == .authorized {
                        loadAvailableLists()
                    }
                }
            }
            .alert("Import Complete", isPresented: $showImportResultAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                if let result = lastImportResult {
                    if result.importedCount > 0 {
                        Text(
                            "Successfully imported \(result.importedCount) reminder\(result.importedCount == 1 ? "" : "s")."
                        )
                    } else if result.failedCount > 0 {
                        Text("Failed to import \(result.failedCount) reminder\(result.failedCount == 1 ? "" : "s").")
                    } else {
                        Text("No reminders to import.")
                    }
                }
            }
        }
    }

    private func loadCurrentSettings() {
        isEnabled = service.isEnabled
        postImportAction = service.postImportAction

        Task {
            await service.updateAuthorizationStatus()
            await MainActor.run {
                authorizationStatus = service.authorizationStatus
                if authorizationStatus == .authorized {
                    loadAvailableLists()
                }
            }
            if service.authorizationStatus == .authorized {
                await updatePendingCount()
            }
        }
    }

    private func loadAvailableLists() {
        availableLists = service.getAvailableLists()
        selectedList = service.getSelectedList()
    }

    private func requestAuthorization() {
        Task {
            _ = await service.requestAuthorization()
            await MainActor.run {
                authorizationStatus = service.authorizationStatus
                if authorizationStatus == .authorized {
                    loadAvailableLists()
                }
            }
        }
    }

    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }

    private func updatePendingCount() async {
        let count = await service.getIncompleteRemindersCount()
        await MainActor.run {
            pendingCount = count
        }
    }

    private func importReminders() {
        isImporting = true
        Task {
            do {
                let result = try await service.importReminders()
                await MainActor.run {
                    lastImportResult = result
                    showImportResultAlert = true
                    isImporting = false
                }
                await updatePendingCount()
            } catch {
                await MainActor.run {
                    lastImportResult = RemindersImportResult(importedCount: 0, failedCount: 1, errors: [error])
                    showImportResultAlert = true
                    isImporting = false
                }
            }
        }
    }

    @ViewBuilder
    private func statusBadge(for status: RemindersAuthorizationStatus) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor(for: status))
                .frame(width: 8, height: 8)
            Text(status.displayName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func statusColor(for status: RemindersAuthorizationStatus) -> Color {
        switch status {
        case .authorized:
            return .green
        case .denied, .restricted:
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
