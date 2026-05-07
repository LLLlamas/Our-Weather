import SwiftUI

struct DailyList: View {
    let days: [DailyEntry]
    var currentTempC: Double? = nil

    private var weekRange: (min: Double, max: Double) {
        let lows = days.map(\.lowC)
        let highs = days.map(\.highC)
        return (
            min: lows.min() ?? 0,
            max: highs.max() ?? 1
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("10-Day Forecast", systemImage: "calendar")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))

            VStack(spacing: 0) {
                ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                    DailyRow(
                        day: day,
                        isToday: index == 0,
                        weekRange: weekRange,
                        currentTempC: index == 0 ? currentTempC : nil
                    )
                    if index < days.count - 1 {
                        Divider()
                            .background(.white.opacity(0.25))
                    }
                }
            }
        }
        .padding()
        .background(.white.opacity(0.15))
        .clipShape(.rect(cornerRadius: 16))
    }
}

private struct DailyRow: View {
    let day: DailyEntry
    let isToday: Bool
    let weekRange: (min: Double, max: Double)
    let currentTempC: Double?

    var body: some View {
        HStack(spacing: 10) {
            Text(isToday ? "Today" : day.date.formatted(.dateTime.weekday(.abbreviated)))
                .font(.body)
                .frame(width: 56, alignment: .leading)

            VStack(spacing: 0) {
                Image(systemName: day.condition.sfSymbol)
                    .font(.title3)
                    .symbolRenderingMode(.multicolor)
                if let chance = day.precipitationChance, chance >= 30 {
                    Text("\(chance)%")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(red: 0.55, green: 0.85, blue: 1.0))
                }
            }
            .frame(width: 32)

            TempView(celsius: day.lowC, compact: true)
                .foregroundStyle(.white.opacity(0.7))
                .frame(minWidth: 56, alignment: .trailing)

            RangeBar(
                low: day.lowC,
                high: day.highC,
                weekMin: weekRange.min,
                weekMax: weekRange.max,
                currentTempC: currentTempC
            )
            .frame(height: 4)
            .frame(maxWidth: .infinity)

            TempView(celsius: day.highC, compact: true)
                .frame(minWidth: 56, alignment: .leading)
        }
        .foregroundStyle(.white)
        .padding(.vertical, 8)
    }
}

private struct RangeBar: View {
    let low: Double
    let high: Double
    let weekMin: Double
    let weekMax: Double
    let currentTempC: Double?

    var body: some View {
        GeometryReader { geo in
            let span = max(weekMax - weekMin, 1)
            let lowPos = CGFloat((low - weekMin) / span) * geo.size.width
            let highPos = CGFloat((high - weekMin) / span) * geo.size.width
            let barWidth = max(highPos - lowPos, 6)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.2))

                Capsule()
                    .fill(LinearGradient(
                        colors: [Self.colorFor(low), Self.colorFor(high)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: barWidth)
                    .offset(x: lowPos)

                if let currentTempC,
                   currentTempC >= weekMin,
                   currentTempC <= weekMax {
                    let dotX = CGFloat((currentTempC - weekMin) / span) * geo.size.width
                    Circle()
                        .fill(.white)
                        .frame(width: 8, height: 8)
                        .shadow(color: .black.opacity(0.25), radius: 1)
                        .offset(x: dotX - 4)
                }
            }
        }
    }

    /// Maps a Celsius temp to a color for the range-bar gradient.
    /// Mirrors iOS Weather's cool-to-warm progression.
    private static func colorFor(_ celsius: Double) -> Color {
        switch celsius {
        case ..<(-5):  Color(red: 0.45, green: 0.55, blue: 0.95)
        case -5..<5:   Color(red: 0.30, green: 0.70, blue: 0.95)
        case 5..<15:   Color(red: 0.40, green: 0.85, blue: 0.75)
        case 15..<22:  Color(red: 0.55, green: 0.85, blue: 0.40)
        case 22..<28:  Color(red: 0.95, green: 0.80, blue: 0.30)
        case 28..<35:  Color(red: 0.95, green: 0.55, blue: 0.20)
        default:       Color(red: 0.92, green: 0.30, blue: 0.25)
        }
    }
}

#Preview {
    let today = Calendar.current.startOfDay(for: .now)
    let days = (0..<10).map { i in
        DailyEntry(
            date: today.addingTimeInterval(Double(i) * 86400),
            highC: Double.random(in: 18...26),
            lowC: Double.random(in: 8...14),
            condition: WeatherCondition.allCases.randomElement()!,
            sunrise: today.addingTimeInterval(6 * 3600),
            sunset: today.addingTimeInterval(20 * 3600),
            precipitationChance: Int.random(in: 0...100)
        )
    }
    return DailyList(days: days, currentTempC: 16)
        .padding()
        .background(LinearGradient(colors: [.blue, .indigo], startPoint: .top, endPoint: .bottom))
}
