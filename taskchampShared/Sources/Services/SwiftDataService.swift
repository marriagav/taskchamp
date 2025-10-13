import Foundation
import SwiftData

public class SwiftDataService {
    public static let shared = SwiftDataService()

    private init() {}

    public var container: ModelContainer?

    @MainActor
    public func fetchAllTags() -> [TCTag] {
        do {
            guard let container else { return [] }
            let context = container.mainContext
            let descriptor = FetchDescriptor<TCTag>()
            let tags = try context.fetch(descriptor)
            return tags
        } catch {
            return []
        }
    }

    @MainActor
    public func fetchTag(name: String) -> TCTag? {
        do {
            guard let container else { return nil }
            let context = container.mainContext
            let descriptor = FetchDescriptor<TCTag>(
                predicate: #Predicate { $0.name == name }
            )
            let tags = try context.fetch(descriptor)
            return tags.first
        } catch {
            return nil
        }
    }
}
