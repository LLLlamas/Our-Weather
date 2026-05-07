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

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 18) {
                    ForEach(upcoming) { entry in
                        HourCell(entry: entry, isNow: entry.id == upcoming.first?.id)
                    }
                }
            }
        }
        .padding()
        .background(.white.opacity(0.15))
        .clipShape(.rect(cornerRadius: 16))
    }
}

private struct HourCell: View {
    let entry: HourlyEntry
    let isNow: Bool

    var body: some View {
        VStack(spacing: 8) {
            Text(isNow ? "Now" : entry.time.formatted(.dateTime.hour()))
                .font(.caption)

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
    let hours = (0..<12).map { i in
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
