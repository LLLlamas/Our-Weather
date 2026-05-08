import SwiftUI

struct RootView: View {
    private let client: any WeatherClient
    private let geocoder: any GeocodingClient

    @State private var store = LocationStore()
    @State private var locationService = LocationService()
    @State private var showingLocations = false
    @AppStorage("forceNightMode") private var forceNightMode = false

    init(
        client: any WeatherClient = OpenMeteoClient(),
        geocoder: any GeocodingClient = OpenMeteoGeocodingClient()
    ) {
        self.client = client
        self.geocoder = geocoder
    }

    var body: some View {
        TabView(selection: tabSelection) {
            ForEach(store.locations) { location in
                WeatherPageView(location: location, client: client)
                    .tag(location.id)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: store.locations.count > 1 ? .always : .never))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .ignoresSafeArea()
        .overlay(alignment: .topTrailing) {
            VStack(spacing: 8) {
                Button {
                    forceNightMode.toggle()
                } label: {
                    Image(systemName: forceNightMode ? "moon.fill" : "moon")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(.ultraThinMaterial, in: .circle)
                }
                Button {
                    showingLocations = true
                } label: {
                    Image(systemName: "list.bullet")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(.ultraThinMaterial, in: .circle)
                }
            }
            .padding(.trailing, 16)
            .padding(.top, 8)
        }
        .task {
            await refreshCurrentLocation()
        }
        .sheet(isPresented: $showingLocations) {
            LocationsSheet(store: store, geocoder: geocoder)
        }
    }

    private var tabSelection: Binding<UUID> {
        Binding(
            get: { store.selectedID },
            set: { store.select($0) }
        )
    }

    private func refreshCurrentLocation() async {
        guard let coord = try? await locationService.currentCoordinate() else { return }
        let name = await locationService.placeName(for: coord) ?? "Current Location"
        store.updateCurrentLocation(coordinate: coord, name: name)
    }
}

#Preview {
    RootView()
}
