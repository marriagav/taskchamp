import Foundation
import taskchampShared
import UIKit

extension EditTaskView {
    func handleObsidianTap() {
        do {
            let obsidianVaultName: String? = UserDefaultsManager.shared.getValue(forKey: .obsidianVaultName)
            if obsidianVaultName == nil || obsidianVaultName?.isEmpty ?? true {
                isShowingObsidianSettings = true
                return
            }
            if !storeKit.hasPremiumAccess() {
                globalState.isShowingPaywall = true
                return
            }
            if task.hasNote {
                let noteUrl = try? FileService.shared.createObsidianNote(
                    for: task.obsidianNote ?? "",
                    taskStatus: task.status
                )
                guard let noteUrl else {
                    isShowingAlert = true
                    alertTitle = "There was an error"
                    alertMessage =
                        "Failed to create task note. Please check your Obsidian vault and path settings and try again."
                    return
                }
                _ = noteUrl

                showNoteView = true
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
            let noteUrl = try? FileService.shared.createObsidianNote(for: taskNote, taskStatus: task.status)

            guard let noteUrl else {
                isShowingAlert = true
                alertTitle = "There was an error"
                alertMessage =
                    "Failed to create task note. Please check your Obsidian vault and path settings and try again."
                return
            }

            _ = noteUrl

            try TaskchampionService.shared.updateTask(newTask)
            task = newTask

            showNoteView = true
            return
        } catch {
            isShowingAlert = true
            alertTitle = "There was an error"
            alertMessage =
                "Failed to create task note. Please check your Obsidian vault and path settings and try again."
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
                LocationService.shared.stopMonitoringRegion(for: task.uuid)
            } else {
                NotificationService.shared.createReminderForTask(task: task)
                if task.hasLocationReminder {
                    LocationService.shared.startMonitoringRegion(for: task)
                }
            }
            dismiss()
        } catch {
            isShowingAlert = true
            alertTitle = "There was an error"
            alertMessage = "Task failed to update. Please try again."
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

        let updatedTask = TCTask(
            uuid: task.uuid,
            project: project.isEmpty ? nil : project,
            description: description,
            status: status,
            priority: priority == .none ? nil : priority,
            due: finalDate,
            tags: tags,
            locationReminder: locationReminder
        )

        do {
            globalState.isSyncingTasks = true
            try TaskchampionService.shared.updateTask(updatedTask) {
                globalState.isSyncingTasks = false
            }
            NotificationService.shared.createReminderForTask(task: updatedTask)

            // Handle location reminder monitoring
            LocationService.shared.stopMonitoringRegion(for: task.uuid)
            if updatedTask.hasLocationReminder {
                LocationService.shared.startMonitoringRegion(for: updatedTask)
            }

            dismiss()
        } catch {
            isShowingAlert = true
            alertTitle = "There was an error"
            alertMessage = "Task failed to update. Please try again."
        }
    }

    func deleteTask() {
        do {
            globalState.isSyncingTasks = true
            try TaskchampionService.shared.updatePendingTasks([task.uuid], withStatus: .deleted) {
                globalState.isSyncingTasks = false
            }
            NotificationService.shared.deleteReminderForTask(task: task)
            LocationService.shared.stopMonitoringRegion(for: task.uuid)
            dismiss()
        } catch {
            isShowingAlert = true
            alertTitle = "There was an error"
            alertMessage = "Task failed to update. Please try again."
        }
    }
}
