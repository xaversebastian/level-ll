// ManualSessionSheet.swift — LevelEleven
// v1.0 | 2026-03-16
// - Log a past session with date range and participant selection
//

import SwiftUI

struct ManualSessionSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var sessionName = ""
    @State private var startDate = Calendar.current.date(byAdding: .hour, value: -4, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var selectedProfileIds: Set<String> = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Session Name
                    VStack(alignment: .leading, spacing: 6) {
                        Text("SESSION NAME")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(2)
                            .foregroundStyle(.secondary)
                        TextField("e.g. Friday Night", text: $sessionName)
                            .padding(12)
                            .background(Color.surfaceSecondary, in: RoundedRectangle(cornerRadius: 10))
                    }

                    // Date Range
                    VStack(alignment: .leading, spacing: 6) {
                        Text("TIME RANGE")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(2)
                            .foregroundStyle(.secondary)

                        DatePicker("Started", selection: $startDate)
                            .datePickerStyle(.compact)
                        DatePicker("Ended", selection: $endDate, in: startDate...)
                            .datePickerStyle(.compact)
                    }

                    // Participants
                    VStack(alignment: .leading, spacing: 6) {
                        Text("PARTICIPANTS")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(2)
                            .foregroundStyle(.secondary)

                        ForEach(appState.profiles, id: \.id) { profile in
                            Button {
                                if selectedProfileIds.contains(profile.id) {
                                    selectedProfileIds.remove(profile.id)
                                } else {
                                    selectedProfileIds.insert(profile.id)
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: selectedProfileIds.contains(profile.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selectedProfileIds.contains(profile.id) ? Color.accent : .secondary)
                                    Text(profile.avatarEmoji)
                                        .font(.title3)
                                    Text(profile.name)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.primary)
                                    Spacer()
                                }
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)
                        }

                        if appState.profiles.isEmpty {
                            Text("No profiles yet.")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .padding(.horizontal, DS.screenPadding)
                .padding(.vertical, 16)
            }
            .scrollIndicators(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Log Past Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveSession() }
                        .disabled(selectedProfileIds.isEmpty)
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let activeId = appState.activeProfileId {
                    selectedProfileIds.insert(activeId)
                }
            }
        }
    }

    private func saveSession() {
        let name = sessionName.trimmingCharacters(in: .whitespaces)
        let session = BallerSession(
            name: name.isEmpty ? "Manual Session" : name,
            participantIds: Array(selectedProfileIds),
            startedAt: startDate,
            endedAt: endDate
        )
        appState.sessionHistory.insert(session, at: 0)
        // Persist
        if let data = try? JSONEncoder().encode(appState.sessionHistory) {
            UserDefaults.standard.set(data, forKey: "sessionHistory")
        }
        dismiss()
    }
}
