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
        .ignoresSafeArea()
    }

    private var colors: [Color] {
        switch condition {
        case .clear:
            isDay
                ? [Color(red: 0.20, green: 0.55, blue: 0.95), Color(red: 0.45, green: 0.75, blue: 0.95)]
                : [Color(red: 0.05, green: 0.06, blue: 0.20), Color(red: 0.10, green: 0.12, blue: 0.30)]
        case .partlyCloudy:
            isDay
                ? [Color(red: 0.35, green: 0.55, blue: 0.85), Color(red: 0.55, green: 0.70, blue: 0.90)]
                : [Color(red: 0.10, green: 0.12, blue: 0.25), Color(red: 0.20, green: 0.22, blue: 0.35)]
        case .overcast, .fog:
            isDay
                ? [Color(red: 0.45, green: 0.50, blue: 0.55), Color(red: 0.60, green: 0.65, blue: 0.70)]
                : [Color(red: 0.15, green: 0.17, blue: 0.20), Color(red: 0.25, green: 0.27, blue: 0.30)]
        case .drizzle, .rain:
            [Color(red: 0.30, green: 0.38, blue: 0.48), Color(red: 0.42, green: 0.50, blue: 0.60)]
        case .snow:
            [Color(red: 0.55, green: 0.62, blue: 0.72), Color(red: 0.75, green: 0.80, blue: 0.88)]
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
