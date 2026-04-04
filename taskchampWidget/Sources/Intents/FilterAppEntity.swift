import AppIntents
import taskchampShared

struct FilterAppEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Filter")
    static var defaultQuery = FilterEntityQuery()

    var id: String
    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct FilterEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [FilterAppEntity] {
        let allFilters = getSavedFilters()
        return allFilters.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [FilterAppEntity] {
        return getSavedFilters()
    }

    private func getSavedFilters() -> [FilterAppEntity] {
        guard let filters: [TCFilter] = UserDefaultsManager.shared.getDecodedValue(forKey: .savedFilters) else {
            return []
        }
        return filters.map { FilterAppEntity(id: $0.id.uuidString, name: $0.fullDescription) }
    }
}

/// Resolves a FilterAppEntity back to the full TCFilter from shared UserDefaults.
func getFilterFromUserDefaults(id: String) -> TCFilter? {
    guard let filters: [TCFilter] = UserDefaultsManager.shared.getDecodedValue(forKey: .savedFilters) else {
        return nil
    }
    return filters.first { $0.id.uuidString == id }
}
