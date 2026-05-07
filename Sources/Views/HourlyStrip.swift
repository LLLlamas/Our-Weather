import SwiftUI

struct HourlyStrip: View {
    let hours: [HourlyEntry]

    private var upcoming: [HourlyEntry] {
        let cutoff = Date.now.addingTimeInterval(-3600)
        return Array(hours.filter { $0.time > cutoff }.prefix(24))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Hourly Forecast", systemImage: "clock")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .legibleText()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 18) {
                    ForEach(Array(upcoming.enumerated()), id: \.element.id) { index, entry in
                        HourCell(
                            entry: entry,
                            isNow: index == 0,
                            dayLabel: dayLabel(forIndex: index)
                        )
                    }
                }
            }
        }
        .padding()
        .background(.white.opacity(0.15))
        .clipShape(.rect(cornerRadius: 16))
    }

    /// Returns an abbreviated weekday name for the cell when it's the first hour
    /// of a new day relative to the previous cell. Nil otherwise.
    private func dayLabel(forIndex index: Int) -> String? {
        guard index > 0 else { return nil }
        let cal = Calendar.current
        let prev = cal.startOfDay(for: upcoming[index - 1].time)
        let current = cal.startOfDay(for: upcoming[index].time)
        guard prev != current else { return nil }
        return upcoming[index].time.formatted(.dateTime.weekday(.abbreviated))
    }
}

private struct HourCell: View {
    let entry: HourlyEntry
    let isNow: Bool
    let dayLabel: String?

    var body: some View {
        VStack(spacing: 6) {
            // Day pill area — fixed height so all cells align vertically
            Group {
                if let dayLabel {
                    Text(dayLabel)
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(.white.opacity(0.20))
                        .clipShape(.capsule)
                        .legibleText()
                } else {
                    Color.clear
                }
            }
            .frame(height: 16)

            Text(isNow ? "Now" : entry.time.formatted(.dateTime.hour()))
                .font(.caption)
                .legibleText()

            Image(systemName: entry.condition.sfSymbol)
                .font(.title3)
                .symbolRenderingMode(.multicolor)
                .frame(height: 24)

            TempView(celsius: entry.temperatureC, compact: true)
                .font(.callout)
        }
        .foregroundStyle(.white)
    }
}

#Preview {
    let now = Date.now
    let hours = (0..<20).map { i in
        HourlyEntry(
            time: now.addingTimeInterval(Double(i) * 3600),
            temperatureC: Double.random(in: 8...18),
            condition: WeatherCondition.allCases.randomElement()!,
            precipitationChance: Int.random(in: 0...80)
        )
    }
    return HourlyStrip(hours: hours)
        .padding()
        .background(LinearGradient(colors: [.blue, .indigo], startPoint: .top, endPoint: .bottom))
}
