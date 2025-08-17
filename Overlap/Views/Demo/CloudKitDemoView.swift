//
//  CloudKitDemoView.swift
//  Overlap
//
//  Demo view showcasing CloudKit sharing features
//

import SwiftUI
import SwiftData
import CloudKit

struct CloudKitDemoView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.navigationPath) private var navigationPath
    @StateObject private var cloudKitService = CloudKitService()
    
    @Query private var overlaps: [Overlap]
    
    var onlineOverlaps: [Overlap] {
        overlaps.filter { $0.isOnline }
    }
    
    var localOverlaps: [Overlap] {
        overlaps.filter { !$0.isOnline }
    }
    
    var body: some View {
        GlassScreen {
            VStack(spacing: Tokens.Spacing.xl) {
                
                // Header
                VStack(spacing: Tokens.Spacing.m) {
                    Image(systemName: "icloud.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue.gradient)
                    
                    Text("CloudKit Sharing Demo")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Experience collaborative overlap sessions")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // CloudKit Status
                VStack(spacing: Tokens.Spacing.s) {
                    HStack {
                        Image(systemName: cloudKitService.isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(cloudKitService.isAvailable ? .green : .red)
                        Text("CloudKit Status")
                            .font(.headline)
                        Spacer()
                        Text(cloudKitService.isAvailable ? "Available" : "Unavailable")
                            .font(.subheadline)
                            .foregroundColor(cloudKitService.isAvailable ? .green : .red)
                    }
                    
                    Text("Account: \(cloudKitService.accountStatus.description)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .standardGlassCard()
                
                // Online Overlaps Section
                if !onlineOverlaps.isEmpty {
                    VStack(alignment: .leading, spacing: Tokens.Spacing.m) {
                        HStack {
                            Image(systemName: "icloud.fill")
                                .foregroundColor(.blue)
                            Text("Online Overlaps")
                                .font(.headline)
                            Spacer()
                        }
                        
                        ForEach(onlineOverlaps, id: \.id) { overlap in
                            DemoOverlapCard(overlap: overlap, isOnline: true)
                        }
                    }
                }
                
                // Local Overlaps Section
                if !localOverlaps.isEmpty {
                    VStack(alignment: .leading, spacing: Tokens.Spacing.m) {
                        HStack {
                            Image(systemName: "device.iphone")
                                .foregroundColor(.gray)
                            Text("Local Overlaps")
                                .font(.headline)
                            Spacer()
                        }
                        
                        ForEach(localOverlaps, id: \.id) { overlap in
                            DemoOverlapCard(overlap: overlap, isOnline: false)
                        }
                    }
                }
                
                // Demo Actions
                VStack(spacing: Tokens.Spacing.m) {
                    Text("Demo Actions")
                        .font(.headline)
                    
                    HStack(spacing: Tokens.Spacing.m) {
                        Button("Create Online Overlap") {
                            createDemoOnlineOverlap()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Join Demo") {
                            navigate(to: .join, using: navigationPath)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .standardGlassCard()
                
                Spacer()
            }
            .padding(Tokens.Spacing.xl)
        }
        .navigationTitle("CloudKit Demo")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func createDemoOnlineOverlap() {
        let demoOverlap = Overlap(
            participants: ["Demo User"],
            isOnline: true,
            title: "Demo Online Session",
            information: "This is a demonstration of online collaborative features",
            instructions: "Share this overlap with others to test real-time collaboration",
            questions: [
                "Do you like the new sharing feature?",
                "Is the interface intuitive?",
                "Would you use this for team decisions?"
            ],
            iconEmoji: "🚀"
        )
        
        modelContext.insert(demoOverlap)
        try? modelContext.save()
        
        navigate(to: demoOverlap, using: navigationPath)
    }
}

struct DemoOverlapCard: View {
    let overlap: Overlap
    let isOnline: Bool
    @Environment(\.navigationPath) private var navigationPath
    
    var body: some View {
        Button(action: {
            navigate(to: overlap, using: navigationPath)
        }) {
            HStack {
                Circle()
                    .fill(overlap.startColor.gradient)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(overlap.iconEmoji)
                            .font(.title3)
                    )
                
                VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
                    Text(overlap.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    HStack {
                        OnlineIndicator(isOnline: isOnline, overlapId: overlap.id, style: .detailed)
                        
                        Spacer()
                        
                        Text("\(overlap.participants.count) participants")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if isOnline {
                    ShareButton(overlap: overlap)
                        .scaleEffect(0.8)
                }
            }
            .padding(Tokens.Spacing.m)
            .standardGlassCard()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Account Status Extension

extension CKAccountStatus {
    var description: String {
        switch self {
        case .available:
            return "Available"
        case .noAccount:
            return "No Account"
        case .restricted:
            return "Restricted"
        case .couldNotDetermine:
            return "Unknown"
        case .temporarilyUnavailable:
            return "Temporarily Unavailable"
        @unknown default:
            return "Unknown"
        }
    }
}

#Preview {
    NavigationStack {
        CloudKitDemoView()
    }
    .modelContainer(cloudKitPreviewContainer)
}