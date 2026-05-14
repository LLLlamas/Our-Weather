import SwiftUI

extension View {
    /// Thin dark silver/chrome halo around text for legibility on any background.
    /// Single pass (radius 0.5, no offset) reads as a sharp edge outline without
    /// the multi-pass compositing cost of stacked shadow modifiers.
    /// Apply at the Text/Label level.
    func legibleText() -> some View {
        self.shadow(color: Color(red: 0.20, green: 0.20, blue: 0.26).opacity(0.65), radius: 0.5, x: 0, y: 0)
    }
}
