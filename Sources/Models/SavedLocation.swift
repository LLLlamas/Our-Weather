import Foundation

/// A user-pinned location, or the device's current location.
/// `isCurrentLocation == true` marks the device-location entry; its coordinate
/// is refreshed via `LocationService` on launch.
struct SavedLocation: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String
    var coordinate: Coordinate
    var isCurrentLocation: Bool

    init(
        id: UUID = UUID(),
        name: String,
        coordinate: Coordinate,
        isCurrentLocation: Bool = false
    ) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
        self.isCurrentLocation = isCurrentLocation
    }
}
