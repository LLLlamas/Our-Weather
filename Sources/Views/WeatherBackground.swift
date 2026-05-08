import SwiftUI

struct WeatherBackground: View {
    let condition: WeatherCondition
    let isDay: Bool

    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(
            LinearGradient(
                colors: [.clear, .black.opacity(0.20)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .ignoresSafeArea()
    }

    private var colors: [Color] {
        switch condition {
        case .clear:
            isDay
                ? [Color(red: 0.18, green: 0.50, blue: 0.86), Color(red: 0.40, green: 0.68, blue: 0.86)]
                : [Color(red: 0.05, green: 0.06, blue: 0.20), Color(red: 0.10, green: 0.12, blue: 0.30)]
        case .partlyCloudy:
            isDay
                ? [Color(red: 0.32, green: 0.50, blue: 0.77), Color(red: 0.50, green: 0.63, blue: 0.81)]
                : [Color(red: 0.10, green: 0.12, blue: 0.25), Color(red: 0.20, green: 0.22, blue: 0.35)]
        case .overcast, .fog:
            isDay
                ? [Color(red: 0.40, green: 0.45, blue: 0.50), Color(red: 0.54, green: 0.58, blue: 0.63)]
                : [Color(red: 0.15, green: 0.17, blue: 0.20), Color(red: 0.25, green: 0.27, blue: 0.30)]
        case .drizzle, .rain:
            [Color(red: 0.28, green: 0.35, blue: 0.44), Color(red: 0.38, green: 0.45, blue: 0.54)]
        case .snow:
            [Color(red: 0.50, green: 0.56, blue: 0.65), Color(red: 0.68, green: 0.72, blue: 0.79)]
        case .thunderstorm:
            [Color(red: 0.12, green: 0.13, blue: 0.22), Color(red: 0.25, green: 0.27, blue: 0.36)]
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 8) {
            ForEach(WeatherCondition.allCases, id: \.self) { c in
                ZStack {
                    WeatherBackground(condition: c, isDay: true)
                        .frame(height: 60)
                    Text(c.displayName)
                        .foregroundStyle(.white)
                }
                ZStack {
                    WeatherBackground(condition: c, isDay: false)
                        .frame(height: 60)
                    Text("\(c.displayName) (night)")
                        .foregroundStyle(.white)
                }
            }
        }
    }
}
