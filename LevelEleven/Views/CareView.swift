// CareView.swift — LevelEleven
// v1.0 | 2026-03-16
// - Always-visible Care tab: in-session tips, normalization, aftercare, wellbeing
//

import SwiftUI
import Combine

struct CareView: View {
    @Environment(AppState.self) private var appState
    @State private var currentTime = Date()
    @State private var showCheckInSheet = false

    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    private var profile: Profile? { appState.activeProfile }

    private var activeSubstanceIds: Set<String> {
        guard let profile else { return [] }
        return Set(appState.activeDoses(for: profile.id, at: currentTime).map { $0.substanceId })
    }

    private var hasActiveSession: Bool { appState.activeSession != nil }

    private var aftercareState: AftercareState { appState.aftercareState }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Active In-Session Section
                    if !activeSubstanceIds.isEmpty {
                        inSessionSection
                    }

                    // Normalization Section — always visible
                    normalizationSection

                    // Aftercare Section
                    if aftercareState.isActive {
                        aftercareSection
                    }

                    // Wellbeing Check-in
                    if aftercareState.isActive {
                        checkInSection
                    }

                    // Idle state when nothing is happening
                    if activeSubstanceIds.isEmpty && !aftercareState.isActive {
                        idleSection
                    }
                }
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Care")
            .onReceive(timer) { currentTime = $0 }
            .sheet(isPresented: $showCheckInSheet) {
                AftercareCheckInSheet(aftercareState: appState.aftercareState) { checkIn in
                    appState.aftercareState.checkInHistory.append(checkIn)
                }
            }
        }
    }

    // MARK: - In-Session Tips

    private var inSessionSection: some View {
        VStack(spacing: 0) {
            sectionHeader("In-Session Care", icon: "heart.circle.fill", color: .levelCopper)

            let tips = AftercareEngine.inSessionTips(for: activeSubstanceIds)
            let activeNames = activeSubstanceIds.compactMap { Substances.byId[$0]?.shortName }.joined(separator: ", ")

            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color.levelGreen)
                        .frame(width: 8, height: 8)
                    Text("Active: \(activeNames)")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, DS.screenPadding)
                .padding(.vertical, 10)

                ForEach(Array(tips.enumerated()), id: \.offset) { idx, tip in
                    if idx > 0 { Divider().padding(.leading, 50) }
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundStyle(Color.accent)
                            .frame(width: 22)
                            .padding(.top, 2)
                        Text(tip)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .lineSpacing(3)
                        Spacer()
                    }
                    .padding(.horizontal, DS.screenPadding)
                    .padding(.vertical, 8)
                }

                if tips.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("No specific tips for your active substances right now.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, DS.screenPadding)
                    .padding(.vertical, 12)
                }
            }
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, DS.screenPadding)
        }
    }

    // MARK: - Normalization Section

    private var normalizationSection: some View {
        VStack(spacing: 0) {
            sectionHeader("Normalization Tips", icon: "arrow.down.heart.fill", color: .orange)

            VStack(spacing: 0) {
                Text("What to do when effects are too strong")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DS.screenPadding)
                    .padding(.top, 12)
                    .padding(.bottom, 6)

                ForEach(Array(AftercareEngine.normalizationTips.enumerated()), id: \.element.id) { idx, tip in
                    if idx > 0 { Divider().padding(.leading, 50) }
                    normalizationRow(tip, isActive: activeSubstanceIds.contains(tip.id))
                }
            }
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, DS.screenPadding)
        }
    }

    @State private var expandedNormTip: String?

    private func normalizationRow(_ tip: AftercareEngine.NormalizationTip, isActive: Bool) -> some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedNormTip = expandedNormTip == tip.id ? nil : tip.id
                }
            } label: {
                HStack(spacing: 12) {
                    let substance = Substances.byId[tip.id]
                    Image(systemName: substance?.category.icon ?? "pill.fill")
                        .foregroundStyle(isActive ? Color.orange : Color(hex: substance?.category.color ?? "#888"))
                        .frame(width: 22)
                    Text(tip.substanceName)
                        .font(.subheadline.bold())
                        .foregroundStyle(isActive ? .primary : .secondary)
                    Spacer()
                    if isActive {
                        Text("ACTIVE")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15), in: Capsule())
                    }
                    Image(systemName: expandedNormTip == tip.id ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, DS.screenPadding)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)

            if expandedNormTip == tip.id {
                Text(tip.tips)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
                    .padding(.horizontal, DS.screenPadding)
                    .padding(.bottom, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Aftercare Section

    private var aftercareSection: some View {
        VStack(spacing: 0) {
            sectionHeader("Aftercare", icon: "clock.badge.checkmark.fill", color: .levelGreen)

            let hints = AftercareEngine.hintsForSubstances(
                aftercareState.lastSessionSubstances,
                hoursSinceSession: aftercareState.hoursSinceSession,
                daysSinceSession: aftercareState.daysSinceSession
            )

            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)
                        .frame(width: 22)
                    let dayText = aftercareState.daysSinceSession == 0 ? "Today" : "Day \(aftercareState.daysSinceSession)"
                    Text("\(dayText) after session")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Spacer()
                    let substances = aftercareState.lastSessionSubstances.compactMap { Substances.byId[$0]?.shortName }.joined(separator: ", ")
                    Text(substances)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, DS.screenPadding)
                .padding(.vertical, 10)

                if hints.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("No new recovery tips right now. Keep taking care of yourself!")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, DS.screenPadding)
                    .padding(.vertical, 12)
                } else {
                    ForEach(Array(hints.enumerated()), id: \.element.id) { idx, hint in
                        if idx > 0 { Divider().padding(.leading, 50) }
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: hint.category.icon)
                                .foregroundStyle(Color.levelGreen)
                                .frame(width: 22)
                                .padding(.top, 2)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(hint.title)
                                    .font(.subheadline.bold())
                                Text(hint.message)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineSpacing(3)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, DS.screenPadding)
                        .padding(.vertical, 10)
                    }
                }
            }
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, DS.screenPadding)
        }
    }

    // MARK: - Check-in Section

    private var checkInSection: some View {
        VStack(spacing: 0) {
            sectionHeader("Wellbeing Check-in", icon: "chart.bar.doc.horizontal.fill", color: .levelTeal)

            VStack(spacing: 12) {
                let todayCheckIn = aftercareState.checkInHistory.first {
                    Calendar.current.isDateInToday($0.date)
                }

                if let checkIn = todayCheckIn {
                    HStack(spacing: 16) {
                        wellbeingIndicator("Mood", value: checkIn.mood, icon: "face.smiling")
                        wellbeingIndicator("Energy", value: checkIn.energyLevel, icon: "bolt.fill")
                        wellbeingIndicator("Sleep", value: checkIn.sleepQuality, icon: "moon.zzz.fill")
                    }
                    .padding(.horizontal, DS.screenPadding)
                    .padding(.vertical, 12)

                    Text("Today's check-in complete ✓")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .padding(.bottom, 8)
                } else {
                    Button {
                        showCheckInSheet = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Color.accent)
                            Text("Log today's wellbeing check-in")
                                .font(.subheadline.bold())
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, DS.screenPadding)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                    .pressFeedback()
                }

                // History summary
                if aftercareState.checkInHistory.count > 1 {
                    Divider().padding(.leading, 50)
                    HStack(spacing: 10) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundStyle(.secondary)
                            .frame(width: 22)
                        Text("\(aftercareState.checkInHistory.count) check-ins logged")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, DS.screenPadding)
                    .padding(.vertical, 8)
                }
            }
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, DS.screenPadding)
        }
    }

    private func wellbeingIndicator(_ label: String, value: Int, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(wellbeingColor(value))
            Text("\(value)/5")
                .font(.headline.monospacedDigit())
                .foregroundStyle(wellbeingColor(value))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func wellbeingColor(_ value: Int) -> Color {
        switch value {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .green.opacity(0.8)
        case 5: return .green
        default: return .secondary
        }
    }

    // MARK: - Idle Section

    private var idleSection: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 40)
            VStack(spacing: 16) {
                Image(systemName: "heart.text.clipboard.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.accent.opacity(0.3))
                Text("All Clear")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                Text("No active substances or recent sessions.\nNormalization tips are always available below.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
            }
            .padding(.horizontal, DS.screenPadding)
            .padding(.vertical, 30)
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
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
}

// MARK: - Aftercare Check-In Sheet

struct AftercareCheckInSheet: View {
    let aftercareState: AftercareState
    let onSave: (AftercareCheckIn) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var mood = 3
    @State private var energy = 3
    @State private var sleep = 3
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text("How are you feeling today?")
                        .font(.title3.bold())
                        .padding(.top, 20)

                    ratingRow("Mood", value: $mood, icon: "face.smiling",
                              labels: ["Terrible", "Bad", "Okay", "Good", "Great"])
                    ratingRow("Energy", value: $energy, icon: "bolt.fill",
                              labels: ["Exhausted", "Low", "Normal", "Good", "High"])
                    ratingRow("Sleep Quality", value: $sleep, icon: "moon.zzz.fill",
                              labels: ["None", "Poor", "Fair", "Good", "Excellent"])

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes (optional)")
                            .font(.subheadline.bold())
                        TextField("How are you feeling?", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                            .padding(12)
                            .background(Color.surfaceSecondary, in: RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.horizontal, DS.screenPadding)
                }
            }
            .background(Color.appBackground)
            .navigationTitle("Wellbeing Check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let checkIn = AftercareCheckIn(
                            mood: mood,
                            energyLevel: energy,
                            sleepQuality: sleep,
                            notes: notes,
                            daysAfterSession: aftercareState.daysSinceSession
                        )
                        onSave(checkIn)
                        dismiss()
                    }
                    .bold()
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func ratingRow(_ title: String, value: Binding<Int>, icon: String, labels: [String]) -> some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(Color.accent)
                Text(title)
                    .font(.subheadline.bold())
                Spacer()
                Text(labels[value.wrappedValue - 1])
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 6) {
                ForEach(1...5, id: \.self) { i in
                    Button {
                        value.wrappedValue = i
                    } label: {
                        Circle()
                            .fill(i <= value.wrappedValue ? Color.accent : Color.secondary.opacity(0.2))
                            .frame(width: 36, height: 36)
                            .overlay {
                                Text("\(i)")
                                    .font(.caption.bold())
                                    .foregroundStyle(i <= value.wrappedValue ? .white : .secondary)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, DS.screenPadding)
        .padding(.vertical, 6)
    }
}

#Preview {
    CareView()
        .environment(AppState())
}
