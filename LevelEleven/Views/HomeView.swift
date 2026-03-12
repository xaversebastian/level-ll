// HomeView.swift — LevelEleven
// v5.0 | 2026-03-12 17:18
// - 11-segment hero, flat content sections, safeAreaInset log button
// - Stripped legacy comments, added structured header
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
    @State private var showQuickDose = false
    @State private var showEmergency = false
    @State private var snoozedWarnings: [String: Date] = [:]
    @State private var timerCancellable: AnyCancellable?

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
        .onAppear {
            timerCancellable = Timer.publish(every: 10, on: .main, in: .common)
                .autoconnect()
                .sink { _ in currentTime = Date() }
        }
        .onDisappear {
            timerCancellable?.cancel()
        }
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
            .background(Color.accent.gradient, in: RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(.white)
            .shadow(color: Color.accent.opacity(0.2), radius: 8, y: 3)
        }
        .padding(.horizontal, DS.screenPadding)
        .padding(.vertical, 12)
        .background(.regularMaterial)
    }

    // MARK: - Main Content

    private func mainContent(_ profile: Profile, topInset: CGFloat = 0) -> some View {
        let level = appState.currentLevel(for: profile, at: currentTime)
        let color = appState.levelColor(for: level)
        let activeDoses = appState.activeDoses(for: profile.id, at: currentTime)
        let active = appState.activeDoses(for: profile.id, at: currentTime)
        let allDoses = appState.recentDoses(for: profile.id, hours: 8)
        let allWarnings = WarningSystem.checkInteractions(activeDoses: active, allDoses: allDoses, profile: profile, now: currentTime)
        let warnings = allWarnings.filter { w in
            guard let snoozeUntil = snoozedWarnings[w.title] else { return true }
            return currentTime > snoozeUntil
        }

        return VStack(spacing: 0) {
            heroSection(profile: profile, level: level, color: color, topInset: topInset)

            // ── Flat content ──────────────────────────────────────────────

            // Limit warning
            if level >= Double(profile.personalLimit) {
                limitBanner(level: level, color: color)
            }

            // Warnings section
            if !activeDoses.isEmpty && !warnings.isEmpty {
                sectionHeader("Warning\(warnings.count > 1 ? "s (\(warnings.count))" : "")",
                              color: warnings.first?.severity == .danger ? .red : Color.levelOrange)
                ForEach(Array(warnings.prefix(3).enumerated()), id: \.element.title) { idx, warning in
                    if idx > 0 { thinDivider }
                    warningRow(warning)
                        .transition(.asymmetric(insertion: .slide.combined(with: .opacity), removal: .opacity))
                }
                .animation(.spring(duration: 0.3), value: warnings.count)
                if warnings.count > 3 {
                    Button { showWarnings = true } label: {
                        Text("+\(warnings.count - 3) more warnings")
                            .font(.caption.bold())
                            .foregroundStyle(Color.levelOrange)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, DS.screenPadding)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Session strip
            if let session = appState.activeSession {
                sessionStrip(session)
            }

            // Active substances
            let activeCount = activeDoses.count
            sectionHeader(activeCount > 0 ? "Active (\(activeCount))" : "Active", color: .secondary)
            if activeDoses.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.levelGreen)
                    Text("Nothing active — you're clear")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DS.screenPadding)
                .padding(.vertical, 14)
            } else {
                ForEach(Array(activeDoses.enumerated()), id: \.element.id) { idx, dose in
                    if let substance = Substances.byId[dose.substanceId] {
                        if idx > 0 { thinDivider }
                        doseRow(dose: dose, substance: substance)
                            .transition(.asymmetric(insertion: .slide.combined(with: .opacity), removal: .scale.combined(with: .opacity)))
                    }
                }
                .animation(.spring(duration: 0.3), value: activeDoses.map(\.id))
            }

            Color.clear.frame(height: 20) // bottom breathing room
        }
    }

    // MARK: - Hero Section

    private func heroSection(profile: Profile, level: Double, color: Color, topInset: CGFloat = 0) -> some View {
        let minutesToSober = appState.minutesUntilBaseline(for: profile, from: currentTime)
        let soberText: String = {
            guard let min = minutesToSober, min > 0 else { return "Sober now" }
            let h = Int(min) / 60; let m = Int(min) % 60
            return h > 0 ? "~\(h)h \(m > 0 ? "\(m)m" : "")" : "~\(m)m"
        }()
        let isSober = minutesToSober == nil || minutesToSober == 0

        return VStack(alignment: .leading, spacing: 0) {

            // Top bar
            HStack(spacing: 10) {
                Text("LEVEL")
                    .font(.system(size: 11, weight: .black))
                    .tracking(3)
                    .foregroundStyle(.white.opacity(0.3))

                Spacer()

                Button { showEmergency = true } label: {
                    Text("SOS")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10).padding(.vertical, 5)
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
                        Text(safeEmoji(profile.avatarEmoji)).font(.system(size: 16))
                        Text(profile.name).font(.subheadline.bold())
                        Image(systemName: "chevron.down").font(.caption2).foregroundStyle(.white.opacity(0.4))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background(.white.opacity(0.1), in: Capsule())
                }
            }
            .padding(.horizontal, DS.screenPadding)
            .padding(.top, max(topInset, 54) + 8)
            .padding(.bottom, 18)

            // Level number
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(String(format: "%.1f", level))
                    .font(.system(size: 88, weight: .black, design: .rounded))
                    .foregroundStyle(color)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: level)
                Text("/ 11")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.2))
            }
            .padding(.horizontal, DS.screenPadding)

            // Description + sober time row
            Button { showTimeline = true } label: {
                HStack(alignment: .firstTextBaseline) {
                    Text(appState.levelDescription(for: level))
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    Spacer()
                    HStack(spacing: 4) {
                        Text(isSober ? "Sober" : "Sober in \(soberText)")
                            .font(.subheadline)
                            .foregroundStyle(isSober ? Color.levelGreen : .white.opacity(0.55))
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.25))
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, DS.screenPadding)
            .padding(.top, 4)
            .padding(.bottom, 16)

            // 11-segment indicator
            HStack(spacing: 5) {
                ForEach(1...11, id: \.self) { i in
                    Capsule()
                        .fill(i <= Int(level)
                              ? segmentColor(i)
                              : Color.white.opacity(0.08))
                        .frame(maxWidth: .infinity)
                        .frame(height: 5)
                        .animation(.easeInOut(duration: 0.2), value: i <= Int(level))
                }
            }
            .padding(.horizontal, DS.screenPadding)
            .padding(.bottom, 28)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.heroBackground)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .ignoresSafeArea(edges: .top)
    }

    /// Color for each of the 11 level segments (visual color ramp).
    private func segmentColor(_ i: Int) -> Color {
        switch i {
        case 1, 2:   return Color.levelGreen
        case 3, 4:   return Color(hex: "B5973A")
        case 5, 6:   return Color.levelOrange
        case 7, 8:   return Color.levelWarm
        default:     return Color.levelMauve
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String, color: Color = .secondary) -> some View {
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

    // MARK: - Warning Row

    private func warningRow(_ warning: Warning) -> some View {
        let calm = appState.calmMode
        let displayColor: Color = calm && warning.severity < .danger ? Color.levelCalm : warning.severity.color
        let displayIcon = calm && warning.severity < .danger ? "info.circle.fill" : warning.severity.icon

        return HStack(spacing: 14) {
            Button { showWarnings = true } label: {
                HStack(spacing: 14) {
                    Image(systemName: displayIcon)
                        .font(.body)
                        .foregroundStyle(displayColor)
                        .frame(width: 22)

                    Text(warning.title)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .pressFeedback()

            Button {
                snoozedWarnings[warning.title] = currentTime.addingTimeInterval(30 * 60)
            } label: {
                Image(systemName: "bell.slash")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 44, minHeight: 44)
                    .background(.secondary.opacity(0.1), in: Circle())
            }
            .buttonStyle(.plain)
            .pressFeedback()
        }
        .padding(.horizontal, DS.screenPadding)
        .padding(.vertical, 11)
        .background(Color.appBackground)
    }

    // MARK: - Session Strip

    private func sessionStrip(_ session: BallerSession) -> some View {
        Button { showBallerMode = true } label: {
            HStack(spacing: 10) {
                Circle().fill(.green).frame(width: 7, height: 7)
                Text(session.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.accent)
                Text("·")
                    .foregroundStyle(.secondary)
                Text("\(session.participantIds.count) people")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("·")
                    .foregroundStyle(.secondary)
                Text(session.durationFormatted)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, DS.screenPadding)
            .padding(.vertical, 12)
            .background(Color.accent.opacity(0.06))
        }
        .buttonStyle(.plain)
        .padding(.top, 10)
    }

    // MARK: - Dose Row

    private func doseRow(dose: Dose, substance: Substance) -> some View {
        let minutesAgo = dose.minutesAgo(from: currentTime)
        let progress = min(minutesAgo / substance.durationMinutes, 1.0)
        let remaining = max(0, substance.durationMinutes - minutesAgo)
        let catColor = Color(hex: substance.category.color)

        return HStack(spacing: 14) {
            // Left accent line
            RoundedRectangle(cornerRadius: 2)
                .fill(catColor)
                .frame(width: 3, height: 32)

            // Name + amount
            VStack(alignment: .leading, spacing: 2) {
                Text(substance.shortName)
                    .font(.subheadline.bold())
                Text("\(formatDoseAmount(dose.amount, substance: substance)) · \(dose.route.displayName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Decay bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.secondary.opacity(0.12))
                    Capsule()
                        .fill(catColor)
                        .frame(width: geo.size.width * (1 - progress))
                }
            }
            .frame(width: 60, height: 4)

            // Time remaining
            Text("\(Int(remaining))m")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 34, alignment: .trailing)

            // Delete button
            Button {
                withAnimation(.easeOut(duration: 0.2)) { appState.deleteDose(dose.id) }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary.opacity(0.3))
                    .frame(minWidth: 44, minHeight: 44)
            }
            .buttonStyle(.plain)
            .pressFeedback()
        }
        .padding(.horizontal, DS.screenPadding)
        .padding(.vertical, 10)
        .background(Color.appBackground)
        .contentShape(Rectangle())
        .pressFeedback()
        .contextMenu {
            Button(role: .destructive) {
                withAnimation(.easeOut(duration: 0.2)) { appState.deleteDose(dose.id) }
            } label: {
                Label("Delete Dose", systemImage: "trash")
            }
        }
    }

    // MARK: - Limit Banner

    private func limitBanner(level: Double, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text("Personal limit reached (\(String(format: "%.1f", level)) / \(appState.activeProfile?.personalLimit ?? 7))")
                .font(.subheadline.bold())
                .foregroundStyle(.red)
            Spacer()
        }
        .padding(.horizontal, DS.screenPadding)
        .padding(.vertical, 10)
        .background(.red.opacity(0.08))
    }

    // MARK: - Thin Divider

    private var thinDivider: some View {
        Divider().padding(.leading, 54)
    }

    // MARK: - Helpers

    private func formatDoseAmount(_ amount: Double, substance: Substance) -> String {
        let unit = substance.unit.symbol
        if amount < 1        { return String(format: "%.2f%@", amount, unit) }
        if amount == floor(amount) { return String(format: "%.0f%@", amount, unit) }
        return String(format: "%.1f%@", amount, unit)
    }

    private func safeEmoji(_ emoji: String) -> String {
        let broken: Set<String> = ["\u{1F9D1}", "\u{1F469}", "\u{1F468}", "\u{1FAF1}"]
        if emoji.isEmpty || broken.contains(emoji) { return "😊" }
        return emoji
    }

    // MARK: - No Profile

    private var noProfileView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 48)).foregroundStyle(.secondary)
            Text("No active profile").font(.headline)
            Text("Go to Profiles to create one")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        .padding(60)
    }

    // MARK: - Sheets

    private var warningsSheet: some View {
        NavigationStack {
            ScrollView { WarningsView().padding() }
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
    HomeView().environment(AppState())
}
