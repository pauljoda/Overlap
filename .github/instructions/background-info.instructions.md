---
applyTo: '**'
---
This is an iOS app targetting iOS 26. The purpose of the app is to present a list of questions to users, and have them answer yes, no, or maybe. Then, once all users have responded using the card swipe interfacing, it will show where users agree, or potentially agree. The app supports local pass-to-each-user play and a hosted online invite flow for multi-device participation.

It references the new Liquid Glass interface from Apple, so references to glassEffect and GlassEffectContainer, and similar styling that may look custom are part of the new native UI design from Apple

Here are some examples from apple

Text("Hello, World!")
    .font(.title)
    .padding()
    .glassEffect()


Text("Hello, World!")
    .font(.title)
    .padding()
    .glassEffect(in: .rect(cornerRadius: 16.0))


Text("Hello, World!")
    .font(.title)
    .padding()
    .glassEffect(.regular.tint(.orange).interactive())
