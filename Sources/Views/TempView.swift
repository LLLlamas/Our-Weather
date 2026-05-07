import SwiftUI

/// Single source of truth for temperature display.
/// Always renders both Fahrenheit and Celsius — the product rule.
struct TempView: View {
    let celsius: Double
    var compact: Bool = false

    var body: some View {
        if compact {
            Text("\(fahrenheit)° / \(celsiusInt)°")
        } else {
            Text("\(fahrenheit)°F / \(celsiusInt)°C")
        }
    }

    var fahrenheit: Int {
        Int((celsius * 9 / 5 + 32).rounded())
    }

    var celsiusInt: Int {
        Int(celsius.rounded())
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
