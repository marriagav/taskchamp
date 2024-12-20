import SwiftUI
import taskchampShared
import UIKit

extension TaskListView {
    private var searchedTasks: [TCTask] {
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

    private var isEditModeActive: Bool {
        return editMode.isEditing == true
    }

    func setDbUrl() throws {
        guard let path = taskChampionFileUrlString else {
            throw TCError.genericError("No access or path")
        }
        DBService.shared.setDbUrl(path)
    }

    func updateTasks(_ uuids: Set<String>, withStatus newStatus: TCTask.Status) {
        do {
            try setDbUrl()
            try DBService.shared.updatePendingTasks(uuids, withStatus: newStatus)
            NotificationService.shared.removeNotifications(for: Array(uuids))
            updateTasks()
        } catch {
            print(error)
        }
    }

    func updateTasks() {
        do {
            try setDbUrl()
            let newTasks = try DBService.shared.getTasks(
                sortType: sortType,
                filter: selectedFilter
            )
            if newTasks == tasks {
                return
            }
            withAnimation {
                tasks = newTasks
            }
        } catch {
            if !FileService.shared.isICloudAvailable() {
                print("iCloud Unavailable")
                isShowingICloudAlert = true
            }
            print(error)
        }
    }

    func copyDatabaseIfNeeded() {
        do {
            if taskChampionFileUrlString != nil {
                updateTasks()
                return
            }
            taskChampionFileUrlString = try FileService.shared.copyDatabaseIfNeededAndGetDestinationPath()
            updateTasks()
            NotificationService.shared.requestAuthorization { success, error in
                if success {
                    print("Notification Authorization granted")
                    Task {
                        let pending = try DBService.shared.getTasks(
                            sortType: sortType,
                            filter: .defaultFilter
                        )
                        await NotificationService.shared.createReminderForTasks(tasks: pending)
                    }
                } else if let error = error {
                    print(error.localizedDescription)
                }
            }
            return
        } catch {
            print(error)
        }
    }

    func handleDeepLink(url: URL) {
        Task {
            guard url.scheme == "taskchamp", url.host == "task" else {
                return
            }

            let uuidString = url.pathComponents[1]

            if uuidString == "new" {
                isShowingCreateTaskView = true
                return
            }

            do {
                try setDbUrl()
                let task = try DBService.shared.getTask(uuid: uuidString)
                pathStore.path.append(task)
            } catch {
                print(error)
            }
        }
    }
}
