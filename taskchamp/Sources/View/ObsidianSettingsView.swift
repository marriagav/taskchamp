import Foundation
import SwiftUI
import taskchampShared

struct ObsidianSettingsView: View, UseKeyboardToolbar {
    @Environment(StoreKitManager.self) var storeKit: StoreKitManager
    @Environment(\.dismiss) var dismiss

    @State private var obsidianVaultName = UserDefaultsManager.standard.getValue(forKey: .obsidianVaultName) ?? ""
    @State private var tasksFolderPath = UserDefaultsManager.standard.getValue(forKey: .tasksFolderPath) ?? ""
    @State private var showObsidianInfoPopover = false
    @State private var showPaywall = false

    @FocusState private var focusedField: FormField?
    enum FormField {
        case vaultName
        case folderPath
    }

    func calculateNextField() {
        switch focusedField {
        case .vaultName:
            focusedField = .folderPath
        case .folderPath:
            focusedField = .folderPath
        default:
            focusedField = nil
        }
    }

    func calculatePreviousField() {
        switch focusedField {
        case .vaultName:
            focusedField = .vaultName
        case .folderPath:
            focusedField = .vaultName
        default:
            focusedField = nil
        }
    }

    func onDismissKeyboard() {
        focusedField = nil
    }

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
                        .autocapitalization(.none)
                        .focused($focusedField, equals: .vaultName)
                    TextField("Tasks Folder Relative Path (Optional)", text: $tasksFolderPath)
                        .autocapitalization(.none)
                        .focused($focusedField, equals: .folderPath)
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if !storeKit.hasPremiumAccess() {
                            showPaywall = true
                            return
                        }
                        UserDefaultsManager.standard.set(value: obsidianVaultName, forKey: .obsidianVaultName)
                        if tasksFolderPath.last == "/" {
                            tasksFolderPath = String(tasksFolderPath.dropLast(1))
                        }
                        UserDefaultsManager.standard.set(value: tasksFolderPath, forKey: .tasksFolderPath)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .keyboard) {
                    KeyboardToolbarView(
                        onPrevious: {
                            calculatePreviousField()
                        },
                        onNext: {
                            calculateNextField()
                        },
                        onDismiss: {
                            onDismissKeyboard()
                        }
                    )
                }
            }
            .navigationDestination(isPresented: $showPaywall) {
                TCPaywall()
            }
            .navigationTitle("Obsidian Settings")
        }
    }
}
