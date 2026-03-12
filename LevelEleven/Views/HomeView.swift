//
//  HomeView.swift
//  LevelEleven
//
//  Version: 1.2  |  2026-03-12
//
//  Hauptscreen mit Level-Gauge-Hero, Profil-Picker, Warnungs-Card, aktive-Substanzen-Card
//  und Live-Status-Card (Level / Active / Phase).
//  Ein Timer aktualisiert alle 10 Sekunden currentTime, damit Level-Berechnung live bleibt.
//  Tipp auf Gauge öffnet Timeline-Sheet; Tipp auf Profil-Pill öffnet Profil-Wechsel-Sheet.
//
//  HINWEIS: Alle Level-Berechnungen laufen in AppState; HomeView ist rein deklarativ.
//  Bei Performance-Problemen: Timer-Intervall erhöhen oder Berechnungen in Task auslagern.
//
//  Author: Silja & Xaver
//  Created: 2026-01-04
//

import SwiftUI
import Combine

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var currentTime = Date()
    @State private var showWarnings = false
    @State private var showProfilePicker = false
    @State private var showTimeline = false
    @State private var showBallerMode = false
    // Snooze: [warningTitle: snoozeUntil]
    @State private var snoozedWarnings: [String: Date] = [:]

    let timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                if let profile = appState.activeProfile {
                    mainContent(profile, topInset: geo.safeAreaInsets.top)
                } else {
                    noProfileView
                }
            }
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
        }
        .ignoresSafeArea(edges: .top)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .sheet(isPresented: $showWarnings) {
            warningsSheet
                .environment(appState)
        }
        .sheet(isPresented: $showProfilePicker) {
            profilePickerSheet
                .environment(appState)
        }
        .sheet(isPresented: $showTimeline) {
            NavigationStack {
                TimelineView()
                    .environment(appState)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showTimeline = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showBallerMode) {
            BallerModeView()
                .environment(appState)
        }
    }

    private func mainContent(_ profile: Profile, topInset: CGFloat = 0) -> some View {
        let level = appState.currentLevel(for: profile, at: currentTime)
        let color = appState.levelColor(for: level)

        return VStack(spacing: 0) {
            // Hero Section - Level Display
            heroSection(profile: profile, level: level, color: color, topInset: topInset)

            // Content Cards
            VStack(spacing: 12) {
                lastDoseCard(profile)
                warningsCard(profile)
                if appState.activeSession != nil {
                    sessionOverviewCard()
                }
                activeSubstancesCard(profile)
                liveStatusCard(profile)
            }
            .padding(.horizontal, 16)
            .padding(.top, -40)
            .padding(.bottom, 100)
        }
    }

    private func heroSection(profile: Profile, level: Double, color: Color, topInset: CGFloat = 0) -> some View {
        VStack(spacing: 16) {
            // Safe area spacer
            Color.clear.frame(height: topInset + 60)

            // Header Row: Logo left, Profile right
            HStack {
                Image("level-logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 70)

                Spacer()

                // Profile pill - tappable to switch profile (1-tap toggle for 2 profiles)
                Button {
                    if appState.profiles.count == 2,
                       let other = appState.profiles.first(where: { $0.id != appState.activeProfile?.id }) {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        appState.setActiveProfile(other)
                    } else {
                        showProfilePicker = true
                    }
                } label: {
                    HStack(spacing: 10) {
                        Text(profile.avatarEmoji)
                            .font(.title2)
                        Text(profile.name)
                            .font(.headline)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                }
                .foregroundStyle(.primary)
            }
            .padding(.horizontal, 20)

            // Level Gauge - tappable to show timeline
            Button {
                showTimeline = true
            } label: {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 220, height: 220)
                        .blur(radius: 30)

                    LevelGaugeView(level: level, color: color)
                }
            }
            .buttonStyle(.plain)

            Spacer()
            // Description
            VStack(spacing: 4) {
                Text(appState.levelDescription(for: level))
                    .font(.title2.bold())
                    .foregroundStyle(color)

                Text("Limit: \(profile.personalLimit)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Limit Warning
            if level >= Double(profile.personalLimit) {
                Label("Personal limit reached", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.red.gradient, in: Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 60)
        .background(
            LinearGradient(
                colors: [color.opacity(0.15), Color(.systemGroupedBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func lastDoseCard(_ profile: Profile) -> some View {
        let summary = appState.lastDoseSummary(for: profile.id, now: currentTime)
        let last = appState.lastDose(for: profile.id, at: currentTime)

        return VStack(alignment: .leading, spacing: 12) {
            // Header row: "Last dose" left, "Substance • elapsed" right
            HStack {
                Label("Last dose", systemImage: "hourglass")
                    .font(.subheadline.bold())

                Spacer()

                Text("\(summary.substance) • \(summary.elapsed)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }

    private func warningsCard(_ profile: Profile) -> some View {
        let active = appState.activeDoses(for: profile.id, at: currentTime)
        let allDoses = appState.recentDoses(for: profile.id, hours: 8)
        let allWarnings = WarningSystem.checkInteractions(activeDoses: active, allDoses: allDoses, profile: profile, now: currentTime)
        let warnings = allWarnings.filter { warning in
            guard let snoozeUntil = snoozedWarnings[warning.title] else { return true }
            return currentTime > snoozeUntil
        }
        let hasActiveDoses = !active.isEmpty
        let calm = appState.calmMode && hasActiveDoses

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(calm ? "Keep in Mind" : "Warnings",
                      systemImage: calm ? "info.circle" : "exclamationmark.shield")
                    .font(.subheadline.bold())
                Spacer()
                if warnings.count > 0 {
                    Text("\(warnings.count)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.secondary.opacity(0.15), in: Capsule())
                }
            }

            if let topWarning = warnings.first {
                HStack(spacing: 12) {
                    Button {
                        showWarnings = true
                    } label: {
                        HStack(spacing: 12) {
                            // Calm mode: soften non-danger warnings
                            let displayColor: Color = {
                                if calm && topWarning.severity < .danger {
                                    return Color(hex: "7B9BB5")
                                }
                                return topWarning.severity.color
                            }()
                            let displayIcon: String = {
                                if calm && topWarning.severity < .danger {
                                    return "info.circle.fill"
                                }
                                return topWarning.severity.icon
                            }()

                            Image(systemName: displayIcon)
                                .font(.title3)
                                .foregroundStyle(displayColor)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(topWarning.title)
                                    .font(.subheadline.bold())
                                if warnings.count > 1 {
                                    Text("+\(warnings.count - 1) more")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)

                    // Snooze Button
                    Button {
                        snoozedWarnings[topWarning.title] = currentTime.addingTimeInterval(30 * 60)
                    } label: {
                        Image(systemName: "bell.slash")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .background(.secondary.opacity(0.1), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(calm ? "All good" : "No interaction warnings")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.secondary.opacity(0.12), lineWidth: 1)
        )
    }

    private func activeSubstancesCard(_ profile: Profile) -> some View {
        let active = appState.activeDoses(for: profile.id, at: currentTime)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Active", systemImage: "waveform.path.ecg")
                    .font(.subheadline.bold())
                Spacer()
                Text("\(active.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.secondary.opacity(0.15), in: Capsule())
            }

            if active.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("No active substances")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            } else {
                ForEach(active) { dose in
                    if let substance = Substances.byId[dose.substanceId] {
                        compactDoseRow(dose: dose, substance: substance)
                    }
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }

    private func compactDoseRow(dose: Dose, substance: Substance) -> some View {
        let minutesAgo = dose.minutesAgo(from: currentTime)
        let progress = min(minutesAgo / substance.durationMinutes, 1.0)
        let remaining = max(0, substance.durationMinutes - minutesAgo)

        return HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: substance.category.color))
                .frame(width: 8, height: 8)

            Text(substance.shortName)
                .font(.subheadline)

            Spacer()

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.secondary.opacity(0.15))
                    Capsule()
                        .fill(Color(hex: substance.category.color))
                        .frame(width: geo.size.width * (1 - progress))
                }
            }
            .frame(width: 60, height: 6)

            Text("\(Int(remaining))m")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .trailing)
        }
        .contextMenu {
            Button(role: .destructive) {
                appState.deleteDose(dose.id)
            } label: {
                Label("Delete Dose", systemImage: "trash")
            }
        }
    }

    // MARK: - Session Overview Card

    @ViewBuilder
    private func sessionOverviewCard() -> some View {
        if let session = appState.activeSession {
            Button {
                showBallerMode = true
            } label: {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label(session.name, systemImage: "person.3.fill")
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.accent)
                        Spacer()
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.green)
                                .frame(width: 6, height: 6)
                            Text("Live")
                                .font(.caption2.bold())
                                .foregroundStyle(.green)
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    HStack(spacing: 12) {
                        ForEach(session.participantIds, id: \.self) { profileId in
                            if let profile = appState.profiles.first(where: { $0.id == profileId }) {
                                let level = appState.currentLevel(for: profile, at: currentTime)
                                let color = appState.levelColor(for: level)
                                VStack(spacing: 4) {
                                    ZStack {
                                        Circle()
                                            .fill(color.opacity(0.15))
                                            .frame(width: 36, height: 36)
                                        Text(profile.avatarEmoji)
                                            .font(.body)
                                    }
                                    Text(String(format: "%.1f", level))
                                        .font(.caption.bold())
                                        .foregroundStyle(color)
                                }
                            }
                        }
                        Spacer()
                    }
                }
                .padding(14)
                .background(.background, in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.accent.opacity(0.25), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func liveStatusCard(_ profile: Profile) -> some View {
        let active = appState.activeDoses(for: profile.id, at: currentTime)
        let level = appState.currentLevel(for: profile, at: currentTime)
        let color = appState.levelColor(for: level)

        var maxEndTime: Double = 0
        var strongestPhase = "Idle"
        var strongestIntensity: Double = 0

        for dose in active {
            if let substance = Substances.byId[dose.substanceId] {
                let minutesAgo = dose.minutesAgo(from: currentTime)
                let remaining = substance.durationMinutes - minutesAgo
                if remaining > maxEndTime { maxEndTime = remaining }

                let ratio = minutesAgo / substance.durationMinutes
                let intensity = 1.0 - ratio
                if intensity > strongestIntensity {
                    strongestIntensity = intensity
                    if minutesAgo < substance.onsetMinutes {
                        strongestPhase = "Onset"
                    } else if minutesAgo < substance.peakMinutes {
                        strongestPhase = "Coming Up"
                    } else if minutesAgo < substance.peakMinutes + (substance.durationMinutes - substance.peakMinutes) * 0.3 {
                        strongestPhase = "Peak"
                    } else if minutesAgo < substance.durationMinutes * 0.7 {
                        strongestPhase = "Plateau"
                    } else {
                        strongestPhase = "Coming Down"
                    }
                }
            }
        }

        // Sobriety countdown via AppState (pharmacokinetically accurate)
        let minutesToSober = appState.minutesUntilBaseline(for: profile, from: currentTime)
        let soberText: String = {
            guard let min = minutesToSober, min > 0 else { return "✓ Sober" }
            let h = Int(min) / 60
            let m = Int(min) % 60
            return h > 0 ? "~\(h)h \(m)m" : "~\(m)m"
        }()
        let soberColor: Color = minutesToSober == nil ? .green : (minutesToSober! > 120 ? .primary : .orange)

        return HStack(spacing: 0) {
            VStack(spacing: 4) {
                Text(String(format: "%.1f", level))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                Text("Level")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 40)

            VStack(spacing: 4) {
                Text("\(active.count)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("Active")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 40)

            VStack(spacing: 4) {
                Text(soberText)
                    .font(.system(size: minutesToSober == nil ? 28 : 18, weight: .bold, design: .rounded))
                    .foregroundStyle(soberColor)
                Text(active.isEmpty ? "Sober" : strongestPhase)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }

    private var noProfileView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No active profile")
                .font(.headline)
            Text("Go to Profiles to create one")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(60)
    }

    private var warningsSheet: some View {
        NavigationStack {
            ScrollView {
                WarningsView()
                    .padding()
            }
            .navigationTitle("Warnings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showWarnings = false }
                }
            }
        }
    }

    private var profilePickerSheet: some View {
        NavigationStack {
            List {
                ForEach(appState.profiles) { profile in
                    Button {
                        appState.setActiveProfile(profile)
                        showProfilePicker = false
                    } label: {
                        HStack {
                            Text(profile.avatarEmoji)
                                .font(.title2)
                            Text(profile.name)
                                .font(.body)
                            Spacer()
                            if profile.id == appState.activeProfile?.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accent)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }
            .navigationTitle("Switch Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showProfilePicker = false }
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .environment(AppState())
}
