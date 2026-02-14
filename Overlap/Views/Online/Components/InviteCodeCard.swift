//
//  InviteCodeCard.swift
//  Overlap
//
//  Reusable invite code display with inline share and copy actions.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct InviteCodeCard: View {
    let code: String
    let shareURL: URL
    let questionnaireTitle: String

    @State private var didCopyCode = false

    var body: some View {
        HStack(spacing: Tokens.Spacing.m) {
            // Code display
            VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
                Text("Invite Code")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text(code)
                    .font(.title3)
                    .fontWeight(.bold)
                    .fontDesign(.monospaced)
                    .foregroundColor(.primary)
            }

            Spacer()

            // Inline action buttons
            ShareLink(
                item: shareURL,
                subject: Text("Join my Overlap session"),
                message: Text("Join \"\(questionnaireTitle)\" on Overlap. If needed, use code \(code).")
            ) {
                Image(systemName: "square.and.arrow.up")
                    .font(.body)
                    .foregroundColor(.blue)
                    .frame(width: Tokens.Size.buttonCompact, height: Tokens.Size.buttonCompact)
            }
            .buttonStyle(.bordered)
            .clipShape(Circle())

            Button {
                copyInviteCode()
            } label: {
                Image(systemName: didCopyCode ? "checkmark" : "doc.on.doc")
                    .font(.body)
                    .foregroundColor(didCopyCode ? .green : .blue)
                    .frame(width: Tokens.Size.buttonCompact, height: Tokens.Size.buttonCompact)
            }
            .buttonStyle(.bordered)
            .clipShape(Circle())
        }
        .padding(Tokens.Spacing.l)
        .standardGlassCard()
    }

    private func copyInviteCode() {
        #if canImport(UIKit)
        UIPasteboard.general.string = code
        #endif
        withAnimation { didCopyCode = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { didCopyCode = false }
        }
    }
}

#Preview {
    InviteCodeCard(
        code: "ABC-123",
        shareURL: URL(string: "https://overlap.app/join?token=abc123")!,
        questionnaireTitle: "Weekend Plans"
    )
    .padding()
}
