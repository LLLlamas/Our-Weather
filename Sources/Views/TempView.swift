import SwiftUI

/// Pure conversion helpers — kept out of any `View` so they aren't bound to `@MainActor`
/// and can be called freely from tests and background work.
enum Temperature {
    static func fahrenheit(fromCelsius celsius: Double) -> Int {
        Int((celsius * 9 / 5 + 32).rounded())
    }

    static func celsius(rounded celsius: Double) -> Int {
        Int(celsius.rounded())
    }
}

/// Single source of truth for temperature display.
/// Always renders both Fahrenheit and Celsius — the product rule.
struct TempView: View {
    let celsius: Double
    var compact: Bool = false

    var body: some View {
        let f = Temperature.fahrenheit(fromCelsius: celsius)
        let c = Temperature.celsius(rounded: celsius)
        Group {
            if compact {
                Text("\(f)° / \(c)°")
            } else {
                Text("\(f)°F / \(c)°C")
            }
        }
        .legibleText()
    }
}

#Preview {
    VStack(spacing: 16) {
        TempView(celsius: 14.2)
        TempView(celsius: 14.2, compact: true)
        TempView(celsius: -3)
        TempView(celsius: 32.5)
        TempView(celsius: 0)
    }
    .padding()
    .font(.title)
}
