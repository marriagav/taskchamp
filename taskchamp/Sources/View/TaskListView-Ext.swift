import SwiftUI
import taskchampShared
import UIKit

extension TaskListView {
    var favoriteFilters: [TCFilter] {
        allFilters.filter { $0.isFavorite }
    }

    @ViewBuilder
    var favoriteFiltersMenu: some View {
        Menu {
            if favoriteFilters.isEmpty {
                Text("No favorite filters")
            } else {
                ForEach(favoriteFilters) { filter in
                    Button {
                        selectFilter(filter)
                    } label: {
                        if selectedFilter.id == filter.id {
                            Label(filter.displayName, systemImage: SFSymbols.checkmark.rawValue)
                        } else {
                            Text(filter.displayName)
                        }
                    }
                }
                Divider()
                Button {
                    selectFilter(.defaultFilter)
                } label: {
                    Label("Clear filters", systemImage: SFSymbols.backArrow.rawValue)
                }
                .disabled(selectedFilter.fullDescription == TCFilter.defaultFilter.fullDescription)
            }
            Divider()
            Button {
                isShowingFilterView = true
            } label: {
                Label("All Filters", systemImage: SFSymbols.star.rawValue)
            }
        } label: {
            Label("Favorite Filters", systemImage: "line.3.horizontal.decrease.circle")
        } primaryAction: {
            isShowingFilterView = true
        }
        .foregroundStyle(.tint)
    }

    func selectFilter(_ filter: TCFilter) {
        withAnimation {
            selectedFilter = filter
            do {
                let res = try JSONEncoder().encode(selectedFilter)
                UserDefaultsManager.standard.set(value: res, forKey: .selectedFilter)
            } catch { print(error) }
        }
    }

    var searchedTasks: [TCTask] {
        if searchText.isEmpty {
            return tasks
        }
        return tasks.filter { $0.description.localizedCaseInsensitiveContains(searchText) ||
            $0.project?.localizedCaseInsensitiveContains(searchText) ?? false ||
            $0.priority?.rawValue.localizedCaseInsensitiveContains(searchText) ?? false ||
            $0.localDate.localizedCaseInsensitiveContains(searchText)
            || $0.status.rawValue.localizedCaseInsensitiveContains(searchText)
            || $0.project?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }

    var isEditModeActive: Bool {
        return editMode.isEditing == true
    }

    func toggleStartStop(_ task: TCTask) {
        withAnimation {
            do {
                globalState.isSyncingTasks = true
                if task.isActive {
                    try TaskchampionService.shared.stopTask(task.uuid) {
                        globalState.isSyncingTasks = false
                    }
                } else {
                    try TaskchampionService.shared.startTask(task.uuid) {
                        globalState.isSyncingTasks = false
                    }
                }
                updateTasks()
            } catch {
                print(error)
            }
        }
    }

    func updateTasks(_ uuids: Set<String>, withStatus newStatus: TCTask.Status) {
        withAnimation {
            do {
                globalState.isSyncingTasks = true
                try TaskchampionService.shared.updatePendingTasks(uuids, withStatus: newStatus) {
                    globalState.isSyncingTasks = false
                }
                NotificationService.shared.removeNotifications(for: Array(uuids))
                updateTasks()
            } catch {
                print(error)
            }
        }
    }

    func updateTasksWithSync() async {
        do {
            globalState.isSyncingTasks = true
            try await TaskchampionService.shared.sync {
                globalState.isSyncingTasks = false
            }
            let newTasks = try TaskchampionService.shared.getTasks(sortType: sortType, filter: selectedFilter)
            if newTasks == tasks {
                return
            }
            withAnimation {
                tasks = newTasks
            }
        } catch {
            let syncService = TaskchampionService.shared.getSyncServiceFromType(selectedSyncType ?? .none)
            if !syncService.isAvailable() {
                isShowingICloudAlert = true
            }
        }
    }

    func updateTasks() {
        do {
            let newTasks = try TaskchampionService.shared.getTasks(sortType: sortType, filter: selectedFilter)
            if newTasks == tasks {
                return
            }
            withAnimation {
                tasks = newTasks
                rebuildingCache = false
            }
        } catch {
            let syncService = TaskchampionService.shared.getSyncServiceFromType(selectedSyncType ?? .none)
            if !syncService.isAvailable() {
                isShowingICloudAlert = true
            }
        }
    }

    func setupNotifications() {
        NotificationService.shared.requestAuthorization { success, error in
            if success {
                print("Notification Authorization granted")
                Task {
                    let pending = try TaskchampionService.shared.getTasks(
                        sortType: sortType,
                        filter: .defaultFilter
                    )
                    await NotificationService.shared.createReminderForTasks(tasks: pending)
                }
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
    }
}
