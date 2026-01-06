import CoreLocation
import Foundation
import Taskchampion

// swiftlint:disable:next type_body_length
public struct TCTask: Codable, Hashable {
    public enum Status: String, Codable, CaseIterable {
        case pending
        case completed
        case deleted
    }

    public enum Priority: String, Codable, Comparable, CaseIterable {
        public static func < (lhs: TCTask.Priority, rhs: TCTask.Priority) -> Bool {
            switch (lhs, rhs) {
            case (.low, .medium), (.low, .high), (.medium, .high):
                return true
            default:
                return false
            }
        }

        case none = "None"
        case high = "H"
        case medium = "M"
        case low = "L"
    }

    enum CodingKeys: String, CodingKey {
        case uuid
        case project
        case description
        case status
        case priority
        case due
        case tags
        case locationReminder
    }

    // Helper to handle dynamic keys
    private struct DynamicCodingKey: CodingKey {
        var stringValue: String
        var intValue: Int? { nil }

        init?(stringValue: String) {
            self.stringValue = stringValue
        }

        init?(intValue _: Int) {
            return nil
        }
    }

    @MainActor
    public static func taskFactory(from rustTask: TaskRef, withFilter filter: TCFilter) -> TCTask? {
        let prio = rustTask.get_priority().toString()
        if filter.didSetPrio {
            if prio != filter.priority.rawValue {
                return nil
            }
        }

        let project = rustTask.get_project()?.toString() ?? ""
        if filter.didSetProject {
            if project != filter.project {
                return nil
            }
        }

        let statusValue = rustTask.get_status().get_value().toString().lowercased()
        if filter.didSetStatus {
            if statusValue != filter.status.rawValue {
                return nil
            }
        }

        if filter.didSetTags {
            let tagsToInclude = filter.tagsToInclude
            let tagsToExclude = filter.tagsToExclude
            let rustTags = rustTask.get_tags().map { $0.get_value().toString }
            for tag in tagsToInclude ?? [] where !rustTags.contains(where: { $0() == tag.name }) {
                return nil
            }
            for tag in tagsToExclude ?? [] where rustTags.contains(where: { $0() == tag.name }) {
                return nil
            }
        }

        return TCTask(from: rustTask)
    }

    @MainActor
    public init(from rustTask: TaskRef) {
        let uuid = rustTask.get_uuid().to_string().toString()
        let description = rustTask.get_description().toString()
        let status = rustTask.get_status().get_value().toString().lowercased()
        let prio = rustTask.get_priority().toString()
        let due = rustTask.get_due()?.toString()
        let project = rustTask.get_project()?.toString()
        let annotations = rustTask.get_annotations().map { $0.get_description().toString() }
        let tags = rustTask.get_tags().map { TCTag.tagFactory(name: $0.get_value().toString()) }

        // Initialize
        self.uuid = uuid
        self.description = description
        self.status = Status(rawValue: status) ?? .pending
        if !prio.isEmpty, let priority = Priority(rawValue: prio) {
            self.priority = priority
        }
        if let due, let timeInterval = TimeInterval(due) {
            self.due = Date(timeIntervalSince1970: timeInterval)
        }
        self.project = project

        // Look for obsidian note in annotations
        var obsidianNoteValue: String?
        for annotation in annotations where annotation.starts(with: "task-note:") {
            obsidianNoteValue = annotation.replacingOccurrences(of: "task-note: ", with: "")
            break
        }
        obsidianNote = obsidianNoteValue

        self.tags = tags.isEmpty ? nil : tags

        // Location reminder data stored in annotations
        var locationReminderValue: TCLocationReminder?
        for annotation in annotations where annotation.starts(with: "location-reminder:") {
            let jsonString = annotation.replacingOccurrences(of: "location-reminder: ", with: "")
            if let data = jsonString.data(using: .utf8),
                let reminder = try? JSONDecoder().decode(TCLocationReminder.self, from: data) {
                locationReminderValue = reminder
                break
            }
        }
        locationReminder = locationReminderValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uuid = try container.decode(String.self, forKey: .uuid)
        project = try container.decodeIfPresent(String.self, forKey: .project)
        description = try container.decode(String.self, forKey: .description)
        status = try container.decode(Status.self, forKey: .status)
        priority = try container.decodeIfPresent(Priority.self, forKey: .priority)
        let dueTimeInterval = try container.decodeIfPresent(String.self, forKey: .due)
        if let dueTimeInterval, let timeInterval = TimeInterval(dueTimeInterval) {
            due = Date(timeIntervalSince1970: timeInterval)
        } else {
            due = nil
        }
        tags = try container.decodeIfPresent([TCTag].self, forKey: .tags)
        // Decode dynamic keys for annotations
        let dynamicContainer = try decoder.container(keyedBy: DynamicCodingKey.self)
        var obsidianNoteValue: String?
        var noteAnnotationKey: String?

        for key in dynamicContainer.allKeys where key.stringValue.starts(with: "annotation_") {
            let annotationValue = try dynamicContainer.decode(String.self, forKey: key)
            if annotationValue.starts(with: "task-note:") {
                noteAnnotationKey = key.stringValue
                obsidianNoteValue = annotationValue.replacingOccurrences(of: "task-note: ", with: "")
                break
            }
        }
        obsidianNote = obsidianNoteValue
        self.noteAnnotationKey = noteAnnotationKey
        locationReminder = try container.decodeIfPresent(TCLocationReminder.self, forKey: .locationReminder)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(project, forKey: .project)
        try container.encode(description, forKey: .description)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(priority, forKey: .priority)
        try container.encode(tags, forKey: .tags)
        try container.encodeIfPresent(locationReminder, forKey: .locationReminder)
        if let due = due {
            let timeInterval = due.timeIntervalSince1970.rounded()
            try container.encode(String(timeInterval), forKey: .due)
        }
        // Encode dynamic annotation keys
        var dynamicContainer = encoder.container(keyedBy: DynamicCodingKey.self)

        // Add the obsidianNote as a dynamic annotation
        if let obsidianNoteValue = obsidianNote {
            if let existingKey = noteAnnotationKey {
                if let dynamicKey = DynamicCodingKey(stringValue: existingKey) {
                    try dynamicContainer.encode(
                        "task-note: \(obsidianNoteValue)",
                        forKey: dynamicKey
                    )
                }
            }
            let modifiedDate = String(Int(Date().timeIntervalSince1970.rounded()))
            let dynamicKey = DynamicCodingKey(stringValue: "annotation_\(modifiedDate))")
            if let dynamicKey = dynamicKey {
                try dynamicContainer.encode("task-note: \(obsidianNoteValue)", forKey: dynamicKey)
            }
        }
    }

