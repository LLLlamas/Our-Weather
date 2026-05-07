import Foundation
import Observation

/// Holds the user's saved locations, the current selection, and persists both to `UserDefaults`.
/// The first launch bootstraps with a single Cupertino entry; if location services succeed,
/// `updateCurrentLocation` inserts a Current Location entry at the top and selects it.
@MainActor
@Observable
final class LocationStore {
    var locations: [SavedLocation] = []
    var selectedID: UUID = UUID()  // overwritten in init to match a real location

    private static let storageKey = "savedLocations.v1"
    private static let selectedKey = "savedLocations.selected.v1"

    init() {
        load()
        if locations.isEmpty {
            locations = [
                SavedLocation(
                    name: "Cupertino",
                    coordinate: Coordinate(latitude: 37.32, longitude: -122.03)
                )
            ]
        }
        if !locations.contains(where: { $0.id == selectedID }) {
            selectedID = locations.first!.id
        }
    }

    var selected: SavedLocation? {
        locations.first(where: { $0.id == selectedID })
    }

    @discardableResult
    func add(name: String, coordinate: Coordinate) -> SavedLocation {
        if let existing = locations.first(where: { $0.coordinate == coordinate }) {
            return existing
        }
        let new = SavedLocation(name: name, coordinate: coordinate)
        locations.append(new)
        save()
        return new
    }

    func remove(_ location: SavedLocation) {
        guard !location.isCurrentLocation else { return }
        locations.removeAll { $0.id == location.id }
        if selectedID == location.id {
            selectedID = locations.first?.id ?? UUID()
        }
        save()
    }

    func select(_ id: UUID) {
        guard locations.contains(where: { $0.id == id }) else { return }
        selectedID = id
        save()
    }

    func updateCurrentLocation(coordinate: Coordinate, name: String?) {
        let displayName = name ?? "Current Location"
        if let idx = locations.firstIndex(where: { $0.isCurrentLocation }) {
            locations[idx].coordinate = coordinate
            locations[idx].name = displayName
        } else {
            let current = SavedLocation(
                name: displayName,
                coordinate: coordinate,
                isCurrentLocation: true
            )
            locations.insert(current, at: 0)
            selectedID = current.id
        }
        save()
    }

    private func load() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode([SavedLocation].self, from: data) {
            locations = decoded
        }
        if let idStr = defaults.string(forKey: Self.selectedKey),
           let id = UUID(uuidString: idStr) {
            selectedID = id
        }
    }

    private func save() {
        let defaults = UserDefaults.standard
        if let data = try? JSONEncoder().encode(locations) {
            defaults.set(data, forKey: Self.storageKey)
        }
        defaults.set(selectedID.uuidString, forKey: Self.selectedKey)
    }
}
