//
//  ShareButton.swift
//  Overlap
//
//  Button component for sharing overlap sessions via CloudKit
//

import SwiftUI
import CloudKit

struct ShareButton: View {
    let overlap: Overlap
    @StateObject private var cloudKitService = CloudKitService()
    @State private var showingShareSheet = false
    @State private var shareItem: Any?
    @State private var isSharing = false
    @State private var shareError: Error?
    @State private var showingError = false
    
    var body: some View {
        Button(action: {
            Task {
                await shareOverlap()
            }
        }) {
            HStack(spacing: Tokens.Spacing.s) {
                if isSharing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "square.and.arrow.up")
                }
                Text("Share")
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .padding(.horizontal, Tokens.Spacing.m)
            .padding(.vertical, Tokens.Spacing.s)
            .background(
                RoundedRectangle(cornerRadius: Tokens.Radius.m)
                    .fill(.blue.gradient)
            )
        }
        .disabled(isSharing || !cloudKitService.isAvailable)
        .opacity(cloudKitService.isAvailable ? 1.0 : 0.6)
        .sheet(isPresented: $showingShareSheet) {
            if let shareItem = shareItem {
                ShareSheet(items: [shareItem])
            }
        }
        .alert("Sharing Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(shareError?.localizedDescription ?? "Failed to share overlap")
        }
    }
    
    private func shareOverlap() async {
        guard cloudKitService.isAvailable else { return }
        
        isSharing = true
        
        do {
            // Update overlap to mark as online
            overlap.isOnline = true
            
            // Create CloudKit share
            let share = try await cloudKitService.shareOverlap(overlap)
            
            await MainActor.run {
                shareItem = share
                showingShareSheet = true
                isSharing = false
            }
        } catch {
            await MainActor.run {
                shareError = error
                showingError = true
                isSharing = false
            }
        }
    }
}

// MARK: - UIKit ShareSheet Bridge

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    ShareButton(overlap: SampleData.sampleOverlap)
}