import SwiftUI

struct HourlyStrip: View {
    let hours: [HourlyEntry]

    @State private var isExpanded: Bool = false

    private var upcoming: [HourlyEntry] {
        let cutoff = Date.now.addingTimeInterval(-3600)
        let limit = isExpanded ? 30 : 24
        return Array(hours.filter { $0.time > cutoff }.prefix(limit))
    }

    /// Consecutive hours grouped by `startOfDay`, in chronological order.
    /// The first group is "today" and renders without a day pill.
    private var days: [DayGroup] {
        let cal = Calendar.current
        var groups: [DayGroup] = []
        for entry in upcoming {
            let start = cal.startOfDay(for: entry.time)
            if let last = groups.last, last.startOfDay == start {
                groups[groups.count - 1].entries.append(entry)
            } else {
                groups.append(DayGroup(startOfDay: start, entries: [entry]))
            }
        }
        return groups
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Hourly Forecast", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .legibleText()
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .legibleText()
            }

            if isExpanded {
                verticalLayout
            } else {
                horizontalLayout
            }
        }
        .padding()
        .background(.white.opacity(0.15))
        .clipShape(.rect(cornerRadius: 16))
        .contentShape(.rect(cornerRadius: 16))
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.25)) {
                isExpanded.toggle()
            }
        }
    }

    // MARK: - Horizontal

    private var horizontalLayout: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(Array(days.enumerated()), id: \.element.startOfDay) { dayIndex, group in
                    VStack(spacing: 6) {
                        dayPill(for: group, isFirstGroup: dayIndex == 0)
                            .frame(height: 16)

                        HStack(spacing: 18) {
                            ForEach(Array(group.entries.enumerated()), id: \.element.id) { entryIndex, entry in
                                HourCell(
                                    entry: entry,
                                    isNow: dayIndex == 0 && entryIndex == 0
                                )
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }

    @ViewBuilder
    private func dayPill(for group: DayGroup, isFirstGroup: Bool) -> some View {
        if isFirstGroup {
            // Today is implicit — empty placeholder preserves vertical alignment
            // with subsequent days that do show a pill.
            Color.clear
        } else {
            Text(group.startOfDay.formatted(.dateTime.weekday(.abbreviated)))
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 1)
                .frame(maxWidth: .infinity)
                .background(.white.opacity(0.20))
                .clipShape(.capsule)
                .legibleText()
        }
    }

    // MARK: - Vertical

    private var verticalLayout: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(days.enumerated()), id: \.element.startOfDay) { dayIndex, group in
                if dayIndex > 0 {
                    Text(group.startOfDay.formatted(.dateTime.weekday(.abbreviated)))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 2)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(.white.opacity(0.20))
                        .clipShape(.capsule)
                        .legibleText()
                        .padding(.top, 4)
                }

                ForEach(Array(group.entries.enumerated()), id: \.element.id) { entryIndex, entry in
                    HourRow(
                        entry: entry,
                        isNow: dayIndex == 0 && entryIndex == 0
                    )
                    .frame(height: 44)
                }
            }
        }
    }
}

private struct DayGroup {
    let startOfDay: Date
    var entries: [HourlyEntry]
}

private struct HourCell: View {
    let entry: HourlyEntry
    let isNow: Bool

    var body: some View {
        VStack(spacing: 6) {
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

private struct HourRow: View {
    let entry: HourlyEntry
    let isNow: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(isNow ? "Now" : entry.time.formatted(.dateTime.hour()))
                .font(.callout)
                .frame(width: 64, alignment: .leading)
                .legibleText()

            Image(systemName: entry.condition.sfSymbol)
                .font(.title3)
                .symbolRenderingMode(.multicolor)
                .frame(width: 28)

            Text(entry.condition.displayName)
                .font(.callout)
                .lineLimit(1)
                .legibleText()

            Spacer(minLength: 8)

            TempView(celsius: entry.temperatureC, compact: true)
                .font(.callout)
        }
        .foregroundStyle(.white)
    }
}

#Preview {
    let now = Date.now
    let hours = (0..<48).map { i in
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
