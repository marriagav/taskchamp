import Foundation
import SoulverCore

public class NLPService {
    public static let shared = NLPService()

    private init() {}

    public func createTask(from input: String) throws -> TCTask {
        // swiftlint:disable line_length
        let pattern =
            #"^(?<description>.+?)(?:\s+prio:(?<prio>\S+))?(?:\s+project:(?<project>.+?))?(?:\s+prio:(?<prio2>\S+))?\s*$"#
        // swiftlint:enable line_length

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            throw TCError.genericError("Failed to create regex")
        }

        let nsString = input as NSString
        let results = regex.firstMatch(
            in: input,
            options: [],
            range: NSRange(location: 0, length: nsString.length)
        )

        var description = results.flatMap { result -> String? in
            guard let range = Range(result.range(withName: "description"), in: input) else {
                return nil
            }
            return String(input[range])
        }

        let project = results.flatMap { result -> String? in
            guard let range = Range(result.range(withName: "project"), in: input) else {
                return nil
            }
            return String(input[range])
        }

        let prio = results.flatMap { result -> String? in
            if let range = Range(result.range(withName: "prio"), in: input) {
                return String(input[range]).trimmingCharacters(in: .whitespaces)
            } else if let range = Range(result.range(withName: "prio2"), in: input) {
                return String(input[range]).trimmingCharacters(in: .whitespaces)
            }
            return nil
        }

        var nlpDate: String?
        if let desc = description, let range = desc.range(
            of: #"@[^@]+@"#,
            options: .regularExpression
        ) {
            nlpDate = String(desc[range]).trimmingCharacters(in: CharacterSet(charactersIn: "@"))
            description = desc.replacingCharacters(in: range, with: "")
                .trimmingCharacters(in: .whitespaces)
        }
        let date = nlpDate?.dateValue

        let priority = TCTask.Priority(rawValue: prio ?? "")

        let task = TCTask(
            uuid: UUID().uuidString,
            project: project,
            description: description ?? "",
            status: .pending,
            priority: priority,
            due: date
        )

        return task
    }
}
