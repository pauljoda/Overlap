import SwiftUI

struct BlobBackgroundView: View {
    @State private var animate = false
    @State private var hueRotation: Double = 0

    var body: some View {
        ZStack {
            // Blob 1 – Pastel Red
            Circle()
                .fill(LinearGradient(
                    colors: [Color.red.opacity(0.3), Color.orange.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing))
                .frame(width: 300, height: 300)
                .offset(x: animate ? -100 : 100, y: animate ? -150 : 150)
                .blur(radius: 60)
                .hueRotation(.degrees(hueRotation))
                .animation(.easeInOut(duration: 20).repeatForever(autoreverses: true), value: animate)

            // Blob 2 – Pastel Yellow
            Circle()
                .fill(LinearGradient(
                    colors: [Color.yellow.opacity(0.3), Color.white.opacity(0.2)],
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading))
                .frame(width: 250, height: 250)
                .offset(x: animate ? 120 : -120, y: animate ? 100 : -100)
                .blur(radius: 60)
                .hueRotation(.degrees(hueRotation + 45))
                .animation(.easeInOut(duration: 24).repeatForever(autoreverses: true), value: animate)

            // Blob 3 – Pastel Green
            Circle()
                .fill(LinearGradient(
                    colors: [Color.green.opacity(0.3), Color.teal.opacity(0.3)],
                    startPoint: .bottomLeading,
                    endPoint: .topTrailing))
                .frame(width: 280, height: 280)
                .offset(x: animate ? -130 : 130, y: animate ? 100 : -100)
                .blur(radius: 60)
                .hueRotation(.degrees(hueRotation + 90))
                .animation(.easeInOut(duration: 28).repeatForever(autoreverses: true), value: animate)
        }
        .ignoresSafeArea()
        .onAppear {
            animate = true
            withAnimation(Animation.linear(duration: 60).repeatForever(autoreverses: false)) {
                hueRotation = 360
            }
        }
    }
}
