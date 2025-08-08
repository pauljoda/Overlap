//
//  ColorPickerSheet.swift
//  Overlap
//
//  Created by Paul Davis on 8/6/25.
//

import SwiftUI

struct ColorPickerSheet: View {
    @Binding var selectedColor: Color
    let colorType: CreateQuestionnaireView.ColorType
    @Environment(\.dismiss) private var dismiss
    
    private let presetColors: [Color] = [
        .blue, .purple, .pink, .red, .orange, .yellow,
        .green, .mint, .teal, .cyan, .indigo, .brown
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Color Wheel Picker
                ColorPicker("Custom Color", selection: $selectedColor, supportsOpacity: false)
                    .labelsHidden()
                    .scaleEffect(1.5)
                    .padding()
                
                // Preset Colors
                VStack(alignment: .leading, spacing: 16) {
                    Text("Preset Colors")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                        ForEach(presetColors, id: \.self) { color in
                            Button(action: {
                                selectedColor = color
                            }) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 3)
                                    )
                                    .scaleEffect(selectedColor == color ? 1.1 : 1.0)
                                    .animation(.easeInOut(duration: 0.2), value: selectedColor)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top)
            .navigationTitle("\(colorType == .start ? "Start" : "End") Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        resetColor()
                    }
                }
            }
        }
    }

    private func resetColor() {
        switch colorType {
        case .start:
            selectedColor = .blue
        case .end:
            selectedColor = .purple
        }
    }
}

#Preview {
    @State var color = Color.blue
    
    ColorPickerSheet(
        selectedColor: $color,
        colorType: .start
    )
}
