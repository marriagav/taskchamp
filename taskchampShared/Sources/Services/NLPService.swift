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

    func extractValue(after tag: String, from input: inout String) -> String? {
        if let range = input.range(of: tag) {
            let substring = input[range.upperBound...]
            if let nextTagRange = substring.range(of: "\\s+(prio:|project:|due:)", options: .regularExpression) {
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
