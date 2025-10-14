import MarkdownUI
import SwiftUI
import taskchampShared

public struct ObsidianNoteView: View {
    @Environment(\.dismiss) var dismiss

    @State private var isFocused: Bool = false
    @State private var noteContent: String
    @State private var isPreviewMode: Bool = false

    private var taskNote: String
    private var noteUrl: URL?

    public init(taskNote: String) {
        self.taskNote = taskNote
        let contentAndUrl = try? FileService.shared.getContentsOfObsidianNote(for: taskNote)
        noteUrl = contentAndUrl?.1
        _noteContent = State(initialValue: contentAndUrl?.0 ?? "")
    }

    func openExternalURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    func getTaskNoteWithPath() -> String? {
        let tasksFolderPath: String = UserDefaultsManager.shared.getValue(forKey: .tasksFolderPath) ?? ""

        guard let noteUrl else {
            return nil
        }

        let taskNoteWithPath = FileService.shared
            .obsidianNoteAfter(component: tasksFolderPath, url: noteUrl) ??
            "\(tasksFolderPath)/\(taskNote)"

        return taskNoteWithPath
    }

    func getUrlString() -> String? {
        let obsidianVaultName: String? = UserDefaultsManager.shared.getValue(forKey: .obsidianVaultName)

        if obsidianVaultName == nil || obsidianVaultName?.isEmpty ?? true {
            return nil
        }

        guard let taskNoteWithPath = getTaskNoteWithPath() else { return nil
        }
        let urlString = "obsidian://open?vault=\(obsidianVaultName ?? "")&file=\(taskNoteWithPath)"

        return urlString
    }

    public var body: some View {
        VStack {
            if isPreviewMode {
                ScrollView {
                    VStack {
                        Markdown(noteContent)
                        Spacer()
                    }
                    .padding()
                }
            } else {
                InnerPaddedTextView(
                    text: $noteContent,
                    font: UIFont.monospacedSystemFont(ofSize: UIFont.labelFontSize, weight: .regular),
                    textContainerInset: UIEdgeInsets(top: 16, left: 18, bottom: 16, right: 18),
                    keyboardDismissMode: .onDrag,
                    isFirstResponder: $isFocused
                )
                .scrollDisabled(true)
            }

            // .onChange(of: noteContent) { newValue in
            //     do {
            //         try FileService.shared.saveSecureFileContents(url: noteUrl, contents: newValue)
            //     } catch {
            //         print("Error saving note: \(error)")
            //     }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Menu {
                    Button {
                        if let getUrlString = getUrlString() {
                            openExternalURL(getUrlString)
                        }
                    } label: {
                        Text("Open in Obsidian")
                    }

                    Button {
                        isPreviewMode.toggle()
                    } label: {
                        HStack {
                            Text("Toggle Preview")
                            if isPreviewMode {
                                Image(systemName: SFSymbols.checkmark.rawValue)
                            }
                        }
                    }
                } label: {
                    Label(
                        "Options",
                        systemImage: SFSymbols.ellipsisCircle.rawValue
                    )
                    .labelStyle(.iconOnly)
                    .imageScale(.large)
                    .bold()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Label(
                        "Done",
                        systemImage: SFSymbols.checkmark.rawValue
                    )
                    .labelStyle(.iconOnly)
                }
            }
        }
        .animation(.default, value: isPreviewMode)
        .navigationTitle(taskNote + ".md")
        .navigationBarTitleDisplayMode(.inline)
    }
}
