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
        let savedFilters = getSavedFiltersFromUserDefaults()
        results.append(contentsOf: savedFilters.map {
            FilterAppEntity(id: $0.id.uuidString, name: $0.fullDescription)
        }.filter { identifiers.contains($0.id) })
        return results
    }

    func suggestedEntities() async throws -> [FilterAppEntity] {
        var results: [FilterAppEntity] = [.noFilter]
        results.append(contentsOf: getSavedFiltersFromUserDefaults().map {
            FilterAppEntity(id: $0.id.uuidString, name: $0.fullDescription)
        })
        return results
    }
}
