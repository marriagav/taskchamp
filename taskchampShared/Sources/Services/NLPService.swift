import Foundation
import SoulverCore

public class NLPService {
    public static let shared = NLPService()

    private init() {}

    public func createTask(from input: String) -> TCTask {
        var task = TCTask(
            uuid: UUID().uuidString,
            project: nil,
            description: "",
            status: .pending,
            priority: nil,
            due: nil
        )
        var remainingString = input

        // Check for and extract prio
        if remainingString.range(of: "prio:") != nil {
            let prio = extractValue(after: "prio:", from: &remainingString)
            task.priority = TCTask.Priority(rawValue: prio ?? "")
        }

        // Check for and extract project
        if remainingString.range(of: "project:") != nil {
            task.project = extractValue(after: "project:", from: &remainingString)
        }

        // Check for and extract due
        if remainingString.range(of: "due:") != nil {
            task.due = extractValue(after: "due:", from: &remainingString)?.dateValue
        }

        // The remaining string is the description
        task.description = remainingString.trimmingCharacters(in: .whitespaces)

        return task
    }

    public func createFilter(from input: String) -> TCFilter {
        let filter = TCFilter(
            fullDescription: input
        )
        var remainingString = input

        // Check for and extract prio
        if remainingString.range(of: "prio:") != nil {
            let prio = extractValue(after: "prio:", from: &remainingString, isFilter: true)
            filter.setPrio(TCTask.Priority(rawValue: prio ?? ""))
        }

        // Check for and extract project
        if remainingString.range(of: "project:") != nil {
            filter.setProject(extractValue(after: "project:", from: &remainingString, isFilter: true))
        }

        // Check for and extract due
        if remainingString.range(of: "due:") != nil {
            filter.setDue(extractValue(after: "due:", from: &remainingString, isFilter: true)?.dateValue)
        }

        // Check for and extract status
        if remainingString.range(of: "status:") != nil {
            let status = extractValue(after: "status:", from: &remainingString, isFilter: true)
            filter.setStatus(TCTask.Status(rawValue: status ?? "pending"))
        } else {
            filter.setStatus(.pending)
        }

        return filter
    }

    func extractValue(after tag: String, from input: inout String, isFilter: Bool = false) -> String? {
        let regex = isFilter ? "\\s+(prio:|project:|due:|status:)" : "\\s+(prio:|project:|due:)"
        if let range = input.range(of: tag) {
            let substring = input[range.upperBound...]
            if let nextTagRange = substring.range(
                of: regex,
                options: .regularExpression
            ) {
                let value = String(substring[..<nextTagRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                input = String(input[..<range.lowerBound] + substring[nextTagRange.lowerBound...])
                return value
            } else {
                let value = String(substring).trimmingCharacters(in: .whitespaces)
                input = String(input[..<range.lowerBound])
                return value
            }
        }
        return nil
    }
}
