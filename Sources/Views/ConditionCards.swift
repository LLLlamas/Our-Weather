import SwiftUI

struct ConditionCards: View {
    let current: CurrentConditions
    let today: DailyEntry?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            Card(title: "Feels Like", systemImage: "thermometer.medium") {
                TempView(celsius: current.apparentTemperatureC, compact: true)
                    .font(.system(size: 28, weight: .light))
            }

            Card(
                title: "UV Index",
                systemImage: "sun.max.fill",
                subtitle: uvDescription(current.uvIndex)
            ) {
                Text("\(Int(current.uvIndex.rounded()))")
                    .font(.system(size: 28, weight: .light))
            }

            Card(title: "Humidity", systemImage: "humidity.fill") {
                Text("\(current.humidity)%")
                    .font(.system(size: 28, weight: .light))
            }

            Card(
                title: "Wind",
                systemImage: "wind",
                subtitle: windDirection(current.windDirectionDegrees)
            ) {
                Text("\(Int(current.windSpeedKmh.rounded())) km/h")
                    .font(.title2)
            }

            if let today {
                Card(
                    title: "Sunrise",
                    systemImage: "sunrise.fill",
                    subtitle: "Sunset \(today.sunset.formatted(.dateTime.hour().minute()))"
                ) {
                    Text(today.sunrise.formatted(.dateTime.hour().minute()))
                        .font(.title2)
                }
            }
        }
    }

    private func uvDescription(_ uv: Double) -> String {
        switch uv {
        case ..<3: "Low"
        case 3..<6: "Moderate"
        case 6..<8: "High"
        case 8..<11: "Very High"
        default: "Extreme"
        }
    }

    private func windDirection(_ degrees: Int) -> String {
        let dirs = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let i = (Int((Double(degrees) / 45.0).rounded()) % 8 + 8) % 8
        return dirs[i]
    }
}

private struct Card<Value: View>: View {
    let title: String
    let systemImage: String
    let subtitle: String?
    let value: () -> Value

    init(
        title: String,
        systemImage: String,
        subtitle: String? = nil,
        @ViewBuilder value: @escaping () -> Value
    ) {
        self.title = title
        self.systemImage = systemImage
        self.subtitle = subtitle
        self.value = value
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .legibleText()

            value()
                .foregroundStyle(.white)
                .legibleText()

            Spacer(minLength: 0)

            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
                    .legibleText()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .frame(height: 110)
        .background(.white.opacity(0.15))
        .clipShape(.rect(cornerRadius: 16))
    }
}

#Preview {
    let current = CurrentConditions(
        time: .now,
        temperatureC: 14.2,
        apparentTemperatureC: 13.5,
        humidity: 65,
        condition: .partlyCloudy,
        windSpeedKmh: 12.3,
        windDirectionDegrees: 270,
        uvIndex: 4.2,
        isDay: true
    )
    let today = DailyEntry(
        date: .now,
        highC: 18,
        lowC: 9,
        condition: .partlyCloudy,
        sunrise: Calendar.current.date(bySettingHour: 6, minute: 14, second: 0, of: .now)!,
        sunset: Calendar.current.date(bySettingHour: 19, minute: 47, second: 0, of: .now)!,
        precipitationChance: 20
    )
    return ConditionCards(current: current, today: today)
        .padding()
        .background(LinearGradient(colors: [.blue, .indigo], startPoint: .top, endPoint: .bottom))
}
