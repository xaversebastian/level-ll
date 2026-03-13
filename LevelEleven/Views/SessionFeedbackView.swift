// SessionFeedbackView.swift — LevelEleven
// v1.0 | 2026-03-12 17:18
// - Post-session feedback sheet (deferrable)
// - Star rating, mood picker, side effects, notes
// - Can be triggered after session end or from session history
//

import SwiftUI

struct SessionFeedbackView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let sessionId: String

    @State private var rating = 3
    @State private var selectedMood = "😊"
    @State private var selectedSideEffects: Set<String> = []
    @State private var notes = ""
    @State private var acceptedAdjustments: [String: Int] = [:]

    private var session: BallerSession? {
        appState.sessionHistory.first { $0.id == sessionId }
    }

    private var substancesUsed: [String] {
        guard let session else { return [] }
        let sDoses = appState.sessionDoses(for: session)
        return Array(Set(sDoses.map { $0.substanceId }))
    }

    private var peakLevelPerSubstance: [String: Double] {
        guard let session else { return [:] }
        let sDoses = appState.sessionDoses(for: session)
        var peaks: [String: Double] = [:]
        let endTime = session.endedAt ?? Date()

        for substanceId in substancesUsed {
            let substanceDoses = sDoses.filter { $0.substanceId == substanceId }
            guard let substance = Substances.byId[substanceId] else { continue }
            var maxLevel: Double = 0
            // Sample across the session to find peak per substance
            var time = session.startedAt
            while time <= endTime {
                var level: Double = 0
                for dose in substanceDoses {
                    let minutesAgo = time.timeIntervalSince(dose.timestamp) / 60
                    guard minutesAgo >= 0 else { continue }
                    let profile = appState.profiles.first { $0.id == dose.profileId }
                    if let profile {
                        level += appState.calculateIntensity(dose: dose, substance: substance, minutesAgo: minutesAgo, profile: profile)
                    }
                }
                maxLevel = max(maxLevel, level)
                time = time.addingTimeInterval(5 * 60)
            }
            peaks[substanceId] = min(11, maxLevel)
        }
        return peaks
    }

    private var suggestedAdjustments: [String: Int] {
        SessionFeedback.suggestToleranceAdjustments(
            rating: rating,
            sideEffects: selectedSideEffects,
            substancesUsed: substancesUsed,
            peakLevelPerSubstance: peakLevelPerSubstance
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                    ratingSection
                    moodSection
                    sideEffectsSection
                    toleranceSuggestionSection
                    notesSection
                }
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Session Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Later") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        submitFeedback()
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            if let session {
                Text(session.name)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                HStack(spacing: 16) {
                    Label(session.durationFormatted, systemImage: "clock")
                    Label("\(session.allParticipantIds.count) people", systemImage: "person.2")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Text("How was the session?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, DS.screenPadding)
    }

    // MARK: - Rating

    private var ratingSection: some View {
        VStack(spacing: 0) {
            sectionHeader("Overall Rating", color: Color.accent)
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        withAnimation(.spring(response: 0.2)) { rating = star }
                    } label: {
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .font(.title)
                            .foregroundStyle(star <= rating ? Color.accent : .secondary.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, DS.screenPadding)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Mood

    private var moodSection: some View {
        VStack(spacing: 0) {
            sectionHeader("Mood", color: .secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(SessionFeedback.moodOptions, id: \.self) { mood in
                        Button {
                            selectedMood = mood
                        } label: {
                            Text(mood)
                                .font(.system(size: 32))
                                .frame(width: 52, height: 52)
                                .background(
                                    selectedMood == mood
                                        ? Color.accent.opacity(0.15)
                                        : Color.secondary.opacity(0.08),
                                    in: RoundedRectangle(cornerRadius: 12)
                                )
                                .overlay(
                                    selectedMood == mood
                                        ? RoundedRectangle(cornerRadius: 12).stroke(Color.accent, lineWidth: 2)
                                        : nil
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, DS.screenPadding)
            }
            .padding(.vertical, 12)
        }
    }

    // MARK: - Side Effects

    private var sideEffectsSection: some View {
        VStack(spacing: 0) {
            sectionHeader("Side Effects", color: .secondary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(SessionFeedback.sideEffectOptions, id: \.self) { effect in
                    Button {
                        if selectedSideEffects.contains(effect) {
                            selectedSideEffects.remove(effect)
                        } else {
                            if effect == "None" {
                                selectedSideEffects = ["None"]
                            } else {
                                selectedSideEffects.remove("None")
                                selectedSideEffects.insert(effect)
                            }
                        }
                    } label: {
                        Text(effect)
                            .font(.caption.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                selectedSideEffects.contains(effect)
                                    ? Color.accent.opacity(0.15)
                                    : Color.secondary.opacity(0.08),
                                in: RoundedRectangle(cornerRadius: 10)
                            )
                            .foregroundStyle(
                                selectedSideEffects.contains(effect)
                                    ? Color.accent
                                    : .primary
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, DS.screenPadding)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Tolerance Suggestions

    private var toleranceSuggestionSection: some View {
        let suggestions = suggestedAdjustments
        return Group {
            if !suggestions.isEmpty {
                VStack(spacing: 0) {
                    sectionHeader("Tolerance Adjustment", color: .blue)

                    Text("Based on your feedback, we suggest adjusting your tolerance for future sessions:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, DS.screenPadding)
                        .padding(.bottom, 8)

                    ForEach(suggestions.sorted(by: { $0.key < $1.key }), id: \.key) { substanceId, delta in
                        if let substance = Substances.byId[substanceId] {
                            let isAccepted = acceptedAdjustments[substanceId] != nil
                            Button {
                                if isAccepted {
                                    acceptedAdjustments.removeValue(forKey: substanceId)
                                } else {
                                    acceptedAdjustments[substanceId] = delta
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: isAccepted ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(isAccepted ? .blue : .secondary)
                                    Circle()
                                        .fill(Color(hex: substance.category.color))
                                        .frame(width: 8, height: 8)
                                    Text(substance.shortName)
                                        .font(.subheadline.bold())
                                    Spacer()
                                    Text(delta > 0 ? "▲ Raise" : "▼ Lower")
                                        .font(.caption.bold())
                                        .foregroundStyle(delta > 0 ? .green : .orange)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            (delta > 0 ? Color.green : Color.orange).opacity(0.12),
                                            in: Capsule()
                                        )
                                }
                                .padding(.horizontal, DS.screenPadding)
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text("Accepting changes your tolerance level by 1, which affects future dose recommendations.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, DS.screenPadding)
                        .padding(.top, 6)
                }
                .onChange(of: suggestedAdjustments) { _, newSuggestions in
                    // Auto-accept all suggestions by default
                    acceptedAdjustments = newSuggestions
                }
                .onAppear {
                    acceptedAdjustments = suggestedAdjustments
                }
            }
        }
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(spacing: 0) {
            sectionHeader("Notes", color: .secondary)
            TextField("Anything else to note…", text: $notes, axis: .vertical)
                .font(.subheadline)
                .lineLimit(3...6)
                .padding(12)
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, DS.screenPadding)
                .padding(.vertical, 8)
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, color: Color) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 4, height: 16)
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(color)
            Spacer()
        }
        .padding(.horizontal, DS.screenPadding)
        .padding(.top, 22)
        .padding(.bottom, 8)
    }

    private func submitFeedback() {
        let feedback = SessionFeedback(
            overallRating: rating,
            mood: selectedMood,
            sideEffects: Array(selectedSideEffects),
            notes: notes.trimmingCharacters(in: .whitespaces),
            submittedAt: Date(),
            toleranceAdjustments: acceptedAdjustments.isEmpty ? nil : acceptedAdjustments
        )
        appState.submitFeedback(feedback, for: sessionId)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}

#Preview {
    SessionFeedbackView(sessionId: "test")
        .environment(AppState())
}
