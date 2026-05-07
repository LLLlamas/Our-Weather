import SwiftUI
import WidgetKit

struct WeatherWidgetView: View {
    let entry: WeatherEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemSmall: small
        case .systemMedium: medium
        case .accessoryRectangular: accessoryRect
        case .accessoryCircular: accessoryCircle
        case .accessoryInline: accessoryInline
        default: small
        }
    }

    @ViewBuilder
    private var small: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.locationName)
                .font(.caption)
                .lineLimit(1)
                .legibleText()

            if let t = entry.temperatureC {
                TempView(celsius: t)
                    .font(.system(size: 26, weight: .light, design: .rounded))
            } else {
                Text("—")
                    .font(.system(size: 26, weight: .light, design: .rounded))
                    .legibleText()
            }

            Image(systemName: entry.condition.sfSymbol)
                .font(.title3)
                .symbolRenderingMode(.multicolor)

            Spacer()

            if let high = entry.highC, let low = entry.lowC {
                HStack(spacing: 4) {
                    Text("H:")
                    TempView(celsius: high, compact: true)
                    Text("L:")
                    TempView(celsius: low, compact: true)
                }
                .font(.caption2)
                .legibleText()
            } else if entry.isError {
                Text("Tap to refresh")
                    .font(.caption2)
                    .legibleText()
            }
        }
        .foregroundStyle(.white)
    }

    @ViewBuilder
    private var medium: some View {
        HStack(alignment: .top) {
            small
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(entry.condition.displayName)
                    .font(.subheadline)
                    .legibleText()
                if entry.temperatureC != nil {
                    Image(systemName: entry.condition.sfSymbol)
                        .font(.system(size: 56))
                        .symbolRenderingMode(.multicolor)
                }
                Spacer()
                Text(entry.date, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
                    .legibleText()
            }
            .foregroundStyle(.white)
        }
    }

    @ViewBuilder
    private var accessoryRect: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 4) {
                Image(systemName: entry.condition.sfSymbol)
                Text(entry.locationName).lineLimit(1)
            }
            .font(.caption2)

            if let t = entry.temperatureC {
                TempView(celsius: t)
                    .font(.headline)
            }

            if let high = entry.highC, let low = entry.lowC {
                HStack(spacing: 2) {
                    TempView(celsius: high, compact: true)
                    Text("/")
                    TempView(celsius: low, compact: true)
                }
                .font(.caption2)
            }
        }
    }

    @ViewBuilder
    private var accessoryCircle: some View {
        VStack(spacing: 0) {
            Image(systemName: entry.condition.sfSymbol)
                .font(.title3)
            if let t = entry.temperatureC {
                Text("\(Temperature.fahrenheit(fromCelsius: t))°")
                    .font(.caption2)
            }
        }
    }

    @ViewBuilder
    private var accessoryInline: some View {
        if let t = entry.temperatureC {
            Label {
                Text("\(Temperature.fahrenheit(fromCelsius: t))°/\(Temperature.celsius(rounded: t))°")
            } icon: {
                Image(systemName: entry.condition.sfSymbol)
            }
        } else {
            Text("Weather unavailable")
        }
    }
}
