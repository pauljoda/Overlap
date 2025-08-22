import SwiftUI
import CloudKit

struct ShareButton: View {
    @Environment(\.cloudKitService) private var cloudKitService
    
    let overlap: Overlap
    
    @State private var showingShareSheet = false
    @State private var shareToPresent: CKShare?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private var isDisabled: Bool {
        !cloudKitService.isAvailable || isLoading
    }
    
    var body: some View {
        Button(action: shareOverlap) {
            HStack(spacing: Tokens.Spacing.s) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else if !cloudKitService.isAvailable {
                    Image(systemName: "icloud.slash")
                } else {
                    Image(systemName: overlap.shareRecordName != nil ? "person.2.fill" : "square.and.arrow.up")
                }
                
                Text(buttonText)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .padding(.horizontal, Tokens.Spacing.m)
            .padding(.vertical, Tokens.Spacing.s)
            .background(
                RoundedRectangle(cornerRadius: Tokens.Radius.m)
                    .fill(buttonColor.gradient)
            )
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1.0)
        .sheet(isPresented: $showingShareSheet) {
            if let share = shareToPresent {
                CloudKitSharingView(
                    share: share,
                    container: cloudKitService.container,
                    overlap: overlap
                )
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private var buttonText: String {
        if isLoading {
            return "Loading..."
        } else if !cloudKitService.isAvailable {
            return "iCloud Unavailable"
        } else if overlap.shareRecordName != nil {
            return "Manage Share"
        } else {
            return "Share"
        }
    }
    
    private var buttonColor: Color {
        cloudKitService.isAvailable ? .blue : .gray
    }
    
    private func shareOverlap() {
        Task {
            // Prevent multiple simultaneous operations
            guard !isLoading else { return }
            
            isLoading = true
            errorMessage = nil
            
            do {
                if overlap.shareRecordName != nil {
                    // Already shared - validate and get existing share
                    if let existingShare = try await cloudKitService.getShare(for: overlap) {
                        await MainActor.run {
                            shareToPresent = existingShare
                            showingShareSheet = true
                        }
                    } else {
                        // Share no longer exists, the getShare method already cleared the share info
                        errorMessage = "Share no longer exists. You can create a new share."
                    }
                } else {
                    // Not shared yet - create new share
                    let result = try await cloudKitService.prepareOverlapForSharing(overlap)
                    await MainActor.run {
                        shareToPresent = result.share
                        showingShareSheet = true
                    }
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            
            isLoading = false
        }
    }
}

// CloudKit Sharing View using UICloudSharingController
struct CloudKitSharingView: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer
    let overlap: Overlap
    
    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController(share: share, container: container)
        controller.delegate = context.coordinator
        controller.availablePermissions = [.allowPublic, .allowReadOnly, .allowReadWrite]
        controller.modalPresentationStyle = .formSheet
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(overlap: overlap)
    }
    
    class Coordinator: NSObject, UICloudSharingControllerDelegate {
        let overlap: Overlap
        
        init(overlap: Overlap) {
            self.overlap = overlap
        }
        
        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            print("Failed to save share: \(error)")
        }
        
        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            print("Successfully saved share")
        }
        
        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            print("Stopped sharing")
            // Clear share information from overlap
            overlap.shareRecordName = nil
            overlap.cloudKitRecordID = nil
            overlap.cloudKitZoneID = nil
            overlap.cloudKitParticipants = nil
        }
        
        func itemTitle(for csc: UICloudSharingController) -> String? {
            return overlap.title
        }
    }
}

// MARK: - Preview

#Preview {
    ShareButton(overlap: SampleData.sampleOverlap)
        .environment(\.cloudKitService, CloudKitService())
}