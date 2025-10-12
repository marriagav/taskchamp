import Foundation
import taskchampShared
import UIKit

extension EditTaskView {
    func openExternalURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    func handleObsidianTap() {
        do {
            let obsidianVaultName: String? = UserDefaultsManager.shared.getValue(forKey: .obsidianVaultName)
            let tasksFolderPath: String = UserDefaultsManager.shared.getValue(forKey: .tasksFolderPath) ?? ""
            if obsidianVaultName == nil || obsidianVaultName?.isEmpty ?? true {
                isShowingObsidianSettings = true
                return
            }
            if !storeKit.hasPremiumAccess() {
                globalState.isShowingPaywall = true
                return
            }
            // TODO: Fix obsidian note creation
            if task.hasNote {
                let taskNoteWithPath = "\(tasksFolderPath)/\(task.obsidianNote ?? "")"
                let urlString = "obsidian://open?vault=\(obsidianVaultName ?? "")&file=\(taskNoteWithPath)"
                openExternalURL(urlString)
                return
            }
            let taskNote = task.description.replacing(" ", with: "-")
            let newTask = TCTask(
                uuid: task.uuid,
                project: task.project,
                description: task.description,
                status: task.status,
                priority: task.priority,
                due: task.due,
                obsidianNote: taskNote
            )
            try TaskchampionService.shared.updateTask(newTask)
            task = newTask
            let taskNoteWithPath = "\(tasksFolderPath)/\(task.obsidianNote ?? "")"
            let urlString = "obsidian://new?vault=\(obsidianVaultName ?? "")&file=\(taskNoteWithPath)"
            openExternalURL(urlString)
            return
        } catch {
            isShowingAlert = true
            alertTitle = "There was an error"
            alertMessage =
                "Failed to create task note. Please check your Obsidian vault and path settings and try again."
            print(error)
        }
    }

    func handleTaskActionTap() {
        do {
            globalState.isSyncingTasks = true
            let newStatus: TCTask.Status = task.isCompleted ? .pending : task
                .isDeleted ? .pending : .completed
            try TaskchampionService.shared.updatePendingTasks(
                [task.uuid],
                withStatus: newStatus
            ) {
                globalState.isSyncingTasks = false
            }
            if (newStatus == .completed) || (newStatus == .deleted) {
                NotificationService.shared.deleteReminderForTask(task: task)
            } else {
                NotificationService.shared.createReminderForTask(task: task)
            }
            dismiss()
        } catch {
            isShowingAlert = true
            alertTitle = "There was an error"
            alertMessage = "Task failed to update. Please try again."
            print(error)
        }
    }

    func updateTask() {
        if description.isEmpty {
            isShowingAlert = true
            alertTitle = "Missing field"
            alertMessage = "Please enter a task name"
            return
        }

        let date: Date? = didSetDate ? due : nil
        let time: Date? = didSetTime ? time : nil
        let finalDate = Calendar.current.mergeDateWithTime(date: date, time: time)
        let tags = tags.isEmpty ? nil : tags

        let task = TCTask(
            uuid: task.uuid,
            project: project.isEmpty ? nil : project,
            description: description,
            status: status,
            priority: priority == .none ? nil : priority,
            due: finalDate,
            tags: tags,
        )

        do {
            globalState.isSyncingTasks = true
            try TaskchampionService.shared.updateTask(task) {
                globalState.isSyncingTasks = false
            }
            NotificationService.shared.createReminderForTask(task: task)
            dismiss()
        } catch {
            isShowingAlert = true
            alertTitle = "There was an error"
            alertMessage = "Task failed to update. Please try again."
            print(error)
        }
    }

    func deleteTask() {
        do {
            globalState.isSyncingTasks = true
            try TaskchampionService.shared.updatePendingTasks([task.uuid], withStatus: .deleted) {
                globalState.isSyncingTasks = false
            }
            NotificationService.shared.deleteReminderForTask(task: task)
            dismiss()
        } catch {
            isShowingAlert = true
            alertTitle = "There was an error"
            alertMessage = "Task failed to update. Please try again."
            print(error)
        }
    }
}
