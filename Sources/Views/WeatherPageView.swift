import SwiftUI

/// One paged screen of weather for a single saved location.
/// `RootView` hosts a TabView of these, one per saved location.
struct WeatherPageView: View {
    let location: SavedLocation
    let client: any WeatherClient

    @State private var forecast: Forecast?
    @State private var loadError: String?

    var body: some View {
        ZStack {
            background
            content
        }
        .task(id: location.id) {
            await load()
        }
        .refreshable {
            await load()
        }
    }

    @ViewBuilder
    private var content: some View {
        if let forecast {
            loaded(forecast)
        } else if let loadError {
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                Text("Couldn't load weather")
                    .font(.headline)
                Text(loadError)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .foregroundStyle(.white)
        } else {
            ProgressView().tint(.white)
        }
    }

    private func loaded(_ forecast: Forecast) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                header(forecast)
                HourlyStrip(hours: forecast.hourly)
                DailyList(days: forecast.daily, currentTempC: forecast.current.temperatureC)
                ConditionCards(current: forecast.current, today: forecast.daily.first)
            }
            .padding(.horizontal)
            .padding(.top, 60)
            .padding(.bottom, 60)
        }
        .scrollIndicators(.hidden)
    }

    private func header(_ forecast: Forecast) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                if location.isCurrentLocation {
                    Image(systemName: "location.fill")
                        .font(.caption)
                }
                Text(location.name)
                    .font(.title2)
                    .legibleText()
            }

            TempView(celsius: forecast.current.temperatureC)
                .font(.system(size: 80, weight: .thin, design: .rounded))

            Text(forecast.current.condition.displayName)
                .font(.title3)
                .legibleText()

            HStack(spacing: 6) {
                Text("H:").legibleText()
                TempView(celsius: highToday(forecast), compact: true)
                Text("L:").legibleText()
                TempView(celsius: lowToday(forecast), compact: true)
            }
            .font(.callout)
            .padding(.top, 4)
        }
        .foregroundStyle(.white)
    }

    private var background: some View {
        WeatherBackground(
            condition: forecast?.current.condition ?? .clear,
            isDay: forecast?.current.isDay ?? true
        )
    }

    private func highToday(_ forecast: Forecast) -> Double {
        forecast.daily.first?.highC ?? forecast.current.temperatureC
    }

    private func lowToday(_ forecast: Forecast) -> Double {
        forecast.daily.first?.lowC ?? forecast.current.temperatureC
    }

    private func load() async {
        do {
            forecast = try await client.forecast(for: location.coordinate)
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
    }
}
