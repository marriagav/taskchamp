import Foundation
import SwiftData

@Model
public class TCFilter: Codable {
    public static var defaultFilter: TCFilter {
        let filter = TCFilter(
            fullDescription: "My tasks",
            project: "",
            status: .pending,
            priority: .none,
            due: Date(timeIntervalSince1970: 0)
        )
        filter.didSetStatus = true
        return filter
    }

    public var isDefaultFilter: Bool {
        return fullDescription == Self.defaultFilter.fullDescription &&
            project == Self.defaultFilter.project &&
            status == Self.defaultFilter.status &&
            priority == Self.defaultFilter.priority &&
            due == Self.defaultFilter.due
    }

    public var id = UUID()
    public var fullDescription: String = ""
    public var project: String = ""
    public var status = TCTask.Status.deleted
    public var priority = TCTask.Priority.none
    public var due = Date(timeIntervalSince1970: 0)

    public var didSetPrio: Bool = false
    public var didSetProject: Bool = false
    public var didSetDue: Bool = false
    public var didSetStatus: Bool = false

    public var realDue: Date? {
        return didSetDue ? due : nil
    }

    public var isValidFilter: Bool {
        return didSetPrio || didSetProject || didSetDue || didSetStatus
    }

    public func setPrio(_ prio: TCTask.Priority?) {
        if let prio = prio {
            priority = prio
            didSetPrio = true
        }
    }

    public func setDue(_ date: Date?) {
        if let date = date {
            due = date
            // TODO: figure out a way to implement date filter
            // didSetDue = true
        }
    }

    public func setProject(_ project: String?) {
        if let project = project {
            self.project = project
            didSetProject = true
        }
    }

    public func setStatus(_ status: TCTask.Status?) {
        if let status = status {
            self.status = status
            didSetStatus = true
        }
    }

    init(
        fullDescription: String = "",
        project: String = "",
        status: TCTask.Status = .deleted,
        priority: TCTask.Priority = .none,
        due: Date = Date(timeIntervalSince1970: 0)
    ) {
        self.fullDescription = fullDescription
        self.project = project
        self.status = status
        self.priority = priority
        self.due = due
    }

    enum CodingKeys: CodingKey {
        case id
        case fullDescription
        case project
        case status
        case priority
        case due
        case didSetPrio
        case didSetProject
        case didSetDue
        case didSetStatus
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        fullDescription = try container.decode(String.self, forKey: .fullDescription)
        project = try container.decode(String.self, forKey: .project)
        status = try container.decode(TCTask.Status.self, forKey: .status)
        priority = try container.decode(TCTask.Priority.self, forKey: .priority)
        due = try container.decode(Date.self, forKey: .due)
        didSetPrio = try container.decode(Bool.self, forKey: .didSetPrio)
        didSetProject = try container.decode(Bool.self, forKey: .didSetProject)
        didSetDue = try container.decode(Bool.self, forKey: .didSetDue)
        didSetStatus = try container.decode(Bool.self, forKey: .didSetStatus)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(fullDescription, forKey: .fullDescription)
        try container.encode(project, forKey: .project)
        try container.encode(status, forKey: .status)
        try container.encode(priority, forKey: .priority)
        try container.encode(due, forKey: .due)
        try container.encode(didSetPrio, forKey: .didSetPrio)
        try container.encode(didSetProject, forKey: .didSetProject)
        try container.encode(didSetDue, forKey: .didSetDue)
        try container.encode(didSetStatus, forKey: .didSetStatus)
    }
}
