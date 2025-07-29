Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            baseColors[2].opacity(greenOpacity),
                            baseColors[2].opacity(0)
                        ]),
                        center: .center,
                        startRadius: startRadius,
                        endRadius: maxRadius
                    )
                )
                .frame(width: frameSize, height: frameSize)
                .offset(x: blobPositions[2].x, y: blobPositions[2].y)
                .scaleEffect(greenScale)
                .blur(radius: blurRadius)