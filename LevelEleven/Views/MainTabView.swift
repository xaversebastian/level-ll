// MainTabView.swift — LevelEleven
// v3.0 | 2026-03-12 17:18
// - AppState now injected from LevelElevenApp (no longer created locally)
// - Stripped legacy comments, added structured header
//

import SwiftUI

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tag(0)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            CareView()
                .tag(1)
                .tabItem {
                    Label("Care", systemImage: "heart.text.clipboard.fill")
                }

            BallerModeView()
                .tag(2)
                .tabItem {
                    Label("Group", systemImage: "person.3.fill")
                }
                .badge(appState.activeSession != nil ? "●" : nil)

            EmergencyView()
                .tag(3)
                .tabItem {
                    Label("SOS", systemImage: "cross.fill")
                }
                .badge(appState.hasDangerWarning ? "!" : nil)

            MoreView()
                .tag(4)
                .tabItem {
                    Label("More", systemImage: "ellipsis")
                }
        }
        .tint(Color.accent)
    }
}

struct MoreView: View {
    @Environment(AppState.self) private var appState
    @State private var showOnboardingReview = false
    @State private var showExport = false
    @State private var showClearDosesConfirm = false
    @State private var showResetStep1 = false
    @State private var showResetStep2 = false
    @State private var resetConfirmText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if let profile = appState.activeProfile {
                        sectionHeader("Current Profile", color: Color.accent)
                        currentProfileSection(profile)
                    }
                    sectionHeader("Activity", color: Color.levelTeal)
                    activitySection
                    sectionHeader("Infos", color: .blue)
                    infosSection
                    sectionHeader("Settings", color: .secondary)
                    settingsSection
                    sectionHeader("Legal", color: .secondary)
                    legalSection
                }
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
            .background(Color.appBackground)
            .navigationTitle("More")
            .fullScreenCover(isPresented: $showOnboardingReview) {
                OnboardingView(isReviewMode: true)
                    .environment(appState)
            }
            .sheet(isPresented: $showExport) {
                ExportView().environment(appState)
            }
            .alert("Clear All Doses", isPresented: $showClearDosesConfirm) {
                Button("Cancel", role: .cancel) { }
                Button("Clear Doses", role: .destructive) {
                    if let profile = appState.activeProfile {
                        appState.clearDoses(for: profile.id)
                    }
                }
            } message: {
                Text("This will permanently delete all doses for \(appState.activeProfile?.name ?? "this profile"). This cannot be undone.")
            }
            .alert("Reset App — Step 1", isPresented: $showResetStep1) {
                Button("Cancel", role: .cancel) { }
                Button("Continue", role: .destructive) { showResetStep2 = true }
            } message: {
                Text("This will delete ALL profiles, ALL doses, and reset the app to default. Are you sure?")
            }
            .alert("Reset App — Final Confirmation", isPresented: $showResetStep2) {
                TextField("Type DELETE to confirm", text: $resetConfirmText)
                Button("Cancel", role: .cancel) { resetConfirmText = "" }
                Button("Reset Everything", role: .destructive) {
                    if resetConfirmText.uppercased() == "DELETE" { performFullReset() }
                    resetConfirmText = ""
                }
            } message: {
                Text("Type DELETE to confirm. This action is irreversible.")
            }
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
    
    // MARK: - Current Profile

    private func currentProfileSection(_ profile: Profile) -> some View {
        NavigationLink {
            ProfileView()
        } label: {
            HStack(spacing: 14) {
                Text(profile.avatarEmoji)
                    .font(.title2)
                    .frame(width: 46, height: 46)
                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.name)
                        .font(.subheadline.bold())
                    let level = appState.currentLevel(for: profile)
                    HStack(spacing: 4) {
                        Circle()
                            .fill(appState.levelColor(for: level))
                            .frame(width: 8, height: 8)
                        Text("Level \(String(format: "%.1f", level))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, DS.screenPadding)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .pressFeedback()
    }

    // MARK: - Activity

    private var activitySection: some View {
        VStack(spacing: 0) {
            moreNavRow(icon: "chart.xyaxis.line", color: .teal, title: "Timeline") { TimelineView() }
            Divider().padding(.leading, 54)
            moreNavRow(icon: "bolt.fill", color: Color.accent, title: "Quick Dose") { QuickDoseView() }
            Divider().padding(.leading, 54)
            moreNavRow(icon: "clock.arrow.circlepath", color: .purple, title: "Session History") { SessionHistoryView() }
            Divider().padding(.leading, 54)
            Button { showExport = true } label: {
                moreRowLabel(icon: "square.and.arrow.up", color: .orange, title: "Export Dose History")
            }
            .buttonStyle(.plain)
            .pressFeedback()
        }
    }

    // MARK: - Infos

    private var infosSection: some View {
        VStack(spacing: 0) {
            moreNavRow(icon: "book.fill", color: .blue, title: "Substance Info") { SubstanceInfoView() }
            Divider().padding(.leading, 54)
            moreNavRow(icon: "exclamationmark.triangle.fill", color: .red, title: "Interaction Guide") { InteractionGuideView() }
            Divider().padding(.leading, 54)
            moreNavRow(icon: "cross.case.fill", color: .green, title: "Harm Reduction Basics") { HarmReductionGuideView() }
            Divider().padding(.leading, 54)
            moreNavRow(icon: "flask.fill", color: .purple, title: "Drug Checking Services") { DrugCheckingView() }
        }
    }
    
    // MARK: - Settings

    private var settingsSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Image(systemName: "lock.display")
                    .foregroundStyle(.secondary)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Lock Screen Activity")
                        .font(.subheadline.bold())
                    Text("Show on Lock Screen & Dynamic Island")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { appState.liveActivityEnabled },
                    set: { appState.setLiveActivityEnabled($0) }
                ))
                .labelsHidden()
            }
            .padding(.horizontal, DS.screenPadding)
            .padding(.vertical, 12)

            Divider().padding(.leading, 54)

            HStack(spacing: 14) {
                Image(systemName: "leaf.fill")
                    .foregroundStyle(Color.levelCalm)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Calm Mode")
                        .font(.subheadline.bold())
                    Text("Trip-safe UI — softer colors, supportive guidance")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { appState.calmMode },
                    set: { appState.calmMode = $0 }
                ))
                .tint(Color.accent)
                .labelsHidden()
            }
            .padding(.horizontal, DS.screenPadding)
            .padding(.vertical, 12)

            Divider().padding(.leading, 54)

            Button { showOnboardingReview = true } label: {
                moreRowLabel(icon: "arrow.clockwise.circle.fill", color: Color.accent, title: "Review Onboarding",
                             subtitle: "Re-view the walkthrough and update tolerances")
            }
            .buttonStyle(.plain)
            .pressFeedback()

            Divider().padding(.leading, 54)

            Button { showClearDosesConfirm = true } label: {
                moreRowLabel(icon: "trash", color: .orange, title: "Clear Doses",
                             subtitle: "Remove all doses for the active profile")
            }
            .buttonStyle(.plain)
            .pressFeedback()

            Divider().padding(.leading, 54)

            Button { showResetStep1 = true } label: {
                moreRowLabel(icon: "arrow.counterclockwise.circle.fill", color: .red, title: "Reset App",
                             subtitle: "Delete all data and start fresh")
            }
            .buttonStyle(.plain)
            .pressFeedback()
        }
    }
    
    // MARK: - Legal
    
    private var legalSection: some View {
        VStack(spacing: 0) {
            NavigationLink {
                DisclaimerView()
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "doc.text.fill")
                        .foregroundStyle(.secondary)
                        .frame(width: 28)
                    Text("Disclaimer & Terms")
                        .font(.subheadline.bold())
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, DS.screenPadding)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .pressFeedback()
            
            Divider().padding(.leading, 54)
            
            HStack(spacing: 14) {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
                    .frame(width: 28)
                Text("Version")
                    .font(.subheadline.bold())
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, DS.screenPadding)
            .padding(.vertical, 12)
            
            Divider().padding(.leading, 54)
            
            Link(destination: URL(string: "https://level11.app/privacy.html")!) {
                HStack(spacing: 14) {
                    Image(systemName: "lock.shield")
                        .foregroundStyle(.secondary)
                        .frame(width: 28)
                    Text("Privacy Policy")
                        .font(.subheadline.bold())
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, DS.screenPadding)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .pressFeedback()
            
            Divider().padding(.leading, 54)
            
            Link(destination: URL(string: "https://level11.app/support.html")!) {
                HStack(spacing: 14) {
                    Image(systemName: "questionmark.circle")
                        .foregroundStyle(.secondary)
                        .frame(width: 28)
                    Text("Support")
                        .font(.subheadline.bold())
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, DS.screenPadding)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .pressFeedback()
            
            Divider().padding(.leading, 54)
            
            Link(destination: URL(string: "https://level11.app")!) {
                HStack(spacing: 14) {
                    Image(systemName: "globe")
                        .foregroundStyle(.secondary)
                        .frame(width: 28)
                    Text("level11.app")
                        .font(.subheadline.bold())
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, DS.screenPadding)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .pressFeedback()
        }
    }

    // MARK: - Row Helpers

    private func moreNavRow<Destination: View>(icon: String, color: Color, title: String, @ViewBuilder destination: @escaping () -> Destination) -> some View {
        NavigationLink { destination() } label: {
            moreRowLabel(icon: icon, color: color, title: title)
        }
        .buttonStyle(.plain)
        .pressFeedback()
    }

    private func moreRowLabel(icon: String, color: Color, title: String, subtitle: String? = nil) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, DS.screenPadding)
        .padding(.vertical, 12)
    }

    // MARK: - Full Reset

    private func performFullReset() {
        appState.profiles = []
        appState.doses = []
        appState.activeProfileId = nil
        appState.activeSession = nil
        appState.sessionHistory = []
        appState.aftercareState = AftercareState()
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        NotificationManager.shared.cancelAllAftercareNotifications()
    }
}

