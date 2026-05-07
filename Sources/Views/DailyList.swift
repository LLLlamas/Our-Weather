import SwiftUI

struct DailyList: View {
    let days: [DailyEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("10-Day Forecast", systemImage: "calendar")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))

            VStack(spacing: 0) {
                ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                    DailyRow(day: day, isToday: index == 0)
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

    var body: some View {
        HStack(spacing: 12) {
            Text(isToday ? "Today" : day.date.formatted(.dateTime.weekday(.abbreviated)))
                .font(.body)
                .frame(width: 70, alignment: .leading)

            Image(systemName: day.condition.sfSymbol)
                .font(.title3)
                .symbolRenderingMode(.multicolor)
                .frame(width: 30)

            Spacer()

            TempView(celsius: day.lowC, compact: true)
                .foregroundStyle(.white.opacity(0.7))

            Text("/")
                .foregroundStyle(.white.opacity(0.5))

            TempView(celsius: day.highC, compact: true)
        }
        .foregroundStyle(.white)
        .padding(.vertical, 8)
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
    return DailyList(days: days)
        .padding()
        .background(LinearGradient(colors: [.blue, .indigo], startPoint: .top, endPoint: .bottom))
}
