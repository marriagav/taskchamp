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
            let prio = extractToken(after: "prio:", from: &remainingString)
            task.priority = TCTask.Priority(rawValue: prio ?? "")
        }

        // Check for and extract project
        if remainingString.range(of: "project:") != nil {
            task.project = extractToken(after: "project:", from: &remainingString)
        }

        // Check for and extract due
        if remainingString.range(of: "due:") != nil {
            let parsedDue = extractDue(from: &remainingString)
            task.due = UserDefaultsManager.standard.applyDefaultDueTimeIfMidnight(to: parsedDue)
        }

        // TODO: Add recur: extraction here when recurring task creation is implemented
        // Creating recurring tasks requires more than just setting the recur property -
        // it needs integration with Taskwarrior's recurrence engine.

        // Check for and extract tags
        while remainingString.range(of: "+") != nil {
            let tagValue = extractToken(after: "+", from: &remainingString)
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

        // The remaining string is the description. Collapse the gaps left behind by removed keywords.
        task.description = remainingString
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")

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

    /// Extracts the single word directly after `tag` (e.g. `+chore`, `project:home`, `prio:H`) and removes
    /// both from `input`. Anything after that word stays in place, so it can still become the description.
    func extractToken(after tag: String, from input: inout String) -> String? {
        guard let range = input.range(of: tag) else { return nil }
        let rest = input[range.upperBound...]
        let end = rest.firstIndex(where: \.isWhitespace) ?? rest.endIndex
        let value = String(rest[..<end])
        input.removeSubrange(range.lowerBound..<end)
        return value
    }

    // TODO: Add recur: to the boundary regex when recurring task creation is implemented
    /// Extracts the date after `due:` and removes it from `input`.
    ///
    /// Due dates can span several words ("tomorrow at 1pm"), but text after the date may be the task
    /// description ("due:today Buy milk"). SoulverCore ignores trailing words that aren't part of a date,
    /// so the date phrase is the shortest run of words that parses to the same date as the whole segment.
    /// The remaining words are left in `input`.
    func extractDue(from input: inout String) -> Date? {
        guard let range = input.range(of: "due:") else { return nil }
        let rest = input[range.upperBound...]
        let boundary = rest.range(of: "\\s+(prio:|project:|due:|\\+|\\-)", options: .regularExpression)?
            .lowerBound ?? rest.endIndex
        let segment = rest[..<boundary]

        // End index of each word in the segment, so a prefix of N words is segment[..<wordEnds[N - 1]].
        var wordEnds: [String.Index] = []
        var index = segment.startIndex
        while index < segment.endIndex {
            while index < segment.endIndex, segment[index].isWhitespace {
                index = segment.index(after: index)
            }
            guard index < segment.endIndex else { break }
            while index < segment.endIndex, !segment[index].isWhitespace {
                index = segment.index(after: index)
            }
            wordEnds.append(index)
        }

        guard let firstWordEnd = wordEnds.first else {
            input.removeSubrange(range)
            return nil
        }

        let candidates = wordEnds.map { (end: $0, date: String(segment[..<$0]).dateValue) }
        // Prefer the date of the whole segment. If trailing words break parsing entirely
        // ("today 3 apples"), fall back to the longest prefix that still parses.
        guard let target = candidates.last?.date ?? candidates.last(where: { $0.date != nil })?.date else {
            // Nothing parses: drop only the first word so the rest can still become the description.
            input.removeSubrange(range.lowerBound..<firstWordEnd)
            return nil
        }
        // Relative dates ("in 2 hours") are computed from the current time, so compare with a tolerance.
        let chosenEnd = candidates.first {
            guard let date = $0.date else { return false }
            return abs(date.timeIntervalSince(target)) < 1
        }?.end ?? firstWordEnd

        input.removeSubrange(range.lowerBound..<chosenEnd)
        return target
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
