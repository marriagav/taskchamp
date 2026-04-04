import AppIntents
import taskchampShared

struct FilterAppEntity: AppEntity {
    static let noFilterId = "none"

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Filter")
    static var defaultQuery = FilterEntityQuery()

    var id: String
    var name: String

    var isNoFilter: Bool { id == Self.noFilterId }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    static var noFilter: FilterAppEntity {
        FilterAppEntity(id: noFilterId, name: "No filter")
    }
}

struct FilterEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [FilterAppEntity] {
        var results: [FilterAppEntity] = []
        if identifiers.contains(FilterAppEntity.noFilterId) {
            results.append(.noFilter)
        }
        let savedFilters = getSavedFilters()
        results.append(contentsOf: savedFilters.filter { identifiers.contains($0.id) })
        return results
    }

    func suggestedEntities() async throws -> [FilterAppEntity] {
        var results: [FilterAppEntity] = [.noFilter]
        results.append(contentsOf: getSavedFilters())
        return results
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
