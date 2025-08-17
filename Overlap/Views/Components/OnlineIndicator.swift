//
//  OnlineIndicator.swift
//  Overlap
//
//  Visual indicator for online vs offline overlap sessions
//

import SwiftUI

struct OnlineIndicator: View {
    let isOnline: Bool
    let overlapId: UUID?
    let style: Style
    
    @Environment(\.overlapSyncManager) private var syncManager
    
    enum Style {
        case compact
        case detailed
    }
    
    init(isOnline: Bool, overlapId: UUID? = nil, style: Style = .compact) {
        self.isOnline = isOnline
        self.overlapId = overlapId
        self.style = style
    }
    
    private var hasUnreadChanges: Bool {
        guard let overlapId = overlapId, let syncManager = syncManager else { return false }
        return syncManager.hasUnreadChanges(for: overlapId)
    }
    
    var body: some View {
        HStack(spacing: Tokens.Spacing.xs) {
            // Status dot
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .overlay(
                    // Pulsing animation for unread changes
                    Circle()
                        .stroke(statusColor, lineWidth: 1)
                        .scaleEffect(hasUnreadChanges ? 1.5 : 1.0)
                        .opacity(hasUnreadChanges ? 0.0 : 1.0)
                        .animation(
                            hasUnreadChanges ? 
                            .easeInOut(duration: 1.0).repeatForever(autoreverses: false) : 
                            .default,
                            value: hasUnreadChanges
                        )
                )
            
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
        if hasUnreadChanges {
            return .orange
        } else {
            return isOnline ? .green : .gray
        }
    }
    
    private var statusText: String {
        if hasUnreadChanges {
            return "Updates"
        } else {
            return isOnline ? "Online" : "Offline"
        }
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