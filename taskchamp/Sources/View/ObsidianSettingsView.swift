import Foundation
import SwiftUI
import taskchampShared

struct ObsidianSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var obsidianVaultName = UserDefaultsManager.standard.getValue(forKey: .obsidianVaultName) ?? ""
    @State private var tasksFolderPath = UserDefaultsManager.standard.getValue(forKey: .tasksFolderPath) ?? ""
    @State private var showObsidianInfoPopover = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(
                        "Taskchamp can create task notes in Obsidian." +
                            "\n\nEnter the following case-sensitive details to enable this feature."
                    )
                    .bold()
                    .foregroundStyle(.secondary)
                    Button {
                        showObsidianInfoPopover.toggle()
                    } label: {
                        Label("Help", systemImage: SFSymbols.questionmarkCircle.rawValue)
                            .labelStyle(.titleAndIcon)
                    }
                    .popover(isPresented: $showObsidianInfoPopover, attachmentAnchor: .point(.bottom)) {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(
                                    // swiftlint:disable:next line_length
                                    "If you don't have an Obsidian vault, you can create one by downloading the Obsidian app."
                                )
                                .padding(.top)
                                Text("Vault name:")
                                    .bold()
                                Text("The name of your Obsidian vault")
                                    .padding(.bottom)
                                Text("Tasks Folder Relative Path:")
                                    .bold()
                                Text(
                                    // swiftlint:disable:next line_length
                                    "The relative path where you want to store your task notes in your Obsidian vault, this must be an existing folder, leave empty to store them in the root of the vault."
                                )
                            }
                        }
                        .textCase(nil)
                        .frame(minHeight: 300)
                        .padding()
                        .presentationCompactAdaptation(.popover)
                    }
                }
                Section {
                    TextField("Obsidian Vault Name", text: $obsidianVaultName)
                    TextField("Tasks Folder Relative Path (Optional)", text: $tasksFolderPath)
                        .autocapitalization(.none)
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        UserDefaultsManager.standard.set(value: obsidianVaultName, forKey: .obsidianVaultName)
                        if tasksFolderPath.last == "/" {
                            tasksFolderPath = String(tasksFolderPath.dropLast(1))
                        }
                        UserDefaultsManager.standard.set(value: tasksFolderPath, forKey: .tasksFolderPath)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .navigationTitle("Obsidian Settings")
        }
    }
}
