import Foundation
import SwiftData
import SwiftUI
import taskchampShared
import WidgetKit

extension AddFilterView {
    var favoriteFilters: [TCFilter] {
        filters.filter { $0.isFavorite }
    }

    var regularFilters: [TCFilter] {
        filters.filter { !$0.isFavorite }
    }

    @ViewBuilder
    func filterRow(_ filter: TCFilter) -> some View {
        Button {
            selectFilter(filter)
        } label: {
            filterRowLabel(filter)
        }
        .contextMenu { filterRowContextMenu(filter) }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            filterRowFavoriteAction(filter)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            filterRowDeleteAction(filter)
        }
    }

    @ViewBuilder
    func filterRowLabel(_ filter: TCFilter) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if let name = filter.name, !name.isEmpty {
                Text(name)
                    .font(.body)
            }
            HStack {
                Text(filter.fullDescription)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(
                        (filter.name?.isEmpty == false)
                            ? .secondary : .primary
                    )
                if selectedFilter.id == filter.id {
                    Spacer()
                    Image(systemName: SFSymbols.checkmark.rawValue)
                }
            }
        }
    }

    @ViewBuilder
    func filterRowContextMenu(_ filter: TCFilter) -> some View {
        Button {
            toggleFavorite(filter)
        } label: {
            Label(
                filter.isFavorite ? "Unfavorite" : "Favorite",
                systemImage: filter.isFavorite ? SFSymbols.starSlash.rawValue : SFSymbols.star.rawValue
            )
        }
        Button {
            editName = filter.name ?? ""
            editQuery = filter.fullDescription
            editingFilter = filter
        } label: {
            Label("Edit", systemImage: "pencil")
        }
        Button(role: .destructive) {
            deleteFilter(filter)
        } label: {
            Label("Delete", systemImage: SFSymbols.trash.rawValue)
        }
    }

    @ViewBuilder
    func filterRowFavoriteAction(_ filter: TCFilter) -> some View {
        Button {
            toggleFavorite(filter)
        } label: {
            Label(
                filter.isFavorite ? "Unfavorite" : "Favorite",
                systemImage: filter.isFavorite ? SFSymbols.starSlash.rawValue : SFSymbols.starFill.rawValue
            )
        }
        .tint(.yellow)
    }

    @ViewBuilder
    func filterRowDeleteAction(_ filter: TCFilter) -> some View {
        Button(role: .destructive) {
            deleteFilter(filter)
        } label: {
            Label("Delete", systemImage: SFSymbols.trash.rawValue)
        }
    }

    func selectFilter(_ filter: TCFilter) {
        if !storeKit.hasPremiumAccess() {
            showPaywall = true
            return
        }
        if filter == selectedFilter {
            selectedFilter = TCFilter.defaultFilter
        } else {
            selectedFilter = filter
        }
        setSelectedFilterUserDefault(selectedFilter: selectedFilter)
        dismiss()
    }

    func deleteFilter(_ filter: TCFilter) {
        withAnimation {
            modelContext.delete(filter)
            if filter == selectedFilter {
                selectedFilter = TCFilter.defaultFilter
                setSelectedFilterUserDefault(selectedFilter: selectedFilter)
            }
        }
    }

    func toggleFavorite(_ filter: TCFilter) {
        withAnimation {
            filter.isFavorite.toggle()
            syncFiltersToSharedUserDefaults()
        }
    }

    func moveFavoriteFilters(from source: IndexSet, to destination: Int) {
        var newFavorites = favoriteFilters
        newFavorites.move(fromOffsets: source, toOffset: destination)
        reassignOrder(favorites: newFavorites, regular: regularFilters)
    }

    func moveRegularFilters(from source: IndexSet, to destination: Int) {
        var newRegular = regularFilters
        newRegular.move(fromOffsets: source, toOffset: destination)
        reassignOrder(favorites: favoriteFilters, regular: newRegular)
    }

    func reassignOrder(favorites: [TCFilter], regular: [TCFilter]) {
        for (index, filter) in (favorites + regular).enumerated() {
            filter.order = index
        }
        syncFiltersToSharedUserDefaults()
    }

    func setSelectedFilterUserDefault(selectedFilter: TCFilter) {
        do {
            try UserDefaultsManager.standard.setEncodableValue(selectedFilter, forKey: .selectedFilter)
        } catch { print(error) }
    }

    func syncFiltersToSharedUserDefaults() {
        do {
            try UserDefaultsManager.shared.setEncodableValue(filters, forKey: .savedFilters)
            WidgetCenter.shared.reloadAllTimelines()
        } catch { print(error) }
    }
}
