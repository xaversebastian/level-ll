//
//  HomeView.swift
//  LevelEleven
//
//  Version: 2.0  |  2026-03-12
//
//  Radikaler Umbau: dunkler Navy-Hero, floating „Log Dose" CTA, SOS-Chip,
//  Sober-Time direkt im Hero. lastDoseCard und liveStatusCard entfernt (redundant).
//  Warnings nur sichtbar wenn aktive Doses vorhanden.
//  „Log Dose" öffnet BallerModeView bei aktiver Session, sonst QuickDoseView.

import SwiftUI
import Combine

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var currentTime = Date()
    @State private var showWarnings = false
    @State private var showProfilePicker = false
    @State private var showTimeline = false
    @State private var showBallerMode = false
    @State private var showQuickDose = false
    @State private var showEmergency = false
    // Snooze: [warningTitle: snoozeUntil]
    @State private var snoozedWarnings: [String: Date] = [:]

    let timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack(alignment: .bottom) {
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
            .background(Color.appBackground.ignoresSafeArea())

            // Floating Log Dose CTA
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                if appState.activeSession != nil {
                    showBallerMode = true
                } else {
                    showQuickDose = true
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: appState.activeSession != nil ? "person.3.fill" : "plus")
                        .font(.body.bold())
                    Text(appState.activeSession != nil ? "Open Session" : "Log Dose")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color.accent.gradient, in: RoundedRectangle(cornerRadius: 16))
                .foregroundStyle(.white)
                .shadow(color: Color.accent.opacity(0.35), radius: 12, y: 6)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 104)
        }
        .onReceive(timer) { _ in currentTime = Date() }
        .sheet(isPresented: $showQuickDose) {
            QuickDoseView()
                .environment(appState)
        }
        .sheet(isPresented: $showEmergency) {
            EmergencyView()
        }
        .sheet(isPresented: $showWarnings) {
            warningsSheet.environment(appState)
        }
        .sheet(isPresented: $showProfilePicker) {
            profilePickerSheet.environment(appState)
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

    // MARK: - Main Content

    private func mainContent(_ profile: Profile, topInset: CGFloat = 0) -> some View {
        let level = appState.currentLevel(for: profile, at: currentTime)
        let color = appState.levelColor(for: level)
        let activeDoses = appState.activeDoses(for: profile.id, at: currentTime)

        return VStack(spacing: 0) {
            heroSection(profile: profile, level: level, color: color, topInset: topInset)

            VStack(spacing: 12) {
                // Warnings: only when doses are active
                if !activeDoses.isEmpty {
                    warningsCard(profile)
                }

                // Session overview
                if appState.activeSession != nil {
                    sessionOverviewCard()
                }

                // Active substances
                activeSubstancesCard(profile)
            }
            .padding(.horizontal, 16)
            .padding(.top, -32)
            .padding(.bottom, 180)
        }
    }

    // MARK: - Hero Section (dark navy)

    private func heroSection(profile: Profile, level: Double, color: Color, topInset: CGFloat = 0) -> some View {
        let minutesToSober = appState.minutesUntilBaseline(for: profile, from: currentTime)

        let soberText: String = {
            guard let min = minutesToSober, min > 0 else { return "✓ Sober" }
            let h = Int(min) / 60
            let m = Int(min) % 60
            return h > 0 ? "Sober in ~\(h)h \(m > 0 ? "\(m)m" : "")" : "Sober in ~\(m)m"
        }()
        let soberColor: Color = minutesToSober == nil ? Color.levelGreen : (minutesToSober! > 120 ? .white.opacity(0.7) : Color.levelOrange)

        return VStack(spacing: 14) {
            // Safe area padding
            Color.clear.frame(height: topInset + 8)

            // Header row: logo | SOS | profile pill
            HStack(spacing: 10) {
                Image("level-logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 52)
                    .colorMultiply(.white)

                Spacer()

                // SOS emergency shortcut
                Button {
                    showEmergency = true
                } label: {
                    Text("SOS")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.red.gradient, in: Capsule())
                }

                // Profile pill
                Button {
                    if appState.profiles.count == 2,
                       let other = appState.profiles.first(where: { $0.id != appState.activeProfile?.id }) {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        appState.setActiveProfile(other)
                    } else {
                        showProfilePicker = true
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(profile.avatarEmoji)
                            .font(.body)
                        Text(profile.name)
                            .font(.subheadline.bold())
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.12), in: Capsule())
                }
            }
            .padding(.horizontal, 20)

            // Level Gauge — tappable → timeline
            Button {
                showTimeline = true
            } label: {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 200, height: 200)
                        .blur(radius: 24)
                    LevelGaugeView(level: level, color: color)
                }
            }
            .buttonStyle(.plain)

            // Level description + sober time
            VStack(spacing: 6) {
                Text(appState.levelDescription(for: level))
                    .font(.title2.bold())
                    .foregroundStyle(color)

                Text(soberText)
                    .font(.subheadline)
                    .foregroundStyle(soberColor)
            }

            // Limit warning
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
        .padding(.bottom, 48)
        .background(Color.heroBackground)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Warnings Card

    private func warningsCard(_ profile: Profile) -> some View {
        let active = appState.activeDoses(for: profile.id, at: currentTime)
        let allDoses = appState.recentDoses(for: profile.id, hours: 8)
        let allWarnings = WarningSystem.checkInteractions(activeDoses: active, allDoses: allDoses, profile: profile, now: currentTime)
        let warnings = allWarnings.filter { warning in
            guard let snoozeUntil = snoozedWarnings[warning.title] else { return true }
            return currentTime > snoozeUntil
        }
        let calm = appState.calmMode

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
                            let displayColor: Color = calm && topWarning.severity < .danger
                                ? Color.levelCalm : topWarning.severity.color
                            let displayIcon: String = calm && topWarning.severity < .danger
                                ? "info.circle.fill" : topWarning.severity.icon

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
                        .foregroundStyle(Color.levelGreen)
                    Text(calm ? "All good" : "No interaction warnings")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.secondary.opacity(0.12), lineWidth: 1))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }

    // MARK: - Active Substances Card

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
                        .foregroundStyle(Color.levelGreen)
                    Text("Nothing active")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(active.enumerated()), id: \.element.id) { idx, dose in
                        if let substance = Substances.byId[dose.substanceId] {
                            if idx > 0 {
                                Divider().padding(.leading, 18)
                            }
                            compactDoseRow(dose: dose, substance: substance)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.secondary.opacity(0.1), lineWidth: 1))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }

    // MARK: - Compact Dose Row

    private func compactDoseRow(dose: Dose, substance: Substance) -> some View {
        let minutesAgo = dose.minutesAgo(from: currentTime)
        let progress = min(minutesAgo / substance.durationMinutes, 1.0)
        let remaining = max(0, substance.durationMinutes - minutesAgo)
        let color = Color(hex: substance.category.color)

        return HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(substance.shortName)
                    .font(.subheadline)
                Text("\(formatDoseAmount(dose.amount, substance: substance)) · \(dose.route.displayName)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.secondary.opacity(0.15))
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * (1 - progress))
                }
            }
            .frame(width: 80, height: 6)

            Text("\(Int(remaining))m")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .trailing)

            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    appState.deleteDose(dose.id)
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary.opacity(0.4))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button(role: .destructive) {
                withAnimation(.easeOut(duration: 0.2)) {
                    appState.deleteDose(dose.id)
                }
            } label: {
                Label("Delete Dose", systemImage: "trash")
            }
        }
    }

    private func formatDoseAmount(_ amount: Double, substance: Substance) -> String {
        let unit = substance.unit.symbol
        if amount < 1 {
            return String(format: "%.2f%@", amount, unit)
        } else if amount == floor(amount) {
            return String(format: "%.0f%@", amount, unit)
        } else {
            return String(format: "%.1f%@", amount, unit)
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
                            Circle().fill(.green).frame(width: 6, height: 6)
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
                            if let p = appState.profiles.first(where: { $0.id == profileId }) {
                                let lvl = appState.currentLevel(for: p, at: currentTime)
                                let col = appState.levelColor(for: lvl)
                                VStack(spacing: 4) {
                                    ZStack {
                                        Circle()
                                            .fill(col.opacity(0.15))
                                            .frame(width: 36, height: 36)
                                        Text(p.avatarEmoji)
                                            .font(.body)
                                    }
                                    Text(String(format: "%.1f", lvl))
                                        .font(.caption.bold())
                                        .foregroundStyle(col)
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
                .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - No Profile View

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

    // MARK: - Sheets

    private var warningsSheet: some View {
        NavigationStack {
            ScrollView {
                WarningsView().padding()
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
                            Text(profile.avatarEmoji).font(.title2)
                            Text(profile.name).font(.body)
                            Spacer()
                            if profile.id == appState.activeProfile?.id {
                                Image(systemName: "checkmark").foregroundStyle(Color.accent)
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
