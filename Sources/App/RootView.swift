import SwiftUI

struct RootView: View {
    private let client: any WeatherClient
    private let coordinate: Coordinate
    private let locationName: String

    @State private var forecast: Forecast?
    @State private var loadError: String?

    init(
        client: any WeatherClient = OpenMeteoClient(),
        coordinate: Coordinate = Coordinate(latitude: 37.32, longitude: -122.03),
        locationName: String = "Cupertino"
    ) {
        self.client = client
        self.coordinate = coordinate
        self.locationName = locationName
    }

    var body: some View {
        ZStack {
            background
            content
        }
        .task {
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
            ProgressView()
                .tint(.white)
        }
    }

    private func loaded(_ forecast: Forecast) -> some View {
        VStack(spacing: 8) {
            Text(locationName)
                .font(.title2)

            TempView(celsius: forecast.current.temperatureC)
                .font(.system(size: 84, weight: .thin))

            Text(forecast.current.condition.displayName)
                .font(.title3)

            HStack(spacing: 6) {
                Text("H:")
                TempView(celsius: highToday(forecast))
                Text("L:")
                TempView(celsius: lowToday(forecast))
            }
            .font(.callout)
        }
        .foregroundStyle(.white)
    }

    private var background: some View {
        LinearGradient(
            colors: [.blue, .indigo],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private func highToday(_ forecast: Forecast) -> Double {
        forecast.daily.first?.highC ?? forecast.current.temperatureC
    }

    private func lowToday(_ forecast: Forecast) -> Double {
        forecast.daily.first?.lowC ?? forecast.current.temperatureC
    }

    private func load() async {
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
