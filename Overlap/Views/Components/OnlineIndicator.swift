//
//  OnlineIndicator.swift
//  Overlap
//
//  Visual indicator for online vs offline overlap sessions
//

import SwiftUI

struct OnlineIndicator: View {
    let isOnline: Bool
    let style: Style
    
    enum Style {
        case compact
        case detailed
    }
    
    init(isOnline: Bool, style: Style = .compact) {
        self.isOnline = isOnline
        self.style = style
    }
    
    var body: some View {
        HStack(spacing: Tokens.Spacing.xs) {
            // Status dot
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            if style == .detailed {
                Text(statusText)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(statusColor)
            }
        }
        .padding(.horizontal, style == .detailed ? Tokens.Spacing.s : 0)
        .padding(.vertical, style == .detailed ? Tokens.Spacing.xs : 0)
        .background(
            style == .detailed ? 
            RoundedRectangle(cornerRadius: Tokens.Radius.s)
                .fill(statusColor.opacity(0.1)) : 
            nil
        )
    }
    
    private var statusColor: Color {
        isOnline ? .green : .gray
    }
    
    private var statusText: String {
        isOnline ? "Online" : "Offline"
    }
}

#Preview {
    VStack(spacing: Tokens.Spacing.l) {
        HStack {
            Text("Offline:")
            OnlineIndicator(isOnline: false, style: .compact)
            OnlineIndicator(isOnline: false, style: .detailed)
        }
        
        HStack {
            Text("Online:")
            OnlineIndicator(isOnline: true, style: .compact)
            OnlineIndicator(isOnline: true, style: .detailed)
        }
    }
    .padding()
}
