//
//  BlobBackgroundView.swift
//  Overlap
//
//  Created by Paul Davis on 7/24/25.
//

import SwiftUI

struct BlobBackgroundView: View {
    @State private var pulseScale: CGFloat = 1.0
    @State private var opacity: Double = 0.3
    
    private let colors: [Color] = [
        .red.opacity(0.4),
        .yellow.opacity(0.4),
        .green.opacity(0.4)
    ]
    
    var body: some View {
        ZStack {
            // Simple static blobs with pulsing animation
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                colors[index],
                                colors[index].opacity(0)
                            ]),
                            center: .center,
                            startRadius: 100,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .offset(
                        x: index == 0 ? -100 : (index == 1 ? 100 : 0),
                        y: index == 0 ? -150 : (index == 1 ? 50 : 200)
                    )
                    .scaleEffect(pulseScale)
                    .opacity(opacity)
                    .blur(radius: 20)
                    .animation(
                        .easeInOut(duration: 3.0 + Double(index))
                        .repeatForever(autoreverses: true),
                        value: pulseScale
                    )
                    .animation(
                        .easeInOut(duration: 4.0 + Double(index) * 0.5)
                        .repeatForever(autoreverses: true),
                        value: opacity
                    )
            }
        }
        .ignoresSafeArea()
        .onAppear {
            pulseScale = 1.2
            opacity = 0.6
        }
    }
}

#Preview {
    BlobBackgroundView()
}
