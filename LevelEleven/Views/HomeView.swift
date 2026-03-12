//
//  HomeView.swift
//  LevelEleven
//
//  Version: 3.0  |  2026-03-12
//
//  Komplett neu gedacht: Kein Ring-Gauge mehr. Kompakter Hero mit großer
//  Level-Zahl + horizontalem Fortschrittsbalken. Sticky Log-Dose-Button
//  via safeAreaInset (kein Overlap mehr). Saubere Card-Struktur darunter.

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
        .background(Color.appBackground.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            logDoseButton
        }
        .onReceive(timer) { _ in currentTime = Date() }
        .sheet(isPresented: $showQuickDose) {
            QuickDoseView().environment(appState)
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
            BallerModeView().environment(appState)
        }
    }

    // MARK: - Sticky Log Dose Button

    private var logDoseButton: some View {
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
            .shadow(color: Color.accent.opacity(0.25), radius: 10, y: 3)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.regularMaterial)
    }

    // MARK: - Main Content

    private func mainContent(_ profile: Profile, topInset: CGFloat = 0) -> some View {
        let level = appState.currentLevel(for: profile, at: currentTime)
        let color = appState.levelColor(for: level)
        let activeDoses = appState.activeDoses(for: profile.id, at: currentTime)

        return VStack(spacing: 0) {
            heroSection(profile: profile, level: level, color: color, topInset: topInset)

            VStack(spacing: 10) {
                if !activeDoses.isEmpty {
                    warningsCard(profile)
                }
                if appState.activeSession != nil {
                    sessionOverviewCard()
                }
                activeSubstancesCard(profile)
            }
            .padding(.horizontal, 16)
            .padding(.top, -20)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Hero Section

    private func heroSection(profile: Profile, level: Double, color: Color, topInset: CGFloat = 0) -> some View {
        let minutesToSober = appState.minutesUntilBaseline(for: profile, from: currentTime)

        let soberText: String = {
            guard let min = minutesToSober, min > 0 else { return "Sober now" }
            let h = Int(min) / 60
            let m = Int(min) % 60
            return h > 0 ? "Sober in ~\(h)h \(m > 0 ? "\(m)m" : "")" : "Sober in ~\(m)m"
        }()
        let soberColor: Color = minutesToSober == nil
            ? Color.levelGreen
            : (minutesToSober! > 120 ? .white.opacity(0.55) : Color.levelOrange)

        return VStack(alignment: .leading, spacing: 0) {

            // ── Top bar ───────────────────────────────────────────
            HStack(spacing: 10) {
                Text("LEVEL")
                    .font(.system(size: 11, weight: .black))
                    .tracking(3)
                    .foregroundStyle(.white.opacity(0.35))

                Spacer()

                Button { showEmergency = true } label: {
                    Text("SOS")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.red.gradient, in: Capsule())
                }

                Button {
                    if appState.profiles.count == 2,
                       let other = appState.profiles.first(where: { $0.id != appState.activeProfile?.id }) {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        appState.setActiveProfile(other)
                    } else {
                        showProfilePicker = true
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(safeEmoji(profile.avatarEmoji))
                            .font(.system(size: 16))
                        Text(profile.name)
                            .font(.subheadline.bold())
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(.white.opacity(0.1), in: Capsule())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, topInset + 16)
            .padding(.bottom, 20)

            // ── Level number + description ─────────────────────────
            Button { showTimeline = true } label: {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        Text(String(format: "%.1f", level))
                            .font(.system(size: 88, weight: .black, design: .rounded))
                            .foregroundStyle(color)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: level)

                        Text("/ 11")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.25))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(appState.levelDescription(for: level))
                            .font(.title3.bold())
                            .foregroundStyle(.white)

                        Text(soberText)
                            .font(.subheadline)
                            .foregroundStyle(soberColor)
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)

            // ── Progress bar ───────────────────────────────────────
            levelBar(progress: level / 11.0, color: color)
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 28)

            // ── Limit warning ──────────────────────────────────────
            if level >= Double(profile.personalLimit) {
                Label("Personal limit reached", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(.red.gradient, in: Capsule())
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.heroBackground)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .ignoresSafeArea(edges: .top)
    }

    private func levelBar(progress: Double, color: Color) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.08))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.6), color],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * CGFloat(min(max(progress, 0), 1)))
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
            }
        }
        .frame(height: 5)
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

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(calm ? "Keep in Mind" : "Warnings",
                      systemImage: calm ? "info.circle" : "exclamationmark.shield")
                    .font(.subheadline.bold())
                Spacer()
                if warnings.count > 0 {
                    Text("\(warnings.count)")
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.levelOrange.opacity(0.15), in: Capsule())
                        .foregroundStyle(Color.levelOrange)
                }
            }

            if let topWarning = warnings.first {
                HStack(spacing: 12) {
                    Button { showWarnings = true } label: {
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
        .background(.background, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: DS.cardRadius).strokeBorder(.primary.opacity(DS.borderOpacity), lineWidth: 1))
        .shadow(color: DS.shadowColor, radius: DS.shadowRadius, y: DS.shadowY)
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
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.secondary.opacity(0.12), in: Capsule())
                    .foregroundStyle(.secondary)
            }

            if active.isEmpty {
                HStack(spacing: 10) {
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
        .background(.background, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: DS.cardRadius).strokeBorder(.primary.opacity(DS.borderOpacity), lineWidth: 1))
        .shadow(color: DS.shadowColor, radius: DS.shadowRadius, y: DS.shadowY)
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
                    Capsule().fill(.secondary.opacity(0.12))
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * (1 - progress))
                }
            }
            .frame(width: 72, height: 5)

            Text("\(Int(remaining))m")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .trailing)
                .monospacedDigit()

            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    appState.deleteDose(dose.id)
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 17))
                    .foregroundStyle(.secondary.opacity(0.35))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 5)
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
            Button { showBallerMode = true } label: {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        HStack(spacing: 6) {
                            Circle().fill(.green).frame(width: 6, height: 6)
                            Text("Live")
                                .font(.caption2.bold())
                                .foregroundStyle(.green)
                        }
                        Text(session.name)
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.accent)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    HStack(spacing: 10) {
                        ForEach(session.participantIds, id: \.self) { profileId in
                            if let p = appState.profiles.first(where: { $0.id == profileId }) {
                                let lvl = appState.currentLevel(for: p, at: currentTime)
                                let col = appState.levelColor(for: lvl)
                                participantChip(p, level: lvl, color: col)
                            }
                        }
                        Spacer()
                    }
                }
                .padding(14)
                .background(.background, in: RoundedRectangle(cornerRadius: DS.cardRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.cardRadius)
                        .strokeBorder(Color.accent.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: DS.shadowColor, radius: DS.shadowRadius, y: DS.shadowY)
            }
            .buttonStyle(.plain)
        }
    }

    private func participantChip(_ profile: Profile, level: Double, color: Color) -> some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 32, height: 32)
                Text(safeEmoji(profile.avatarEmoji))
                    .font(.system(size: 16))
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(profile.name)
                    .font(.caption2.bold())
                    .foregroundStyle(.primary)
                Text(String(format: "%.1f", level))
                    .font(.caption.bold())
                    .foregroundStyle(color)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(color.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Helpers

    /// Returns a guaranteed-renderable emoji, falling back to "😊".
    private func safeEmoji(_ emoji: String) -> String {
        let known: Set<String> = ["\u{1F9D1}", "\u{1F469}", "\u{1F468}", "\u{1FAF1}"]
        if emoji.isEmpty || known.contains(emoji) { return "😊" }
        return emoji
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
                            Text(safeEmoji(profile.avatarEmoji)).font(.title2)
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
