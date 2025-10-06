import SwiftData
import SwiftUI
import taskchampShared

public struct AddTagView: View, UseKeyboardToolbar {
    @Environment(StoreKitManager.self) var storeKit: StoreKitManager

    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @Binding var selectedTags: [TCTag]

    @Query var tags: [TCTag]
    var searchTags: [TCTag] {
        if input.isEmpty {
            return tags
        }
        return tags.filter { $0.name.lowercased().contains(input.lowercased()) }
    }

    @State private var showPopover = false
    @State private var input = ""
    @State private var showPaywall = false

    @State private var isShowingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    @FocusState private var isFocused: Bool

    func skipNextAndPrevious() -> Bool {
        return true
    }

    func calculateNextField() {
        // No next field
    }

    func calculatePreviousField() {
        // No previous field
    }

    func onDismissKeyboard() {
        isFocused = false
    }

    func onTapTagShared(tag: TCTag) -> Bool {
        if !storeKit.hasPremiumAccess() {
            showPaywall = true
            return false
        }
        if tag.isSynthetic() {
            alertTitle = "Synthetic tag"
            alertMessage = "You cannot add or remove synthetic tags manually."
            isShowingAlert = true
            return false
        }
        if !tag.isValid() {
            alertTitle = "Invalid tag"
            alertMessage = "Please enter a valid tag"
            isShowingAlert = true
            return false
        }
        return true
    }

    let instructions: LocalizedStringKey = """
    A Tag is a descriptor for a task, that is either present or absent, and can be used for filtering.

    Valid tags must not contain whitespace or any of the characters in `+-*/(<>^! %=~`.

    Tags composed of all uppercase letters are reserved for synthetic tags.

    The first characters additionally cannot be a digit, and subsequent characters cannot be `:`
    """

    public var body: some View {
        Form {
            Section {
                TextField("my-new-tag", text: $input)
                    .font(.system(.body, design: .monospaced))
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .focused($isFocused)
                    .onAppear {
                        isFocused = false
                    }
                    .submitLabel(.join)
                    .onSubmit {
                        withAnimation {
                            if input.isEmpty {
                                alertTitle = "Empty input"
                                alertMessage = "Please enter a valid tag"
                                isShowingAlert = true
                                return
                            }
                            let newTag = TCTag(name: input)
                            if !onTapTagShared(tag: newTag) {
                                return
                            }
                            selectedTags.append(newTag)
                            if !tags.contains(where: {
                                $0.name == newTag.name
                            }) {
                                modelContext.insert(newTag)
                            }

                            input = ""
                            isFocused = false
                        }
                    }
            } header: {
                HStack {
                    Text("Search or create a tag")
                    Button {
                        showPopover.toggle()
                    } label: {
                        Image(systemName: SFSymbols.questionmarkCircle.rawValue)
                    }
                    .popover(isPresented: $showPopover, attachmentAnchor: .point(.bottom)) {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(
                                    instructions
                                )
                                .padding(.top)
                            }
                        }
                        .textCase(nil)
                        .frame(minHeight: 150)
                        .padding()
                        .presentationCompactAdaptation(.popover)
                    }
                }
            }
            Section(header: Text("Saved Tags")) {
                if tags.isEmpty {
                    ContentUnavailableView {
                        Label("No tags", systemImage: "bolt.heart")
                    } description: {
                        Text("Add a new tag using the input above.")
                    }
                } else {
                    ForEach(searchTags, id: \.name) { tag in
                        Button {
                            if !onTapTagShared(tag: tag) {
                                return
                            }
                            if selectedTags.contains(where: { $0.name == tag.name }) {
                                selectedTags.removeAll { $0.name == tag.name }
                                input = ""
                                return
                            }
                            selectedTags.append(tag)
                            input = ""
                        } label: {
                            HStack {
                                Text(
                                    tag.name
                                )
                                .font(.system(.body, design: .monospaced))
                                if selectedTags.contains(where: { $0.name == tag.name }) {
                                    Spacer()
                                    Image(systemName: SFSymbols.checkmark.rawValue)
                                }
                            }
                        }
                        .disabled(tag.isSynthetic())
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            if !tag.isSynthetic() {
                                Button(role: .destructive) {
                                    withAnimation {
                                        modelContext.delete(tag)
                                        selectedTags.removeAll { $0.name == tag.name }
                                    }
                                } label: {
                                    Label("Delete", systemImage: SFSymbols.trash.rawValue)
                                }
                            }
                        }
                    }
                }
            }
        }
        .alert(isPresented: $isShowingAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .navigationDestination(isPresented: $showPaywall) {
            TCPaywall()
        }
        .toolbar {
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
                    },
                    skipNextAndPrevious: {
                        skipNextAndPrevious()
                    }
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
        .navigationTitle("Add Tags")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.default, value: tags)
        .animation(.default, value: searchTags)
        .animation(.default, value: selectedTags)
        .onAppear {
            for tag in selectedTags where
                !tags.contains(
                    where: { $0.name == tag.name }
                )
            // swiftlint:disable:next opening_brace
            {
                modelContext.insert(tag)
            }
        }
    }
}
