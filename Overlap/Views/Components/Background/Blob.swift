//
//  Blob.swift
//  Overlap
//
//  Created by Paul Davis on 7/26/25.
//

import SwiftUI

struct Blob: View {

    // MARK: Required Parameters
    let color: Color
    let opacity: CGFloat
    let xPos: CGFloat
    let yPos: CGFloat
    let scale: CGFloat

    // MARK: Optional (overridable)
    let startRadius: CGFloat
    let maxRadius: CGFloat
    let blurRadius: CGFloat
    let frameSize: CGFloat

    // MARK: Init
    init(
        color: Color,
        opacity: CGFloat,
        xPos: CGFloat,
        yPos: CGFloat,
        scale: CGFloat,
        startRadius: CGFloat = 100,
        maxRadius: CGFloat = 200,
        blurRadius: CGFloat = 30,
        frameSize: CGFloat = 400
    ) {
        self.color = color
        self.opacity = opacity
        self.xPos = xPos
        self.yPos = yPos
        self.scale = scale
        self.startRadius = startRadius
        self.maxRadius = maxRadius
        self.blurRadius = blurRadius
        self.frameSize = frameSize
    }

    // MARK: View Body
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [
                        color.opacity(opacity),
                        color.opacity(0),
                    ]),
                    center: .center,
                    startRadius: startRadius,
                    endRadius: maxRadius
                )
            )
            .frame(width: frameSize, height: frameSize)
            .offset(x: xPos, y: yPos)
            .scaleEffect(scale)
            .blur(radius: blurRadius)
    }
}

#Preview {
    Blob(
        color: .green,
        opacity: 0.8,
        xPos: 0,
        yPos: 0,
        scale: 1.0
    )
}
