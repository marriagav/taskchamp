import Foundation
import SwiftData
import SwiftUI
import taskchampShared

public struct AddFilterView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @Binding var selectedFilter: TCFilter

    @Query var filters: [TCFilter]

    @State private var showNlpInfoPopover = false
    @State private var nlpInput = ""
    @State private var nlpPlaceholder = "project:my-project prio:M status:pending"

    @State private var isShowingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    @FocusState private var isFocusedNLP: Bool

    private func setSelectedFilterUserDefault(selectedFilter: TCFilter) {
        do {
            try UserDefaultsManager.standard.setEncodableValue(selectedFilter, forKey: .selectedFilter)
        } catch { print(error) }
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Filter", text: $nlpInput)
                        .font(.system(.body, design: .monospaced))
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .focused($isFocusedNLP)
                        .onAppear {
                            isFocusedNLP = false
                        }
                        .submitLabel(.go)
                        .onSubmit {
                            withAnimation {
                                if nlpInput.isEmpty {
                                    alertTitle = "Empty input"
                                    alertMessage = "Please enter a valid filter"
                                    isShowingAlert = true
                                    return
                                }
                                let nlpFilter = NLPService.shared.createFilter(from: nlpInput)
                                if !nlpFilter.isValidFilter {
                                    alertTitle = "Invalid filter"
                                    alertMessage = "Please enter a valid filter"
                                    isShowingAlert = true
                                    return
                                }
                                modelContext.insert(nlpFilter)
                                selectedFilter = nlpFilter

                                setSelectedFilterUserDefault(selectedFilter: selectedFilter)

                                nlpInput = ""
                                isFocusedNLP = false
                                dismiss()
                            }
                        }
                } header: {
                    HStack {
                        Text("Command Line Input")
                        Button {
                            showNlpInfoPopover.toggle()
                        } label: {
                            Image(systemName: SFSymbols.questionmarkCircle.rawValue)
                        }
                        .popover(isPresented: $showNlpInfoPopover, attachmentAnchor: .point(.bottom)) {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(
                                        "Add a filter via a command line input. The fields are optional. " +
                                            "The format is as follows:"
                                    )
                                    .padding(.top)
                                    Text(nlpPlaceholder)
                                        .font(.system(.body, design: .monospaced))
                                }
                            }
                            .textCase(nil)
                            .frame(minHeight: 150)
                            .padding()
                            .presentationCompactAdaptation(.popover)
                        }
                    }
                }
                Section(header: Text("Saved filters")) {
                    if filters.isEmpty {
                        ContentUnavailableView {
                            Label("No filters", systemImage: "bolt.heart")
                        } description: {
                            Text("Add a filter using the command line input above.")
                        }
                    } else {
                        ForEach(filters) { filter in
                            Button {
                                if filter == selectedFilter {
                                    selectedFilter = TCFilter.defaultFilter
                                } else {
                                    selectedFilter = filter
                                }
                                setSelectedFilterUserDefault(selectedFilter: selectedFilter)
                                dismiss()
                            } label: {
                                HStack {
                                    Text(
                                        filter.fullDescription
                                    )
                                    .font(.system(.body, design: .monospaced))
                                    if selectedFilter.id == filter.id {
                                        Spacer()
                                        Image(systemName: SFSymbols.checkmark.rawValue)
                                    }
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    withAnimation {
                                        modelContext.delete(filter)
                                        if filter == selectedFilter {
                                            selectedFilter = TCFilter.defaultFilter
                                            setSelectedFilterUserDefault(selectedFilter: selectedFilter)
                                        }
                                    }
                                } label: {
                                    Label("Delete", systemImage: SFSymbols.trash.rawValue)
                                }
                            }
                        }
                    }
                }
            }
            .alert(isPresented: $isShowingAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .navigationTitle("Filter your tasks")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
