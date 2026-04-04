import Foundation

/// Resolves a filter entity ID back to the full TCFilter from shared UserDefaults.
public func getFilterFromUserDefaults(id: String) -> TCFilter? {
    guard let filters: [TCFilter] = UserDefaultsManager.shared.getDecodedValue(forKey: .savedFilters) else {
        return nil
    }
    return filters.first { $0.id.uuidString == id }
}

/// Returns all saved filters from shared UserDefaults.
public func getSavedFiltersFromUserDefaults() -> [TCFilter] {
    return UserDefaultsManager.shared.getDecodedValue(forKey: .savedFilters) ?? []
}
