import Foundation

public struct Task: Codable, Hashable {
    public enum Status: String, Codable, CaseIterable {
        case pending
        case completed
        case deleted
    }

    public enum Priority: String, Codable, Comparable, CaseIterable {
        public static func < (lhs: Task.Priority, rhs: Task.Priority) -> Bool {
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
    }

    public init(
        uuid: String,
        project: String? = nil,
        description: String,
        status: Status,
        priority: Priority? = nil,
        due: Date? = nil
    ) {
        self.uuid = uuid
        self.project = project
        self.description = description
        self.status = status
        self.priority = priority
        self.due = due
    }

    public let uuid: String
    public var project: String?
    public var description: String
    public var status: Status
    public var priority: Priority?
    public var due: Date?

    public var isCompleted: Bool {
        status == .completed
    }

    public var localDate: String {
        guard let due = due else {
            return ""
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: due)
    }

    public var localDateShort: String {
        guard let due = due else {
            return ""
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        return dateFormatter.string(from: due)
    }
}
