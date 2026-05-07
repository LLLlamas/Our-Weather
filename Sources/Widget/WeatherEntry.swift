import WidgetKit

struct WeatherEntry: TimelineEntry {
    let date: Date
    let temperatureC: Double?
    let condition: WeatherCondition
    let isDay: Bool
    let locationName: String
    let highC: Double?
    let lowC: Double?
    let isError: Bool

    static let placeholder = WeatherEntry(
        date: .now,
        temperatureC: 14,
        condition: .partlyCloudy,
        isDay: true,
        locationName: "Cupertino",
        highC: 18,
        lowC: 9,
        isError: false
    )
}
