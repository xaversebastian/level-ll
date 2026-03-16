// ManualSessionSheet.swift — LevelEleven
// v1.1 | 2026-03-16
// - Log a past session with date range, participant selection, and substance selection
// - Creates doses for selected substances and triggers feedback
//

import SwiftUI

struct ManualSessionSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var sessionName = ""
    @State private var startDate = Calendar.current.date(byAdding: .hour, value: -4, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var selectedProfileIds: Set<String> = []
    @State private var selectedSubstanceIds: Set<String> = []
    @State private var savedSessionId: String?
    @State private var showFeedback = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Session Name
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("SESSION NAME")
                        TextField("e.g. Friday Night", text: $sessionName)
                            .padding(12)
                            .background(Color.surfaceSecondary, in: RoundedRectangle(cornerRadius: 10))
                    }

                    // Date Range
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("TIME RANGE")
                        DatePicker("Started", selection: $startDate)
                            .datePickerStyle(.compact)
                        DatePicker("Ended", selection: $endDate, in: startDate...)
                            .datePickerStyle(.compact)
                    }

                    // Participants
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("PARTICIPANTS")

                        ForEach(appState.profiles, id: \.id) { profile in
                            toggleRow(
                                isSelected: selectedProfileIds.contains(profile.id),
                                label: { HStack(spacing: 8) { Text(profile.avatarEmoji).font(.title3); Text(profile.name).font(.subheadline.bold()) } }
                            ) {
                                if selectedProfileIds.contains(profile.id) {
                                    selectedProfileIds.remove(profile.id)
                                } else {
                                    selectedProfileIds.insert(profile.id)
                                }
                            }
                        }

                        if appState.profiles.isEmpty {
                            Text("No profiles yet.")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }

                    // Substances
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("SUBSTANCES USED")

                        ForEach(Substances.all, id: \.id) { substance in
                            toggleRow(
                                isSelected: selectedSubstanceIds.contains(substance.id),
                                label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: substance.category.icon)
                                            .foregroundStyle(Color(hex: substance.category.color))
                                            .frame(width: 20)
                                        Text(substance.name)
                                            .font(.subheadline.bold())
                                    }
                                }
                            ) {
                                if selectedSubstanceIds.contains(substance.id) {
                                    selectedSubstanceIds.remove(substance.id)
                                } else {
                                    selectedSubstanceIds.insert(substance.id)
                                }
                            }
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
                        .disabled(selectedProfileIds.isEmpty || selectedSubstanceIds.isEmpty)
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let activeId = appState.activeProfileId {
                    selectedProfileIds.insert(activeId)
                }
            }
            .sheet(isPresented: $showFeedback) {
                if let sessionId = savedSessionId {
                    SessionFeedbackView(sessionId: sessionId)
                        .environment(appState)
                }
            }
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .tracking(2)
            .foregroundStyle(.secondary)
    }

    private func toggleRow<Label: View>(isSelected: Bool, @ViewBuilder label: () -> Label, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accent : .secondary)
                label()
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Save

    private func saveSession() {
        let name = sessionName.trimmingCharacters(in: .whitespaces)
        let session = BallerSession(
            name: name.isEmpty ? "Manual Session" : name,
            participantIds: Array(selectedProfileIds),
            startedAt: startDate,
            endedAt: endDate,
            substanceIds: Array(selectedSubstanceIds)
        )
        appState.sessionHistory.insert(session, at: 0)

        // Create doses for each participant × substance at session start time
        for profileId in selectedProfileIds {
            for substanceId in selectedSubstanceIds {
                guard let substance = Substances.byId[substanceId] else { continue }
                let dose = Dose(
                    profileId: profileId,
                    substanceId: substanceId,
                    route: substance.primaryRoute,
                    amount: substance.commonDose,
                    timestamp: startDate
                )
                appState.doses.append(dose)
            }
        }

        // Persist
        if let data = try? JSONEncoder().encode(appState.sessionHistory) {
            UserDefaults.standard.set(data, forKey: "sessionHistory")
        }
        if let data = try? JSONEncoder().encode(appState.doses) {
            UserDefaults.standard.set(data, forKey: "doses")
        }

        savedSessionId = session.id
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showFeedback = true
        }
    }
}
