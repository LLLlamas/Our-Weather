import Foundation

struct GeocodingResult: Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let admin1: String?
    let country: String?
    let coordinate: Coordinate

    var subtitle: String {
        [admin1, country].compactMap { $0 }.joined(separator: ", ")
    }
}

protocol GeocodingClient: Sendable {
    func search(_ query: String) async throws -> [GeocodingResult]
}

struct OpenMeteoGeocodingClient: GeocodingClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func search(_ query: String) async throws -> [GeocodingResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return [] }

        var components = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")!
        components.queryItems = [
            .init(name: "name", value: trimmed),
            .init(name: "count", value: "10"),
            .init(name: "language", value: "en"),
            .init(name: "format", value: "json"),
        ]
        guard let url = components.url else { throw URLError(.badURL) }

        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }

        let raw = try JSONDecoder().decode(GeocodingResponse.self, from: data)
        return (raw.results ?? []).map {
            GeocodingResult(
                id: $0.id,
                name: $0.name,
                admin1: $0.admin1,
                country: $0.country,
                coordinate: Coordinate(latitude: $0.latitude, longitude: $0.longitude)
            )
        }
    }
}

private struct GeocodingResponse: Decodable {
    let results: [Raw]?

    struct Raw: Decodable {
        let id: Int
        let name: String
        let latitude: Double
        let longitude: Double
        let admin1: String?
        let country: String?
    }
}
