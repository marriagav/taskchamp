import Foundation
import SoulverCore
import SwiftData

public class NLPService {
    public enum Surface: String {
        case creation
        case filter
        case prio = "prio:"
        case status = "status:"
        case project = "project:"
        case withTag = "+"
        case withoutTag = "-"
    }

    public static let shared = NLPService()

    private init() {}

    public var tagsCache: [TCTag] = []
    public var projectsCache: [String] = []

    // TODO: Add "recur:" to .creation autocomplete when recurring task creation is implemented
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
            "recur",
            "or",
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
            "deleted",
            "recurring"
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

        if lastWord.hasPrefix(Surface.project.rawValue) {
            let prefix = text.dropLast(lastWord.count)
            return prefix + Surface.project.rawValue + suggestion
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
            if isTag($0) || $0 == "or" {
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
        case .project:
            refreshProjectsCache()
            return projectsCache
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

        if lastWord.hasPrefix(Surface.project.rawValue) {
            refreshProjectsCache()
            let query = String(lastWord.dropFirst(Surface.project.rawValue.count))
            return projectSuggestions(matching: query)
        }

        if containsTag(input) {
            var tagToFilter = tagsCache
            if surface != .filter {
                tagToFilter = tagsWithoutSynthetic(tagsCache)
            }
            return tagToFilter.filter {
                let lastWordWithoutSymbol = lastWord.dropFirst()
                return $0.name.contains(lastWordWithoutSymbol)
            }
            .map { $0.name }
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
            let parsedDue = extractValue(after: "due:", from: &remainingString)?.dateValue
            task.due = UserDefaultsManager.standard.applyDefaultDueTimeIfMidnight(to: parsedDue)
        }

        // TODO: Add recur: extraction here when recurring task creation is implemented
        // Creating recurring tasks requires more than just setting the recur property -
        // it needs integration with Taskwarrior's recurrence engine.

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
                task.tags?.append(TCTag.tagFactory(name: tagValue, addToCache: false))
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

        guard let expression = FilterParser.parse(input) else {
            return filter
        }

        setLegacyProperties(on: filter, from: expression)

        return filter
    }

    @MainActor
    private func setLegacyProperties(on filter: TCFilter, from expression: FilterExpression) {
        switch expression {
        case .and(let expressions), .or(let expressions):
            for expr in expressions {
                setLegacyProperties(on: filter, from: expr)
            }
        case .project(let name):
            filter.setProject(name)
        case .priority(let prio):
            filter.setPrio(prio)
        case .status(let status):
            filter.setStatus(status)
        case .tag(let name):
            filter.setTag(name, forInclusion: true)
        case .notTag(let name):
            filter.setTag(name, forInclusion: false)
        case .recur:
            filter.setRecur()
        }
    }

    // TODO: Add recur: to regex patterns when recurring task creation is implemented
    func extractValue(after tag: String, from input: inout String, isFilter: Bool = false) -> String? {
        let regex = isFilter
            ? "\\s+(prio:|project:|due:|status:|recur|\\+|\\-)"
            : "\\s+(prio:|project:|due:|\\+|\\-)"
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

extension NLPService {
    public func appendProjectsToCache(_ projects: [String]) {
        for project in projects where !projectsCache.contains(project) {
            projectsCache.append(project)
        }
    }

    public func setProjectsCache(_ projects: [String]) {
        projectsCache = projects
    }

    @MainActor
    public func refreshProjectsCache() {
        let onlyActive: Bool = UserDefaultsManager.standard.getValue(forKey: .suggestOnlyActiveProjects) ?? true
        let projects = TaskchampionService.shared.getAllProjects(onlyActive: onlyActive)
        setProjectsCache(projects)
    }

    public func projectSuggestions(matching query: String) -> [String] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return projectsCache
        }
        return projectsCache.filter { $0.localizedCaseInsensitiveContains(trimmed) }
    }
}
