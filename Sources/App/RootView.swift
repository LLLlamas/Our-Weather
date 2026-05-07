import SwiftUI

struct RootView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.blue, .indigo],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                Text("Cupertino")
                    .font(.title2)

                TempView(celsius: 14.2)
                    .font(.system(size: 72, weight: .thin))

                Text("Partly Cloudy")
                    .font(.title3)
            }
            .foregroundStyle(.white)
        }
    }
}

#Preview {
    RootView()
}
