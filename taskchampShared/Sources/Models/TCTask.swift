import Foundation

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
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(project, forKey: .project)
        try container.encode(description, forKey: .description)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(priority, forKey: .priority)
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
        noteAnnotationKey: String? = nil
    ) {
        self.uuid = uuid
        self.project = project
        self.description = description
        self.status = status
        self.priority = priority
        self.due = due
        self.obsidianNote = obsidianNote
        self.noteAnnotationKey = noteAnnotationKey
    }

    public let uuid: String
    public var project: String?
    public var description: String
    public var status: Status
    public var priority: Priority?
    public var due: Date?
    public var obsidianNote: String?
    public var noteAnnotationKey: String?

    public var isCompleted: Bool {
        status == .completed
    }

    public var isDeleted: Bool {
        status == .deleted
    }

    public var hasNote: Bool {
        obsidianNote != nil
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