    public init(
        uuid: String,
        project: String? = nil,
        description: String,
        status: Status,
        priority: Priority? = nil,
        due: Date? = nil,
        obsidianNote: String? = nil,
        noteAnnotationKey: String? = nil,
        tags: [TCTag]? = nil,
        locationReminder: TCLocationReminder? = nil
    ) {
        self.uuid = uuid
        self.project = project
        self.description = description
        self.status = status
        self.priority = priority
        self.due = due
        self.obsidianNote = obsidianNote
        self.noteAnnotationKey = noteAnnotationKey
        self.tags = tags
        self.locationReminder = locationReminder
        if let tags {
            NLPService.shared.appendTagsToCache(tags)
        }
    }

    public let uuid: String
    public var project: String?
    public var description: String
    public var status: Status
    public var priority: Priority?
    public var due: Date?
    public var obsidianNote: String?
    public var noteAnnotationKey: String?
    public var tags: [TCTag]?
    public var locationReminder: TCLocationReminder?

    public var obsidianNoteAnnotation: String? {
        guard let note = obsidianNote else {
            return nil
        }
        return "task-note: \(note)"
    }

    public var rustAnnotationFromObsidianNote: Annotation? {
        guard let note = obsidianNoteAnnotation else {
            return nil
        }

        let annotation = Taskchampion.create_annotation(
            note,
            String(Int(Date().timeIntervalSince1970.rounded()))
        )
        return annotation
    }

    public var locationReminderAnnotation: String? {
        guard let reminder = locationReminder else {
            return nil
        }
        guard let jsonData = try? JSONEncoder().encode(reminder),
            let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }
        return "location-reminder: \(jsonString)"
    }

    public var rustAnnotationFromLocationReminder: Annotation? {
        guard let annotationString = locationReminderAnnotation else {
            return nil
        }

        let annotation = Taskchampion.create_annotation(
            annotationString,
            String(Int(Date().timeIntervalSince1970.rounded()))
        )
        return annotation
    }

    public var rustTags: [Tag?]? {
        guard let tags, !tags.isEmpty else {
            return nil
        }
        return tags.compactMap { tag in
            if tag.isSynthetic() {
                return nil
            }
            let rustTag = tag.rustTag
            if rustTag?.is_synthetic() ?? false {
                return nil
            }
            return rustTag
        }
    }

    public var rustVecOfTags: RustVec<Tag>? {
        guard let rustTags else {
            return nil
        }
        let rustVec = RustVec<Tag>()
        for tag in rustTags {
            if let tag = tag {
                rustVec.push(value: tag)
            }
        }
        return rustVec
    }

    public var isCompleted: Bool {
        status == .completed
    }

    public var isDeleted: Bool {
        status == .deleted
    }

    public var hasNote: Bool {
        obsidianNote != nil
    }

    public var hasLocationReminder: Bool {
        locationReminder != nil
    }

    public var localDate: String {
        guard let due = due else {
            return ""
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.doesRelativeDateFormatting = true
        return dateFormatter.string(from: due)
    }

    public var localDateShort: String {
        guard let due = due else {
            return ""
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.doesRelativeDateFormatting = true
        return dateFormatter.string(from: due)
    }

    public var url: URL {
        guard let url = URL(string: "taskchamp://task/\(uuid)") else {
            fatalError("Failed to construct url.")
        }

        return url
    }

    public static var newTaskUrl: URL {
        guard let url = URL(string: "taskchamp://task/new") else {
            fatalError("Failed to construct url.")
        }

        return url
    }
}
