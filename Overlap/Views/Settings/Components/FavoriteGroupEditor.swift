//
//  FavoriteGroupEditor.swift
//  Overlap
//
//  Create or edit a favorite participant group.
//

import SwiftUI
import SwiftData

struct FavoriteGroupEditor: View {
    let group: FavoriteGroup?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var groupName: String
    @State private var participants: [String]
    @State private var newParticipantName = ""
    @FocusState private var isNameFieldFocused: Bool
    @FocusState private var isParticipantFieldFocused: Bool

    private var isEditing: Bool { group != nil }

    private var canSave: Bool {
        !groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(group: FavoriteGroup?) {
        self.group = group
        _groupName = State(initialValue: group?.name ?? "")
        _participants = State(initialValue: group?.participants ?? [])
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Tokens.Spacing.xxl) {
                    groupNameSection
                    participantsSection
                }
                .padding(.horizontal, Tokens.Spacing.xl)
                .padding(.top, Tokens.Spacing.xl)
                .padding(.bottom, Tokens.Spacing.quadXL)
            }
            .navigationTitle(isEditing ? "Edit Group" : "New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        saveGroup()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    // MARK: - Group Name

    private var groupNameSection: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.m) {
            SectionHeader(title: "Group Name", icon: "tag.fill")

            TextField("e.g. Family, Work Team", text: $groupName)
                .textFieldStyle(.plain)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .padding(Tokens.Spacing.l)
                .standardGlassCard()
                .focused($isNameFieldFocused)
        }
    }

    // MARK: - Participants

    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.m) {
            SectionHeader(title: "Participants (\(participants.count))", icon: "person.3.fill")

            HStack(spacing: Tokens.Spacing.s) {
                TextField("Add participant", text: $newParticipantName)
                    .textFieldStyle(.plain)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .padding(Tokens.Spacing.l)
                    .standardGlassCard()
                    .focused($isParticipantFieldFocused)
                    .onSubmit { addParticipant() }

                Button {
                    addParticipant()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .disabled(newParticipantName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            ForEach(Array(participants.enumerated()), id: \.offset) { index, participant in
                HStack(spacing: Tokens.Spacing.m) {
                    Image(systemName: "person.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)

                    Text(participant)
                        .font(.body)

                    Spacer()

                    Button {
                        removeParticipant(at: index)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, Tokens.Spacing.l)
                .padding(.vertical, Tokens.Spacing.m)
                .standardGlassCard()
            }

            if participants.isEmpty {
                Text("Add participants to this group.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Actions

    private func addParticipant() {
        let trimmed = newParticipantName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !participants.contains(trimmed) else { return }
        withAnimation {
            participants.append(trimmed)
        }
        newParticipantName = ""
    }

    private func removeParticipant(at index: Int) {
        guard index < participants.count else { return }
        withAnimation {
            participants.remove(at: index)
        }
    }

    private func saveGroup() {
        let trimmedName = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        if let group {
            group.name = trimmedName
            group.participants = participants
        } else {
            let newGroup = FavoriteGroup(name: trimmedName, participants: participants)
            modelContext.insert(newGroup)
        }

        try? modelContext.save()
        dismiss()
    }
}

#Preview("New Group") {
    FavoriteGroupEditor(group: nil)
        .modelContainer(for: FavoriteGroup.self, inMemory: true)
}
