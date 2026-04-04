import AppIntents
import taskchampShared

struct OpenFilterIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Filter"
    static var description: IntentDescription = "Opens Taskchamp with a specific filter applied."
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Filter")
    var filter: FilterAppEntity

    func perform() async throws -> some IntentResult {
        if filter.isNoFilter {
            try? UserDefaultsManager.standard.setEncodableValue(
                TCFilter.defaultFilter, forKey: .selectedFilter
            )
        } else if let tcFilter = getFilterFromUserDefaults(id: filter.id) {
            try? UserDefaultsManager.standard.setEncodableValue(
                tcFilter, forKey: .selectedFilter
            )
        }
        return .result()
    }
}