struct SubstanceInfoView: View {
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

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(SubstanceCategory.allCases, id: \.self) { category in
                    let substances = Substances.all.filter { $0.category == category }
                    if !substances.isEmpty {
                        sectionHeader(category.rawValue.capitalized, color: Color(hex: category.color))
                        
                        ForEach(Array(substances.enumerated()), id: \.element.id) { idx, substance in
                            if idx > 0 { Divider().padding(.leading, 54) }
                            NavigationLink {
                                SubstanceDetailView(substance: substance)
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: category.icon)
                                        .foregroundStyle(Color(hex: category.color))
                                        .frame(width: 22)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(substance.name)
                                            .font(.subheadline.bold())
                                        Text(substance.shortName)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.horizontal, DS.screenPadding)
                                .padding(.vertical, 11)
                            }
                            .buttonStyle(.plain)
                            .pressFeedback()
                        }
                    }
                }
            }
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
        .background(Color.appBackground)
        .navigationTitle("Substances")
    }
}

struct SubstanceDetailView: View {
    let substance: Substance

    private func detailSectionHeader(_ title: String, color: Color = .secondary) -> some View {
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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Overview header
                HStack(spacing: 14) {
                    Image(systemName: substance.category.icon)
                        .font(.system(size: 32))
                        .foregroundStyle(Color(hex: substance.category.color))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(substance.name)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                        Text(substance.category.rawValue.capitalized)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, DS.screenPadding)
                .padding(.vertical, 16)

                Text(substance.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DS.screenPadding)
                    .padding(.bottom, 8)

                // Dosage
                detailSectionHeader("Dosage", color: Color.accent)
                dosageRow(label: "Light", dose: substance.lightDose, color: .green)
                Divider().padding(.leading, 54)
                dosageRow(label: "Common", dose: substance.commonDose, color: .orange)
                Divider().padding(.leading, 54)
                dosageRow(label: "Strong", dose: substance.strongDose, color: .red)

                // Timing
                if substance.onsetByRoute != nil || substance.durationByRoute != nil || substance.peakByRoute != nil {
                    detailSectionHeader("Timing (by Route)", color: .secondary)
                    
                    Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
                        GridRow {
                            Text("Route").font(.caption.bold()).foregroundStyle(.secondary)
                            Text("Onset").font(.caption.bold()).foregroundStyle(.secondary)
                            Text("Peak").font(.caption.bold()).foregroundStyle(.secondary)
                            Text("Duration").font(.caption.bold()).foregroundStyle(.secondary)
                        }
                        Divider()
                        ForEach(substance.routes, id: \.self) { route in
                            GridRow {
                                Text(route.displayName).font(.subheadline)
                                Text(formatTime(substance.onset(for: route))).font(.subheadline).foregroundStyle(.secondary)
                                Text(formatTime(substance.peak(for: route))).font(.subheadline).foregroundStyle(.secondary)
                                Text(formatTime(substance.duration(for: route))).font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, DS.screenPadding)
                    .padding(.vertical, 8)

                    timingRow(label: "Half-life", minutes: substance.halfLifeMinutes)
                } else {
                    detailSectionHeader("Timing (\(substance.primaryRoute.displayName))", color: .secondary)
                    timingRow(label: "Onset", minutes: substance.onsetMinutes)
                    Divider().padding(.leading, 54)
                    timingRow(label: "Peak", minutes: substance.peakMinutes)
                    Divider().padding(.leading, 54)
                    timingRow(label: "Duration", minutes: substance.durationMinutes)
                    Divider().padding(.leading, 54)
                    timingRow(label: "Half-life", minutes: substance.halfLifeMinutes)
                }

                // Routes
                detailSectionHeader("Routes", color: .secondary)
                ForEach(Array(substance.routes.enumerated()), id: \.element) { idx, route in
                    if idx > 0 { Divider().padding(.leading, 54) }
                    HStack(spacing: 14) {
                        Text(route.displayName)
                            .font(.subheadline)
                        Spacer()
                        Text("\(Int(route.bioavailability * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if route == substance.primaryRoute {
                            Text("Primary")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accent.opacity(0.15), in: Capsule())
                                .foregroundStyle(Color.accent)
                        }
                    }
                    .padding(.horizontal, DS.screenPadding)
                    .padding(.vertical, 10)
                }

                // Risks
                detailSectionHeader("Risks", color: .red)
                ForEach(Array(substance.risks.enumerated()), id: \.element) { idx, risk in
                    if idx > 0 { Divider().padding(.leading, 54) }
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                            .frame(width: 22)
                        Text(risk)
                            .font(.subheadline)
                        Spacer()
                    }
                    .padding(.horizontal, DS.screenPadding)
                    .padding(.vertical, 8)
                }

