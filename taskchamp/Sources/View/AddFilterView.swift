import Foundation
import SwiftData
import SwiftUI
import taskchampShared
import WidgetKit

public struct AddFilterView: View, UseKeyboardToolbar {
    @Environment(StoreKitManager.self) var storeKit: StoreKitManager

    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @Binding var selectedFilter: TCFilter

    @Query(sort: \TCFilter.order) var filters: [TCFilter]

    @State private var showNlpInfoPopover = false
    @State private var nlpInput = ""
    @State private var nlpPlaceholder =
        "project:my-project prio:M status:pending +tag -tag\n(project:A or project:B) +urgent"
    @State private var showPaywall = false

    @State private var isShowingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    @State private var editingFilter: TCFilter?
    @State private var editName = ""
    @State private var editQuery = ""

    @FocusState private var isFocusedNLP: Bool

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
                            addFilter()
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
                                if !storeKit.hasPremiumAccess() {
                                    showPaywall = true
                                    return
                                }
                                if filter == selectedFilter {
                                    selectedFilter = TCFilter.defaultFilter
                                } else {
                                    selectedFilter = filter
                                }
                                setSelectedFilterUserDefault(selectedFilter: selectedFilter)
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    if let name = filter.name, !name.isEmpty {
                                        Text(name)
                                            .font(.body)
                                    }
                                    HStack {
                                        Text(filter.fullDescription)
                                            .font(.system(.body, design: .monospaced))
                                            .foregroundStyle(
                                                (filter.name?.isEmpty == false)
                                                    ? .secondary : .primary
                                            )
                                        if selectedFilter.id == filter.id {
                                            Spacer()
                                            Image(systemName: SFSymbols.checkmark.rawValue)
                                        }
                                    }
                                }
                            }
                            .contextMenu {
                                Button {
                                    editName = filter.name ?? ""
                                    editQuery = filter.fullDescription
                                    editingFilter = filter
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
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
                        .onMove(perform: moveFilters)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !filters.isEmpty {
                        EditButton()
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
                        },
                        skipNextAndPrevious: {
                            skipNextAndPrevious()
                        }
                        // swiftlint:disable:next multiple_closures_with_trailing_closure
                    ) {
                        AutocompleteBarView(
                            text: $nlpInput,
                            surface: .filter
                        )
                    }
                }
            }
            .alert(isPresented: $isShowingAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .sheet(item: $editingFilter) { _ in
                NavigationStack {
                    Form {
                        Section(header: Text("Name")) {
                            TextField("Filter name (optional)", text: $editName)
                        }
                        Section(header: Text("Query")) {
                            TextField("Filter query", text: $editQuery)
                                .font(.system(.body, design: .monospaced))
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                        }
                    }
                    .navigationTitle("Edit Filter")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                editingFilter = nil
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                saveEditingFilter()
                            }
                            .bold()
                        }
                    }
                }
                .presentationDetents([.medium])
            }
            .navigationDestination(isPresented: $showPaywall) {
                TCPaywall()
            }
            .navigationTitle("Filter your tasks")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                syncFiltersToSharedUserDefaults()
            }
            .onChange(of: filters.count) {
                syncFiltersToSharedUserDefaults()
            }
        }
    }
}

extension AddFilterView {
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
        isFocusedNLP = false
    }

    private func setSelectedFilterUserDefault(selectedFilter: TCFilter) {
        do {
            try UserDefaultsManager.standard.setEncodableValue(selectedFilter, forKey: .selectedFilter)
        } catch { print(error) }
    }

    private func syncFiltersToSharedUserDefaults() {
        do {
            try UserDefaultsManager.shared.setEncodableValue(filters, forKey: .savedFilters)
            WidgetCenter.shared.reloadAllTimelines()
        } catch { print(error) }
    }

    private func addFilter() {
        if !storeKit.hasPremiumAccess() {
            showPaywall = true
            return
        }
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
            nlpFilter.order = filters.count
            modelContext.insert(nlpFilter)
            selectedFilter = nlpFilter

            setSelectedFilterUserDefault(selectedFilter: selectedFilter)

            nlpInput = ""
            isFocusedNLP = false
            dismiss()
        }
    }

    private func moveFilters(from source: IndexSet, to destination: Int) {
        var reordered = filters
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, filter) in reordered.enumerated() {
            filter.order = index
        }
        syncFiltersToSharedUserDefaults()
    }

    private func saveEditingFilter() {
        guard let filter = editingFilter else { return }
        let trimmedQuery = editQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedQuery.isEmpty {
            alertTitle = "Empty query"
            alertMessage = "Please enter a valid filter query"
            isShowingAlert = true
            return
        }
        if FilterParser.parse(trimmedQuery) == nil {
            alertTitle = "Invalid filter"
            alertMessage = "Please enter a valid filter query"
            isShowingAlert = true
            return
        }
        let trimmedName = editName.trimmingCharacters(in: .whitespacesAndNewlines)
        filter.name = trimmedName.isEmpty ? nil : trimmedName
        filter.fullDescription = trimmedQuery
        if selectedFilter.id == filter.id {
            selectedFilter = filter
            setSelectedFilterUserDefault(selectedFilter: selectedFilter)
        }
        syncFiltersToSharedUserDefaults()
        editingFilter = nil
    }
}
