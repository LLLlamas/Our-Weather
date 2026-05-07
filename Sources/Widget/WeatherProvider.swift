import WidgetKit
import CoreLocation

/// Timeline provider for the weather widget. Each entry refreshes after 30 minutes.
/// Uses the system's cached location (populated by the main app's foreground use)
/// and falls back to Cupertino if no cache exists.
struct WeatherProvider: TimelineProvider {
    private let client: any WeatherClient = OpenMeteoClient()

    func placeholder(in context: Context) -> WeatherEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (WeatherEntry) -> Void) {
        Task {
            let entry = await fetchEntry()
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeatherEntry>) -> Void) {
        Task {
            let entry = await fetchEntry()
            let nextUpdate = Date.now.addingTimeInterval(30 * 60)
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }

    private func fetchEntry() async -> WeatherEntry {
        let (coord, name) = currentLocation()
        do {
            let forecast = try await client.forecast(for: coord)
            return WeatherEntry(
                date: .now,
                temperatureC: forecast.current.temperatureC,
                condition: forecast.current.condition,
                isDay: forecast.current.isDay,
                locationName: name,
                highC: forecast.daily.first?.highC,
                lowC: forecast.daily.first?.lowC,
                isError: false
            )
        } catch {
            return WeatherEntry(
                date: .now,
                temperatureC: nil,
                condition: .clear,
                isDay: true,
                locationName: name,
                highC: nil,
                lowC: nil,
                isError: true
            )
        }
    }

    /// Reads the system's cached location. The main app's foreground location use
    /// keeps this fresh; if the cache is empty (first launch before any main-app fetch),
    /// returns Cupertino as a sensible default.
    private func currentLocation() -> (Coordinate, String) {
        let manager = CLLocationManager()
        if let loc = manager.location {
            return (
                Coordinate(
                    latitude: loc.coordinate.latitude,
                    longitude: loc.coordinate.longitude
                ),
                "Current Location"
            )
        }
        return (Coordinate(latitude: 37.32, longitude: -122.03), "Cupertino")
    }
}
