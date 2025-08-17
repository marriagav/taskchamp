import SwiftUI
import taskchampShared
import UIKit

extension TaskListView {
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

    func setDbUrl() throws {
        let localReplicaPath = try FileService.shared.getDestinationPathForLocalReplica()
        try TaskchampionService.shared
            .setDbUrl(
                path: localReplicaPath
            )
    }

    func updateTasks(_ uuids: Set<String>, withStatus newStatus: TCTask.Status) {
        do {
            try setDbUrl()
            try DBServiceDEPRECATED.shared.updatePendingTasks(uuids, withStatus: newStatus)
            NotificationService.shared.removeNotifications(for: Array(uuids))
            updateTasks()
        } catch {
            print(error)
        }
    }

    func updateTasks() {
        do {
            try setDbUrl()
            let newTasks = try TaskchampionService.shared.getTasks(sortType: sortType, filter: selectedFilter)
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
                let task = try TaskchampionService.shared.getTask(uuid: uuidString)
                pathStore.path.append(task)
            } catch {
                print(error)
            }
        }
    }
}
