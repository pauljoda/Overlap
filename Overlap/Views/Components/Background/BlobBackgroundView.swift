//
//  BlobBackgroundView.swift
//  Overlap
//
//  Created by Paul Davis on 7/24/25.
//

import SwiftUI

enum BlobEmphasis {
    case none
    case red  // No selection
    case yellow  // Maybe selection
    case green  // Yes selection
}

struct BlobBackgroundView: View {
    // MARK: Paramaters
    let emphasis: BlobEmphasis
    let blobPositions: [CGPoint]

    // MARK: Animation Variables
    @State private var pulseScale: CGFloat = 1.0
    @State private var opacity: Double = 0.3

    // Individual blob states for controlled animation
    @State private var redScale: CGFloat = 1.0
    @State private var yellowScale: CGFloat = 1.0
    @State private var greenScale: CGFloat = 1.0

    @State private var redOpacity: Double = 0.4
    @State private var yellowOpacity: Double = 0.4
    @State private var greenOpacity: Double = 0.4

    // MARK: Default Values
    private let baseColors: [Color] = [.red, .yellow, .green]

    // Default blob positions
    private static let defaultPositions: [CGPoint] = [
        CGPoint(x: -75, y: -175),  // Red blob
        CGPoint(x: 75, y: 25),  // Yellow blob
        CGPoint(x: 0, y: 225),  // Green blob
    ]

    // MARK: Constructor
    init(emphasis: BlobEmphasis = .none, blobPositions: [CGPoint]? = nil) {
        self.emphasis = emphasis
        self.blobPositions = blobPositions ?? Self.defaultPositions
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        ZStack {
            // Red blob
            Blob(
                color: baseColors[0],
                opacity: redOpacity,
                xPos: blobPositions[0].x,
                yPos: blobPositions[0].y,
                scale: redScale
            )

            // Yellow blob
            Blob(
                color: baseColors[1],
                opacity: yellowOpacity,
                xPos: blobPositions[1].x,
                yPos: blobPositions[1].y,
                scale: yellowScale
            )

            // Green blob
            Blob(
                color: baseColors[2],
                opacity: greenOpacity,
                xPos: blobPositions[2].x,
                yPos: blobPositions[2].y,
                scale: greenScale
            )
        }
        .ignoresSafeArea()
        .background(
            reduceTransparency ? Color(.systemBackground) : Color.clear
        )
        .onAppear {
            startDefaultAnimation()
        }
        .onChange(of: emphasis) { _, newEmphasis in
            updateEmphasis(newEmphasis)
        }
    }

    /// Starts the default random pulsing animation
    private func startDefaultAnimation() {
        if reduceMotion {
            // Respect Reduce Motion: keep subtle static scales/opacity
            withAnimation(.linear(duration: 0.01)) {
                redScale = 1.0; yellowScale = 1.0; greenScale = 1.0
                redOpacity = 0.4; yellowOpacity = 0.4; greenOpacity = 0.4
            }
            return
        }
        if emphasis == .none {
            // Default random pulsing behavior
            withAnimation(
                .easeInOut(duration: 3.0).repeatForever(autoreverses: true)
            ) {
                redScale = 1.2
                redOpacity = 0.6
            }

            withAnimation(
                .easeInOut(duration: 4.0).repeatForever(autoreverses: true)
            ) {
                yellowScale = 1.1
                yellowOpacity = 0.5
            }

            withAnimation(
                .easeInOut(duration: 3.5).repeatForever(autoreverses: true)
            ) {
                greenScale = 1.15
                greenOpacity = 0.55
            }
        } else {
            updateEmphasis(emphasis)
        }
    }

    /// Updates the emphasis based on selection
    private func updateEmphasis(_ newEmphasis: BlobEmphasis) {
        switch newEmphasis {
        case .none:
            // Return to default random pulsing
            withAnimation(.easeInOut(duration: 0.5)) {
                redScale = 1.0
                yellowScale = 1.0
                greenScale = 1.0
                redOpacity = 0.4
                yellowOpacity = 0.4
                greenOpacity = 0.4
            }

            // Restart default animations after transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                startDefaultAnimation()
            }

        case .red:
            withAnimation(.easeInOut(duration: 0.3)) {
                redScale = 1.5
                yellowScale = 0.8
                greenScale = 0.8
                redOpacity = 0.8
                yellowOpacity = 0.2
                greenOpacity = 0.2
            }

        case .yellow:
            withAnimation(.easeInOut(duration: 0.3)) {
                redScale = 0.8
                yellowScale = 1.5
                greenScale = 0.8
                redOpacity = 0.2
                yellowOpacity = 0.8
                greenOpacity = 0.2
            }

        case .green:
            withAnimation(.easeInOut(duration: 0.3)) {
                redScale = 0.8
                yellowScale = 0.8
                greenScale = 1.5
                redOpacity = 0.2
                yellowOpacity = 0.2
                greenOpacity = 0.8
            }
        }
    }
}

#Preview("Default") {
    BlobBackgroundView(emphasis: .none)
}

#Preview("Red Emphasis") {
    BlobBackgroundView(emphasis: .red)
}

#Preview("Yellow Emphasis") {
    BlobBackgroundView(emphasis: .yellow)
}

#Preview("Green Emphasis") {
    BlobBackgroundView(emphasis: .green)
}
