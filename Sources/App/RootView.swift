import SwiftUI

struct RootView: View {
    private let client: any WeatherClient
    @State private var locationService = LocationService()

    @State private var locationName: String = ""
    @State private var forecast: Forecast?
    @State private var loadError: String?

    private static let fallbackCoordinate = Coordinate(latitude: 37.32, longitude: -122.03)
    private static let fallbackName = "Cupertino"

    init(client: any WeatherClient = OpenMeteoClient()) {
        self.client = client
    }

    var body: some View {
        ZStack {
            background
            content
        }
        .task { await load() }
        .refreshable { await load() }
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
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
    }

    private func header(_ forecast: Forecast) -> some View {
        VStack(spacing: 4) {
            Text(locationName)
                .font(.title2)

            TempView(celsius: forecast.current.temperatureC)
                .font(.system(size: 76, weight: .thin))

            Text(forecast.current.condition.displayName)
                .font(.title3)

            HStack(spacing: 6) {
                Text("H:")
                TempView(celsius: highToday(forecast), compact: true)
                Text("L:")
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
        let coordinate: Coordinate
        if let real = try? await locationService.currentCoordinate() {
            coordinate = real
            locationName = await locationService.placeName(for: real) ?? "Current Location"
        } else {
            coordinate = Self.fallbackCoordinate
            locationName = Self.fallbackName
        }

        do {
            forecast = try await client.forecast(for: coordinate)
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
    }
}

#Preview {
    RootView()
}
