import Foundation

protocol WeatherClient: Sendable {
    func forecast(for coordinate: Coordinate) async throws -> Forecast
}

struct OpenMeteoClient: WeatherClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func forecast(for coordinate: Coordinate) async throws -> Forecast {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            .init(name: "latitude", value: String(coordinate.latitude)),
            .init(name: "longitude", value: String(coordinate.longitude)),
            .init(name: "current", value: "temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,is_day,wind_speed_10m,wind_direction_10m,uv_index"),
            .init(name: "hourly", value: "temperature_2m,precipitation_probability,weather_code"),
            .init(name: "daily", value: "weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,precipitation_probability_max"),
            .init(name: "temperature_unit", value: "celsius"),
            .init(name: "wind_speed_unit", value: "kmh"),
            .init(name: "timezone", value: "auto"),
            .init(name: "forecast_days", value: "10"),
        ]
        guard let url = components.url else { throw URLError(.badURL) }

        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }

        let raw = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        return raw.toForecast()
    }
}

// MARK: - Wire format (Open-Meteo's parallel-array shape)

private struct OpenMeteoResponse: Decodable {
    let latitude: Double
    let longitude: Double
    let timezone: String
    let current: Current
    let hourly: Hourly
    let daily: Daily

    struct Current: Decodable {
        let time: String
        let temperature_2m: Double
        let apparent_temperature: Double
        let relative_humidity_2m: Int
        let weather_code: Int
        let is_day: Int
        let wind_speed_10m: Double
        let wind_direction_10m: Int
        let uv_index: Double
    }

    struct Hourly: Decodable {
        let time: [String]
        let temperature_2m: [Double]
        let precipitation_probability: [Int?]
        let weather_code: [Int]
    }

    struct Daily: Decodable {
        let time: [String]
        let weather_code: [Int]
        let temperature_2m_max: [Double]
        let temperature_2m_min: [Double]
        let sunrise: [String]
        let sunset: [String]
        let precipitation_probability_max: [Int?]
    }

    func toForecast() -> Forecast {
        let formatter = DateFormatter.openMeteoLocal(timezone: timezone)

        let currentConditions = CurrentConditions(
            time: formatter.date(from: current.time) ?? .now,
            temperatureC: current.temperature_2m,
            apparentTemperatureC: current.apparent_temperature,
            humidity: current.relative_humidity_2m,
            condition: WeatherCondition(wmoCode: current.weather_code),
            windSpeedKmh: current.wind_speed_10m,
            windDirectionDegrees: current.wind_direction_10m,
            uvIndex: current.uv_index,
            isDay: current.is_day == 1
        )

        let hourlyEntries: [HourlyEntry] = zip4(hourly.time, hourly.temperature_2m, hourly.weather_code, hourly.precipitation_probability)
            .compactMap { time, temp, code, precip in
                guard let date = formatter.date(from: time) else { return nil }
                return HourlyEntry(
                    time: date,
                    temperatureC: temp,
                    condition: WeatherCondition(wmoCode: code),
                    precipitationChance: precip
                )
            }

        let dailyEntries: [DailyEntry] = (0..<daily.time.count).compactMap { i in
            guard let date = formatter.date(from: daily.time[i]),
                  let sunrise = formatter.date(from: daily.sunrise[i]),
                  let sunset = formatter.date(from: daily.sunset[i]) else { return nil }
            return DailyEntry(
                date: date,
                highC: daily.temperature_2m_max[i],
                lowC: daily.temperature_2m_min[i],
                condition: WeatherCondition(wmoCode: daily.weather_code[i]),
                sunrise: sunrise,
                sunset: sunset,
                precipitationChance: daily.precipitation_probability_max[i]
            )
        }

        return Forecast(
            coordinate: Coordinate(latitude: latitude, longitude: longitude),
            timezone: timezone,
            current: currentConditions,
            hourly: hourlyEntries,
            daily: dailyEntries
        )
    }
}

private extension DateFormatter {
    /// Open-Meteo returns naive ISO strings (`yyyy-MM-dd'T'HH:mm`) interpreted in the response's timezone.
    static func openMeteoLocal(timezone: String) -> DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd'T'HH:mm"
        f.timeZone = TimeZone(identifier: timezone) ?? .gmt
        return f
    }
}

private func zip4<A, B, C, D>(_ a: [A], _ b: [B], _ c: [C], _ d: [D]) -> [(A, B, C, D)] {
    let n = min(a.count, b.count, c.count, d.count)
    return (0..<n).map { (a[$0], b[$0], c[$0], d[$0]) }
}
