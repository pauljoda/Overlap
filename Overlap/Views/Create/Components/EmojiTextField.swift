//
//  EmojiTextField.swift
//  Overlap
//
//  Created by Paul Davis on 8/7/25.
//

import SwiftUI

struct EmojiTextField: View {
    @Binding var text: String
    var placeholder: String = "📝"
    @FocusState.Binding var isFocused: Bool
    
    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(.plain)
            .multilineTextAlignment(.center)
            .font(.system(size: Tokens.FontSize.extraLarge * 0.67))
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .focused($isFocused)
            .onChange(of: text) { oldValue, newValue in
                // Filter to only allow single emoji
                if newValue.isEmpty {
                    // Allow empty text (deletion)
                    return
                } else if newValue.count == 1 && newValue.isSingleEmoji {
                    // Keep single emoji if it's exactly one character
                    return
                } else {
                    // Multiple characters or mixed content - extract the newest emoji
                    let emojis = newValue.compactMap { char in
                        String(char).isSingleEmoji ? char : nil
                    }
                    
                    if let lastEmoji = emojis.last {
                        // Use the last (most recently typed) emoji
                        text = String(lastEmoji)
                    } else {
                        // No emoji found, revert to previous valid value
                        text = oldValue.isSingleEmoji ? oldValue : ""
                    }
                }
            }
    }
}

extension String {
    var isSingleEmoji: Bool {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count == 1, let character = trimmed.first else { return false }
        return character.isEmoji
    }
}

extension Character {
    var isEmoji: Bool {
        // Following Apple's guidance: check multiple scalars in a Character
        // and handle default presentations and variation selectors properly
        let scalars = unicodeScalars
        
        // For single scalar characters
        if scalars.count == 1 {
            let scalar = scalars.first!
            // Use isEmojiPresentation for default emoji presentation
            // This excludes digits and other non-default emoji scalars
            return scalar.properties.isEmojiPresentation
        }
        
        // For multi-scalar characters (like emoji with variation selectors)
        let baseScalar = scalars.first!
        
        // Check if base scalar is emoji and if there's a variation selector
        if baseScalar.properties.isEmoji {
            // Check for variation selector-16 (U+FE0F) which forces emoji presentation
            let hasEmojiVariationSelector = scalars.contains { $0.value == 0xFE0F }
            
            // Either has default emoji presentation or explicit emoji variation selector
            return baseScalar.properties.isEmojiPresentation || hasEmojiVariationSelector
        }
        
        return false
    }
}

#Preview {
    @State var emoji = "📝"
    @FocusState var isFocused: Bool
    
    VStack {
        Text("Selected: \(emoji)")
        EmojiTextField(text: $emoji, isFocused: $isFocused)
            .frame(width: Tokens.Size.maxContentWidth * 0.25, height: Tokens.Size.buttonStandard + Tokens.Spacing.m)
            .background(Color.gray.opacity(Tokens.Opacity.light))
            .cornerRadius(Tokens.Radius.s)
    }
    .padding()
}
