import CoreLocation
import Observation

@MainActor
@Observable
final class LocationService {
    private let manager = CLLocationManager()
    private(set) var status: CLAuthorizationStatus

    init() {
        self.status = manager.authorizationStatus
    }

    /// Returns the device's current coordinate.
    /// Triggers the system permission prompt the first time it's called.
    /// Throws `LocationError.denied` if the user denied permission,
    /// or `LocationError.unavailable` if no location could be determined.
    func currentCoordinate() async throws -> Coordinate {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }

        for try await update in CLLocationUpdate.liveUpdates(.default) {
            status = manager.authorizationStatus

            if update.authorizationDenied || update.authorizationDeniedGlobally {
                throw LocationError.denied
            }

            if let location = update.location {
                return Coordinate(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
            }
        }
        throw LocationError.unavailable
    }

    /// Best-effort reverse geocoding. Returns nil on failure.
    func placeName(for coordinate: Coordinate) async -> String? {
        let location = CLLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        return try? await CLGeocoder()
            .reverseGeocodeLocation(location)
            .first?
            .locality
    }
}

enum LocationError: LocalizedError {
    case denied
    case unavailable

    var errorDescription: String? {
        switch self {
        case .denied:
            "Location access denied. Enable location for Our-Weather in Settings to see local weather."
        case .unavailable:
            "Couldn't determine your location."
        }
    }
}
