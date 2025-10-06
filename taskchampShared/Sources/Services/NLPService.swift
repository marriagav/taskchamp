import Foundation
import SoulverCore
import SwiftData

public class NLPService {
    public enum Surface: String {
        case creation
        case filter
        case prio = "prio:"
        case status = "status:"
        case withTag = "+"
        case withoutTag = "-"
    }

    public static let shared = NLPService()

    private init() {}

    public var tagsCache: [TCTag] = []

    private var autoCompleteSources: [Surface: [String]] = [
        .creation: [
            "prio:",
            "project:",
            "due:",
            "+"
        ],
        .filter: [
            "prio:",
            "project:",
            "status:",
            "+",
            "-"
        ],
        .prio: [
            "H",
            "M",
            "L"
        ],
        .status: [
            "pending",
            "completed",
            "deleted"
        ]
    ]

    public func getAutoCompletedString(for text: String, suggestion: String) -> String {
        let endsWithSpace = text.hasSuffix(" ")
        if endsWithSpace {
            return text + suggestion
        }
        let lastWord = text.split(separator: " ").last ?? ""

        if let surface = Surface(rawValue: String(lastWord)) {
            _ = surface
            return text + suggestion
        }

        if containsTag(text) && !isTag(suggestion) {
            let firstChar = lastWord.first.map { String($0) } ?? ""
            if firstChar == "+" || firstChar == "-" {
                let prefix = text.dropLast(lastWord.count)
                let first = prefix + firstChar + suggestion
                return first + " "
            }
        }

        let prefix = text.dropLast(lastWord.count)
        return prefix + suggestion
    }

    private func isTag(_ source: String) -> Bool {
        return source == "+" || source == "-"
    }

    private func containsTag(_ input: String) -> Bool {
        return input.contains("+") || input.contains("-")
    }

    private func autoCompleteSourcesNotAlreadyInInput(_ input: String, surface: Surface) -> [String] {
        return (autoCompleteSources[surface] ?? []).filter {
            if isTag($0) {
                return true
            }
            return !input.contains($0)
        }
    }

    private func tagsWithoutSynthetic(_ tags: [TCTag]) -> [TCTag] {
        return tags.filter { tag in
            if !tag.isValid() {
                return false
            }
            return !tag.isSynthetic()
        }
    }

    public func appendTagsToCache(_ tags: [TCTag]) {
        for tag in tags where
            !tagsCache.contains(where: { $0.name == tag.name })
        // swiftlint:disable:next opening_brace
        {
            tagsCache.append(tag)
        }
    }

    @MainActor
    private func autoCompleteForKeywords(lastWord: Surface, originalSurface: Surface) -> [String] {
        switch lastWord {
        case .prio:
            return autoCompleteSources[.prio] ?? []
        case .status:
            return autoCompleteSources[.status] ?? []
        case .withTag, .withoutTag:
            let newTags = SwiftDataService.shared.fetchAllTags()
            appendTagsToCache(newTags)
            if originalSurface != .filter {
                return tagsWithoutSynthetic(tagsCache).map { $0.name }
            }
            return tagsCache.filter { $0.isValid() }.map { $0.name }
        default:
            return []
        }
    }

    @MainActor
    public func autoCompleteSuggestions(for input: String, surface: Surface) -> [String] {
        if input.isEmpty, surface != .creation {
            return autoCompleteSources[surface] ?? []
        }
        let endsWithSpace = input.hasSuffix(" ")

        if endsWithSpace {
            return autoCompleteSourcesNotAlreadyInInput(input, surface: surface)
        }

        let lastWord = input.split(separator: " ").last ?? ""

        if let newSurface = Surface(rawValue: String(lastWord)) {
            return autoCompleteForKeywords(lastWord: newSurface, originalSurface: surface)
        }

        if containsTag(input) {
            var tagToFilter = tagsCache
            if surface != .filter {
                tagToFilter = tagsWithoutSynthetic(tagsCache)
            }
            let tagNames = tagToFilter.filter {
                let lastWordWithoutSymbol = lastWord.dropFirst()
                return $0.name.contains(lastWordWithoutSymbol)
            }
            .map { $0.name }
            return tagNames
        }

        let trimmedInput = lastWord.trimmingCharacters(in: .whitespaces)
        guard !trimmedInput.isEmpty else { return [] }

        var suggestions: [String] = []

        for source in autoCompleteSourcesNotAlreadyInInput(input, surface: surface) {
            if source.hasPrefix(trimmedInput), source != trimmedInput {
                suggestions.append(source)
            }
        }

        return suggestions
    }

    @MainActor
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

        // Check for and extract tags
        while remainingString.range(of: "+") != nil {
            let tagValue = extractValue(after: "+", from: &remainingString)
            if let tagValue, !tagValue.isEmpty {
                if task.tags == nil {
                    task.tags = []
                }
                if task.tags?.contains(where: { $0.name == tagValue }) ?? false {
                    continue
                }
                task.tags?.append(TCTag.tagFactory(name: tagValue))
            }
        }

        // The remaining string is the description
        task.description = remainingString.trimmingCharacters(in: .whitespaces)

        return task
    }

    @MainActor
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
        }

        // Check for and extract tags
        while remainingString.range(of: "+") != nil {
            let tagValue = extractValue(after: "+", from: &remainingString)
            if let tagValue, !tagValue.isEmpty {
                filter.setTag(tagValue, forInclusion: true)
            }
        }

        // Check for and extract negative tags
        while remainingString.range(of: "-") != nil {
            let tagValue = extractValue(after: "-", from: &remainingString)
            if let tagValue, !tagValue.isEmpty {
                filter.setTag(tagValue, forInclusion: false)
            }
        }

        return filter
    }

    func extractValue(after tag: String, from input: inout String, isFilter: Bool = false) -> String? {
        let regex = isFilter ? "\\s+(prio:|project:|due:|status:|\\+|\\-)" : "\\s+(prio:|project:|due:|\\+|\\-)"
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
