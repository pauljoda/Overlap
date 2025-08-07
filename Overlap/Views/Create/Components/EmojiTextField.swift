//
//  EmojiTextField.swift
//  Overlap
//
//  Created by Paul Davis on 8/7/25.
//

import SwiftUI
import UIKit

extension UIKeyboardType {
    static let emoji = UIKeyboardType(rawValue: 124)!
}

struct EmojiTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String = "📝"
    @Binding var isFocused: Bool
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.textAlignment = .center
        textField.font = UIFont.systemFont(ofSize: 32)
        textField.keyboardType = .emoji
        textField.returnKeyType = .done
        textField.delegate = context.coordinator
        
        // Configure for emoji input
        textField.textContentType = .none
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.spellCheckingType = .no
        
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
        
        // Handle focus state changes
        if isFocused && !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        } else if !isFocused && uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        let parent: EmojiTextField
        
        init(_ parent: EmojiTextField) {
            self.parent = parent
        }
        
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            // Get the current text
            let currentText = textField.text ?? ""
            
            // If trying to delete, allow it
            if string.isEmpty {
                let newText = (currentText as NSString).replacingCharacters(in: range, with: string)
                parent.text = newText
                return true
            }
            
            // Check if the new character is an emoji
            guard string.isSingleEmoji else {
                return false
            }
            
            // If there's already text, replace it entirely with the new emoji
            if !currentText.isEmpty {
                parent.text = string
                textField.text = string
                return false
            }
            
            // Allow the first emoji
            parent.text = string
            return true
        }
        
        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.isFocused = true
        }
        
        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.text = textField.text ?? ""
            parent.isFocused = false
        }
        
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
    }
}

extension Character {
    /// Check if the character is an emoji
    var isSimpleEmoji: Bool {
        guard let firstScalar = unicodeScalars.first else { return false }
        return firstScalar.properties.isEmoji && firstScalar.value > 0x238C
    }
    
    /// Check if the character is an emoji including complex emojis
    var isEmoji: Bool {
        // Simple emoji check
        if isSimpleEmoji { return true }
        
        // Check for complex emojis (like skin tone modifiers, combined emojis, etc.)
        return unicodeScalars.allSatisfy { scalar in
            scalar.properties.isEmoji ||
            scalar.properties.isEmojiModifier ||
            scalar.properties.isEmojiModifierBase ||
            scalar.value == 0x200D || // Zero-width joiner
            scalar.value == 0xFE0F    // Variation selector-16
        }
    }
}

extension String {
    /// Check if the string contains only a single emoji character
    var isSingleEmoji: Bool {
        return count == 1 && first?.isEmoji == true
    }
    
    /// Check if the string contains only emoji characters
    var isEmojiOnly: Bool {
        return !isEmpty && allSatisfy { $0.isEmoji }
    }
}

#Preview {
    @State var emoji = "📝"
    @State var isFocused = false
    
    VStack {
        Text("Selected: \(emoji)")
        EmojiTextField(text: $emoji, isFocused: $isFocused)
            .frame(width: 100, height: 60)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
    }
    .padding()
}
