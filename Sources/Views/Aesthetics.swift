import SwiftUI

extension View {
    /// Solid dark silver/chrome outline around text for legibility on any background.
    /// Eight 1pt offset shadows at radius 0 fill every edge pixel with no blur bleed.
    /// Apply at the Text/Label level.
    func legibleText() -> some View {
        let c = Color(red: 0.22, green: 0.22, blue: 0.28).opacity(0.90)
        return self
            .shadow(color: c, radius: 0, x: 1,  y: 0)
            .shadow(color: c, radius: 0, x: -1, y: 0)
            .shadow(color: c, radius: 0, x: 0,  y: 1)
            .shadow(color: c, radius: 0, x: 0,  y: -1)
            .shadow(color: c, radius: 0, x: 1,  y: 1)
            .shadow(color: c, radius: 0, x: -1, y: -1)
            .shadow(color: c, radius: 0, x: 1,  y: -1)
            .shadow(color: c, radius: 0, x: -1, y: 1)
    }
}