                // Safer Use
                detailSectionHeader("Safer Use", color: .green)
                ForEach(Array(substance.saferUse.enumerated()), id: \.element) { idx, tip in
                    if idx > 0 { Divider().padding(.leading, 54) }
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                            .frame(width: 22)
                        Text(tip)
                            .font(.subheadline)
                        Spacer()
                    }
                    .padding(.horizontal, DS.screenPadding)
                    .padding(.vertical, 8)
                }

                // Drug Checking
                if let info = substance.drugCheckingInfo {
                    detailSectionHeader("Drug Checking", color: .blue)

                    Text(info)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, DS.screenPadding)
                        .padding(.vertical, 8)

                    drugCheckLink("drugsdata.org", url: "https://drugsdata.org")
                    Divider().padding(.leading, 54)
                    drugCheckLink("saferparty.ch", url: "https://saferparty.ch")
                }
            }
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
        .background(Color.appBackground)
        .navigationTitle(substance.shortName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func dosageRow(label: String, dose: Double, color: Color) -> some View {
        HStack(spacing: 14) {
            Circle().fill(color).frame(width: 8, height: 8).frame(width: 22)
            Text(label).font(.subheadline)
            Spacer()
            Text(formatDose(dose))
                .font(.subheadline.bold())
                .foregroundStyle(color)
        }
        .padding(.horizontal, DS.screenPadding)
        .padding(.vertical, 10)
    }

    private func drugCheckLink(_ name: String, url: String) -> some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: 14) {
                Image(systemName: "flask.fill")
                    .foregroundStyle(.blue)
                    .frame(width: 22)
                Text(name)
                    .font(.subheadline)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, DS.screenPadding)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .pressFeedback()
    }
    
    private func formatDose(_ dose: Double) -> String {
        if dose < 1 {
            return String(format: "%.2f %@", dose, substance.unit.symbol)
        } else if dose == floor(dose) {
            return String(format: "%.0f %@", dose, substance.unit.symbol)
        } else {
            return String(format: "%.1f %@", dose, substance.unit.symbol)
        }
    }
    
    private func timingRow(label: String, minutes: Double) -> some View {
        HStack(spacing: 14) {
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(formatTime(minutes))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, DS.screenPadding)
        .padding(.vertical, 10)
    }
    
    private func formatTime(_ minutes: Double) -> String {
        if minutes >= 60 {
            let h = Int(minutes) / 60
            let m = Int(minutes) % 60
            return m > 0 ? "\(h)h \(m)min" : "\(h)h"
        }
        return "\(Int(minutes)) min"
    }
}

