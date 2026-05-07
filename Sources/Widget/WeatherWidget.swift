import WidgetKit
import SwiftUI

struct WeatherWidget: Widget {
    let kind: String = "WeatherWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeatherProvider()) { entry in
            WeatherWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    WeatherBackground(condition: entry.condition, isDay: entry.isDay)
                }
        }
        .configurationDisplayName("Weather")
        .description("Current temperature for your location, in both °F and °C.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryRectangular,
            .accessoryCircular,
            .accessoryInline,
        ])
    }
}
