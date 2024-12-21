import Foundation
import taskchampShared

extension EditTaskView {
    func handleObsidianTap() {
        do {
            let obsidianVaultName = UserDefaults.standard
                .string(forKey: "obsidianVaultName")
            let tasksFolderPath = UserDefaults.standard
                .string(forKey: "tasksFolderPath") ?? ""
            if obsidianVaultName == nil {
                isShowingObsidianSettings = true
                return
            }
            if task.hasNote {
                let taskNoteWithPath = "\(tasksFolderPath)/\(task.obsidianNote ?? "")"
                // TODO: Implement Obsidian note opener
                print("Navigating to note: \(taskNoteWithPath)")
                return
            }
            let taskNote = "task-note: \(task.description.replace(" ", with: "-"))"
            let newTask = TCTask(
                uuid: task.uuid,
                project: task.project,
                description: task.description,
                status: task.status,
                priority: task.priority,
                due: task.due,
                obsidianNote: taskNote
            )
            try DBService.shared.updateTask(newTask)
            task = newTask
            let taskNoteWithPath = "\(tasksFolderPath)/\(task.obsidianNote ?? "")"
            // TODO: Implement Obsidian note opener
            print("Navigating to note: \(taskNoteWithPath)")
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
            let newStatus: TCTask.Status = task.isCompleted ? .pending : task
                .isDeleted ? .pending : .completed
            try DBService.shared.updatePendingTasks(
                [task.uuid],
                withStatus: newStatus
            )
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

        let task = TCTask(
            uuid: task.uuid,
            project: project.isEmpty ? nil : project,
            description: description,
            status: status,
            priority: priority == .none ? nil : priority,
            due: finalDate
        )

        do {
            try DBService.shared.updateTask(task)
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
            try DBService.shared.updatePendingTasks([task.uuid], withStatus: .deleted)
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
