import Foundation

struct Coordinate: Sendable, Equatable {
    let latitude: Double
    let longitude: Double
}

struct Forecast: Sendable {
    let coordinate: Coordinate
    let timezone: String
    let current: CurrentConditions
    let hourly: [HourlyEntry]
    let daily: [DailyEntry]
}

struct CurrentConditions: Sendable {
    let time: Date
    let temperatureC: Double
    let apparentTemperatureC: Double
    let humidity: Int
    let condition: WeatherCondition
    let windSpeedKmh: Double
    let windDirectionDegrees: Int
    let uvIndex: Double
    let isDay: Bool
}

struct HourlyEntry: Sendable, Identifiable {
    var id: Date { time }
    let time: Date
    let temperatureC: Double
    let condition: WeatherCondition
    let precipitationChance: Int?
}

struct DailyEntry: Sendable, Identifiable {
    var id: Date { date }
    let date: Date
    let highC: Double
    let lowC: Double
    let condition: WeatherCondition
    let sunrise: Date
    let sunset: Date
    let precipitationChance: Int?
}

enum WeatherCondition: Sendable, CaseIterable {
    case clear
    case partlyCloudy
    case overcast
    case fog
    case drizzle
    case rain
    case snow
    case thunderstorm

    /// WMO weather interpretation codes used by Open-Meteo.
    /// Reference: https://open-meteo.com/en/docs (Weather Variable Documentation)
    init(wmoCode: Int) {
        switch wmoCode {
        case 0: self = .clear
        case 1, 2: self = .partlyCloudy
        case 3: self = .overcast
        case 45, 48: self = .fog
        case 51, 53, 55, 56, 57: self = .drizzle
        case 61, 63, 65, 66, 67, 80, 81, 82: self = .rain
        case 71, 73, 75, 77, 85, 86: self = .snow
        case 95, 96, 99: self = .thunderstorm
        default: self = .clear
        }
    }

    var displayName: String {
        switch self {
        case .clear: "Clear"
        case .partlyCloudy: "Partly Cloudy"
        case .overcast: "Overcast"
        case .fog: "Fog"
        case .drizzle: "Drizzle"
        case .rain: "Rain"
        case .snow: "Snow"
        case .thunderstorm: "Thunderstorm"
        }
    }

    var sfSymbol: String {
        switch self {
        case .clear: "sun.max.fill"
        case .partlyCloudy: "cloud.sun.fill"
        case .overcast: "cloud.fill"
        case .fog: "cloud.fog.fill"
        case .drizzle: "cloud.drizzle.fill"
        case .rain: "cloud.rain.fill"
        case .snow: "cloud.snow.fill"
        case .thunderstorm: "cloud.bolt.rain.fill"
        }
    }
}
