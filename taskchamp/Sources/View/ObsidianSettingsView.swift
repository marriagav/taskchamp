import Foundation
import SwiftUI
import taskchampShared

struct ObsidianSettingsView: View {
    @Environment(StoreKitManager.self) var storeKit: StoreKitManager
    @Environment(\.dismiss) var dismiss

    @State private var showObsidianInfoPopover = false
    @State var isImportingFile = false

    @State private var url: URL?

    @State private var didUpdate = false

    @State private var isShowingAlert = false

    var placeHolder: String {
        if let url {
            return url.path
        }
        if let taskNotesFolderPath: String = UserDefaultsManager.shared.getValue(forKey: .taskNotesFolderPath) {
            return taskNotesFolderPath
        }
        return "Select Notes Folder"
    }

    func onFileImportWithResult(_ result: Result<[URL], Error>) {
        switch result {
        case let .success(urls):
            guard let url = urls.first else {
                return
            }
            self.url = url
            didUpdate = true
        case .failure:
            isShowingAlert = true
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(
                        "Taskchamp can create task notes in Obsidian." +
                            "\n\nSelect the folder where you want to store your markdown notes to enable this feature."
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
                                    "It is recommended to select an Obsidian directory, inside of a vault. But it is possible to select any folder on your device."
                                )
                                .frame(minHeight: 100)
                            }
                        }
                        .textCase(nil)
                        .padding()
                        .presentationCompactAdaptation(.popover)
                    }
                }
                Section {
                    Button(action: {
                        isImportingFile = true
                    }, label: {
                        Label(
                            placeHolder,
                            systemImage: SFSymbols.folder.rawValue
                        )
                    })
                }
            }
            .fileImporter(
                isPresented: $isImportingFile,
                allowedContentTypes: [.folder],
                allowsMultipleSelection: false
            ) { result in
                onFileImportWithResult(result)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        do {
                            try FileService.shared.saveObsidianSettings(url: url)
                        } catch {
                            isShowingAlert = true
                            return
                        }
                        dismiss()
                    }.disabled(!didUpdate)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") {
                        dismiss()
                    }
                }
            }
            .alert(isPresented: $isShowingAlert) {
                Alert(
                    title: Text("There was an error"),
                    message: Text("Make sure that you select a valid folder"),
                    dismissButton: .default(Text("OK"))
                )
            }
            .navigationTitle("Obsidian Settings")
        }
    }
}
