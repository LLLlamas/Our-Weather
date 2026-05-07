import SwiftUI

extension View {
    /// Subtle dark halo around text to improve legibility on bright gradient or
    /// material backgrounds. Single soft shadow at no offset reads as a very thin
    /// edge outline rather than a drop shadow. Apply at the Text/Label level.
    func legibleText() -> some View {
        self.shadow(color: .black.opacity(0.30), radius: 1.0, x: 0, y: 0)
    }
}
