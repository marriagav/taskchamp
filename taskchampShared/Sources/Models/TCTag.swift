import Foundation
import SwiftData
import Taskchampion

@Model
public class TCTag: Codable, Equatable {
    enum CodingKeys: CodingKey {
        case name
        case includedInFilters
        case excludedFromFilters
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
    }

    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        includedInFilters = try container.decodeIfPresent(
            [TCFilter].self,
            forKey: .includedInFilters
        ) ?? []
        excludedFromFilters = try container.decodeIfPresent(
            [TCFilter].self,
            forKey: .excludedFromFilters
        ) ?? []
    }

    public static func == (lhs: TCTag, rhs: TCTag) -> Bool {
        return lhs.name == rhs.name
    }

    public var name: String = ""

    public var includedInFilters: [TCFilter]?

    public var excludedFromFilters: [TCFilter]?

    @MainActor
    public static func tagFactory(name: String) -> TCTag {
        let existingTag = SwiftDataService.shared.fetchTag(name: name)
        if let existingTag {
            NLPService.shared.appendTagsToCache([existingTag])
            return existingTag
        }
        let tag = TCTag(name: name)
        NLPService.shared.appendTagsToCache([tag])
        return tag
    }

    public init(name: String) {
        self.name = name
        includedInFilters = []
        excludedFromFilters = []
    }

    @Transient private var cachedRustTag: Tag?

    public var rustTag: Tag? {
        if cachedRustTag == nil {
            cachedRustTag = Taskchampion.create_tag(name)
        }
        return cachedRustTag
    }

    public func isSynthetic() -> Bool {
        return rustTag?.is_synthetic() ?? false
    }

    public func isValid() -> Bool {
        return rustTag != nil
    }
}