// MARK: - Disclaimer View

struct DisclaimerView: View {
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

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // EN
                sectionHeader("English", color: Color.accent)

                Text("""
                    This app is for harm reduction and educational purposes only. It does not constitute medical advice.

                    All dosage amounts refer to pure active substance. Actual street substances are rarely pure – start lower than the displayed amounts.

                    Possession and use of controlled substances may be illegal in your country. Always be aware of applicable laws.

                    The developers accept no liability for harm resulting from use of this app. Use at your own risk.
                    """)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, DS.screenPadding)

                // DE
                sectionHeader("Deutsch", color: Color.accent)

                Text("""
                    Diese App dient ausschließlich zur Schadensminimierung (Harm Reduction) und zu Bildungszwecken. Sie ersetzt keine medizinische Beratung.

                    Alle Mengenangaben beziehen sich auf reinen Wirkstoff. Tatsächliche Substanzen sind selten rein – starte mit kleineren Mengen als angegeben.

                    Besitz und Konsum können in Ihrem Land strafbar sein. Informiere dich über die geltenden Gesetze.

                    Die Entwickler übernehmen keine Haftung für Schäden durch die Nutzung dieser App. Nutzung auf eigenes Risiko.
                    """)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, DS.screenPadding)
            }
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
        .background(Color.appBackground)
        .navigationTitle("Disclaimer & Terms")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    MainTabView()
        .environment(AppState())
}
