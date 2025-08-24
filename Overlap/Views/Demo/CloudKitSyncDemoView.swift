//
//  CloudKitSyncDemoView.swift
//  Overlap
//
//  Simple demo view showing how to use the SwiftData-CloudKit bridge for Overlap records
//

import SwiftUI
import CloudKit
import SwiftData

struct CloudKitSyncDemoView: View {
    @Environment(\.swiftDataCloudKitBridge) private var cloudKitBridge
    @Query private var overlaps: [Overlap]
    
    @State private var selectedOverlap: Overlap?
    @State private var cloudKitRecord: CKRecord?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var recordCount: Int = 0
    
    var body: some View {
        NavigationView {
            List {
                // CloudKit Status Section
                Section("CloudKit Status") {
                    HStack {
                        Text("Available")
                        Spacer()
                        Image(systemName: cloudKitBridge?.isCloudKitAvailable == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(cloudKitBridge?.isCloudKitAvailable == true ? .green : .red)
                    }
                    
                    HStack {
                        Text("Sync Status")
                        Spacer()
                        Text(syncStatusText)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("CloudKit Records")
                        Spacer()
                        Text("\(recordCount)")
                    }
                }
                
                // Actions Section
                Section("Actions") {
                    Button("Refresh Record Count") {
                        Task {
                            await refreshRecordCount()
                        }
                    }
                    .disabled(cloudKitBridge?.isCloudKitAvailable != true)
                }
                
                // Overlaps Section
                if !overlaps.isEmpty {
                    Section("Overlaps") {
                        ForEach(overlaps, id: \.id) { overlap in
                            VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
                                Text(overlap.title.isEmpty ? "Untitled" : overlap.title)
                                    .font(.headline)
                                
                                Text("\(overlap.participants.count) participants")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Button("Get CloudKit Record") {
                                    selectedOverlap = overlap
                                    Task {
                                        await getCloudKitRecord(for: overlap)
                                    }
                                }
                                .font(.caption)
                                .disabled(cloudKitBridge?.isCloudKitAvailable != true)
                            }
                            .padding(.vertical, Tokens.Spacing.xs)
                        }
                    }
                }
                
                // CloudKit Record Details
                if let record = cloudKitRecord {
                    Section("CloudKit Record Details") {
                        VStack(alignment: .leading, spacing: Tokens.Spacing.s) {
                            Text("Record ID: \(record.recordID.recordName)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("Record Type: \(record.recordType)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("Zone: \(record.recordID.zoneID.zoneName)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let changeTag = record.recordChangeTag {
                                Text("Change Tag: \(changeTag)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("Fields: \(record.allKeys().count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Error Display
                if let error = errorMessage {
                    Section("Error") {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("CloudKit Sync Demo")
            .refreshable {
                await refreshRecordCount()
            }
            .task {
                await refreshRecordCount()
            }
        }
        .overlay {
            if isLoading {
                LoadingOverlay()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var syncStatusText: String {
        guard let bridge = cloudKitBridge else { return "Unknown" }
        
        switch bridge.syncStatus {
        case .idle:
            return "Idle"
        case .syncing:
            return "Syncing..."
        case .error:
            return "Error"
        }
    }
    
    // MARK: - Methods
    
    private func refreshRecordCount() async {
        guard let bridge = cloudKitBridge else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let records = try await bridge.getAllOverlapRecords()
            recordCount = records.count
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func getCloudKitRecord(for overlap: Overlap) async {
        guard let bridge = cloudKitBridge else { return }
        
        isLoading = true
        errorMessage = nil
        cloudKitRecord = nil
        
        do {
            cloudKitRecord = try await bridge.getCloudKitRecord(for: overlap)
        } catch {
            errorMessage = "Failed to get CloudKit record: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

#Preview {
    CloudKitSyncDemoView()
        .modelContainer(for: [Overlap.self], inMemory: true)
}