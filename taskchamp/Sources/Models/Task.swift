import Foundation

struct Task: Codable {
    enum Status: String, Codable {
        case pending
        case done
        case deleted
    }

    enum Priority: String, Codable {
        case low = "L"
        case medium = "M"
        case high = "H"
    }

    enum CodingKeys: String, CodingKey {
        case uuid
        case project
        case description
        case status
        case priority
        case due
    }

    init(from decoder: Decoder) throws {
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

    let uuid: String
    let project: String?
    let description: String
    var status: Status
    let priority: Priority?
    let due: Date?

    var isCompleted: Bool {
        status == .done
    }

    var localDate: String {
        guard let due = due else {
            return ""
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: due)
    }
}
