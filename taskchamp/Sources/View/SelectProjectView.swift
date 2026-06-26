import SwiftUI
import taskchampShared

public struct SelectProjectView: View, UseKeyboardToolbar {
    @Environment(StoreKitManager.self) var storeKit: StoreKitManager
    @Environment(\.dismiss) var dismiss

    @Binding var selectedProject: String

    @State private var input = ""
    @State private var allProjects: [String] = []
    @State private var showPaywall = false

    @FocusState private var isFocused: Bool

    public init(selectedProject: Binding<String>) {
        _selectedProject = selectedProject
    }

    var searchProjects: [String] {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return allProjects
        }
        return allProjects.filter { $0.localizedCaseInsensitiveContains(trimmed) }
    }

    func skipNextAndPrevious() -> Bool {
        return true
    }

    func calculateNextField() {}
    func calculatePreviousField() {}

    func onDismissKeyboard() {
        isFocused = false
    }

    private func choose(_ project: String) {
        if !storeKit.hasPremiumAccess() {
            showPaywall = true
            return
        }
        selectedProject = project
        dismiss()
    }

    private func submitInput() {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        choose(trimmed)
    }

    public var body: some View {
        Form {
            Section {
                TextField("new-project", text: $input)
                    .font(.system(.body, design: .monospaced))
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .focused($isFocused)
                    .submitLabel(.join)
                    .onSubmit { submitInput() }
            } header: {
                Text("Search or set a project")
            }
            Section(header: Text("Existing Projects")) {
                if allProjects.isEmpty {
                    ContentUnavailableView {
                        Label("No projects", systemImage: "bolt.heart")
                    } description: {
                        Text("Set a project using the input above.")
                    }
                } else {
                    ForEach(searchProjects, id: \.self) { project in
                        Button {
                            choose(project)
                        } label: {
                            HStack {
                                Text(project)
                                    .font(.system(.body, design: .monospaced))
                                if selectedProject == project {
                                    Spacer()
                                    Image(systemName: SFSymbols.checkmark.rawValue)
                                }
                            }
                        }
                    }
                }
            }
            if !selectedProject.isEmpty {
                Section {
                    Button(role: .destructive) {
                        selectedProject = ""
                        dismiss()
                    } label: {
                        Label("Clear project", systemImage: SFSymbols.trash.rawValue)
                    }
                }
            }
        }
        .navigationDestination(isPresented: $showPaywall) {
            TCPaywall()
        }
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                KeyboardToolbarView(
                    onPrevious: { calculatePreviousField() },
                    onNext: { calculateNextField() },
                    onDismiss: { onDismissKeyboard() },
                    skipNextAndPrevious: { skipNextAndPrevious() }
                )
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Label("Done", systemImage: SFSymbols.checkmark.rawValue)
                }
            }
        }
        .navigationTitle("Select Project")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.default, value: allProjects)
        .animation(.default, value: searchProjects)
        .onAppear {
            NLPService.shared.refreshProjectsCache()
            allProjects = NLPService.shared.projectsCache
        }
    }
}
