//
//  MainTabView.swift
//  LevelEleven
//
//  Version: 2.0  |  2026-03-12
//
//  Updates v2.0:
//  - MoreView redesigned to match HomeView design patterns
//  - Standardized section headers with accent bars
//  - Card-style sections with shadows and DS tokens
//  - Added pressFeedback to interactive elements
//

import SwiftUI

struct MainTabView: View {
    @State private var appState = AppState()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tag(0)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            ProfileView()
                .tag(1)
                .tabItem {
                    Label("Profiles", systemImage: "person.2.fill")
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
        .environment(appState)
    }
}

struct MoreView: View {
    @Environment(AppState.self) private var appState
    @State private var exportURL: URL?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Quick Actions
                    sectionHeader("Quick Actions", color: Color.accent)
                    quickActionsSection
                    
                    // Current Profile
                    if let profile = appState.activeProfile {
                        sectionHeader("Current Profile", color: Color.levelTeal)
                        currentProfileSection(profile)
                    }
                    
                    // Settings
                    sectionHeader("Settings", color: .secondary)
                    settingsSection
                    
                    // Legal
                    sectionHeader("Legal", color: .secondary)
                    legalSection
                }
                .padding(.vertical, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("More")
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
    
    // MARK: - Quick Actions
    
    private var quickActionsSection: some View {
        VStack(spacing: 0) {
            NavigationLink {
                QuickDoseView()
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(Color.accent)
                        .frame(width: 28)
                    Text("Quick Dose")
                        .font(.subheadline.bold())
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, DS.screenPadding)
                .padding(.vertical, 12)
                .background(Color.appBackground)
            }
            .buttonStyle(.plain)
            
            Divider().padding(.leading, 54)
            
            NavigationLink {
                SubstanceInfoView()
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "book.fill")
                        .foregroundStyle(.blue)
                        .frame(width: 28)
                    Text("Substance Info")
                        .font(.subheadline.bold())
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, DS.screenPadding)
                .padding(.vertical, 12)
                .background(Color.appBackground)
            }
            .buttonStyle(.plain)
            
            Divider().padding(.leading, 54)
            
            NavigationLink {
                TimelineView()
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "chart.xyaxis.line")
                        .foregroundStyle(.teal)
                        .frame(width: 28)
                    Text("Timeline")
                        .font(.subheadline.bold())
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, DS.screenPadding)
                .padding(.vertical, 12)
                .background(Color.appBackground)
            }
            .buttonStyle(.plain)
            
            if let url = buildExportURL() {
                Divider().padding(.leading, 54)
                
                ShareLink(item: url) {
                    HStack(spacing: 14) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(.orange)
                            .frame(width: 28)
                        Text("Export Dose History")
                            .font(.subheadline.bold())
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, DS.screenPadding)
                    .padding(.vertical, 12)
                    .background(Color.appBackground)
                }
                .buttonStyle(.plain)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .fill(Color.appBackground)
                .shadow(color: DS.shadowColor, radius: DS.shadowRadius, y: DS.shadowY)
        )
        .padding(.horizontal, DS.screenPadding)
    }
    
    // MARK: - Current Profile
    
    private func currentProfileSection(_ profile: Profile) -> some View {
        VStack(spacing: 0) {
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
            }
            .padding(.horizontal, DS.screenPadding)
            .padding(.vertical, 12)
            .background(Color.appBackground)
            
            Divider().padding(.leading, 66)
            
            Button(role: .destructive) {
                appState.clearDoses(for: profile.id)
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                        .frame(width: 28)
                    Text("Clear All Doses")
                        .font(.subheadline.bold())
                    Spacer()
                }
                .padding(.horizontal, DS.screenPadding)
                .padding(.vertical, 12)
                .background(Color.appBackground)
            }
            .buttonStyle(.plain)
            .pressFeedback()
        }
        .background(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .fill(Color.appBackground)
                .shadow(color: DS.shadowColor, radius: DS.shadowRadius, y: DS.shadowY)
        )
        .padding(.horizontal, DS.screenPadding)
    }
    
    // MARK: - Settings
    
    private var settingsSection: some View {
        VStack(spacing: 0) {
            // Lock Screen Activity
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
            .background(Color.appBackground)
            
            Divider().padding(.leading, 54)
            
            // Calm Mode
            HStack(spacing: 14) {
                Image(systemName: "leaf.fill")
                    .foregroundStyle(Color.levelCalm)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Calm Mode")
                        .font(.subheadline.bold())
                    Text("Softens warning colors after dosing")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { appState.calmMode },
                    set: { appState.calmMode = $0 }
                ))
                .labelsHidden()
            }
            .padding(.horizontal, DS.screenPadding)
            .padding(.vertical, 12)
            .background(Color.appBackground)
        }
        .background(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .fill(Color.appBackground)
                .shadow(color: DS.shadowColor, radius: DS.shadowRadius, y: DS.shadowY)
        )
        .padding(.horizontal, DS.screenPadding)
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
                .background(Color.appBackground)
            }
            .buttonStyle(.plain)
            
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
            .background(Color.appBackground)
            
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
                .background(Color.appBackground)
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
                .background(Color.appBackground)
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
                .background(Color.appBackground)
            }
            .buttonStyle(.plain)
            .pressFeedback()
        }
        .background(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .fill(Color.appBackground)
                .shadow(color: DS.shadowColor, radius: DS.shadowRadius, y: DS.shadowY)
        )
        .padding(.horizontal, DS.screenPadding)
    }

    private func buildExportURL() -> URL? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        var csv = "Date,Profile,Substance,Route,Amount,Unit,Note\n"
        let profileMap = Dictionary(uniqueKeysWithValues: appState.profiles.map { ($0.id, $0.name) })
        let sortedDoses = appState.doses.sorted { $0.timestamp < $1.timestamp }
        for dose in sortedDoses {
            let date = formatter.string(from: dose.timestamp)
            let profile = profileMap[dose.profileId] ?? dose.profileId
            let substance = Substances.byId[dose.substanceId]?.name ?? dose.substanceId
            let route = dose.route.displayName
            let amount = dose.amount
            let unit = Substances.byId[dose.substanceId]?.unit.symbol ?? ""
            let note = dose.note?.replacingOccurrences(of: ",", with: ";") ?? ""
            csv += "\(date),\(profile),\(substance),\(route),\(amount),\(unit),\(note)\n"
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("LevelEleven-Export.csv")
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        return appState.doses.isEmpty ? nil : url
    }
}

struct SubstanceInfoView: View {
    var body: some View {
        List {
            ForEach(SubstanceCategory.allCases, id: \.self) { category in
                let substances = Substances.all.filter { $0.category == category }
                if !substances.isEmpty {
                    Section(category.rawValue.capitalized) {
                        ForEach(substances) { substance in
                            NavigationLink {
                                SubstanceDetailView(substance: substance)
                            } label: {
                                HStack {
                                    Image(systemName: category.icon)
                                        .foregroundStyle(Color(hex: category.color))
                                        .frame(width: 28)
                                    
                                    VStack(alignment: .leading) {
                                        Text(substance.name)
                                            .font(.body)
                                        Text(substance.shortName)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Substances")
    }
}

struct SubstanceDetailView: View {
    let substance: Substance
    
    var body: some View {
        List {
            Section("Overview") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: substance.category.icon)
                            .font(.largeTitle)
                            .foregroundStyle(Color(hex: substance.category.color))
                        
                        VStack(alignment: .leading) {
                            Text(substance.name)
                                .font(.title2.bold())
                            Text(substance.category.rawValue.capitalized)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Text(substance.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
            
            Section("Dosage") {
                HStack {
                    Circle().fill(.green).frame(width: 8, height: 8)
                    Text("Light")
                    Spacer()
                    Text(formatDose(substance.lightDose))
                        .foregroundStyle(.green)
                }
                HStack {
                    Circle().fill(.orange).frame(width: 8, height: 8)
                    Text("Common")
                    Spacer()
                    Text(formatDose(substance.commonDose))
                        .foregroundStyle(.orange)
                }
                HStack {
                    Circle().fill(.red).frame(width: 8, height: 8)
                    Text("Strong")
                    Spacer()
                    Text(formatDose(substance.strongDose))
                        .foregroundStyle(.red)
                }
            }
            
            if substance.onsetByRoute != nil || substance.durationByRoute != nil || substance.peakByRoute != nil {
                // Route-spezifische Zeiten als Tabelle
                Section("Timing (by Route)") {
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
                    timingRow(label: "Half-life", minutes: substance.halfLifeMinutes)
                }
            } else {
                Section("Timing (\(substance.primaryRoute.displayName))") {
                    timingRow(label: "Onset", minutes: substance.onsetMinutes)
                    timingRow(label: "Peak", minutes: substance.peakMinutes)
                    timingRow(label: "Duration", minutes: substance.durationMinutes)
                    timingRow(label: "Half-life", minutes: substance.halfLifeMinutes)
                }
            }
            
            Section("Routes") {
                ForEach(substance.routes, id: \.self) { route in
                    HStack {
                        Text(route.displayName)
                        Spacer()
                        Text("\(Int(route.bioavailability * 100))% Bioavailability")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if route == substance.primaryRoute {
                            Text("Primary")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.blue.opacity(0.2), in: Capsule())
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
            
            Section {
                ForEach(substance.risks, id: \.self) { risk in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                        Text(risk)
                            .font(.subheadline)
                    }
                }
            } header: {
                Label("Risks", systemImage: "exclamationmark.triangle")
            }
            
            Section {
                ForEach(substance.saferUse, id: \.self) { tip in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                        Text(tip)
                            .font(.subheadline)
                    }
                }
            } header: {
                Label("Safer Use", systemImage: "heart.text.square")
            }

            if substance.id == "mdma" {
                Section("Drug Checking") {
                    Link(destination: URL(string: "https://checkdrugs.at")!) {
                        HStack {
                            Image(systemName: "flask.fill").foregroundStyle(.blue)
                            Text("checkdrugs.at")
                            Spacer()
                            Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Link(destination: URL(string: "https://eve-rave.ch")!) {
                        HStack {
                            Image(systemName: "flask.fill").foregroundStyle(.blue)
                            Text("eve-rave.ch")
                            Spacer()
                            Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Link(destination: URL(string: "https://energy-control.org")!) {
                        HStack {
                            Image(systemName: "flask.fill").foregroundStyle(.blue)
                            Text("energy-control.org")
                            Spacer()
                            Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Text("Get your MDMA tested before use. Street pills vary widely in purity and content.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(substance.shortName)
        .navigationBarTitleDisplayMode(.inline)
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
        HStack {
            Text(label)
            Spacer()
            Text(formatTime(minutes))
                .foregroundStyle(.secondary)
        }
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
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // EN
                VStack(alignment: .leading, spacing: 12) {
                    Label("English", systemImage: "globe")
                        .font(.headline)
                        .foregroundStyle(Color.accent)

                    Text("""
                        This app is for harm reduction and educational purposes only. It does not constitute medical advice.

                        All dosage amounts refer to pure active substance. Actual street substances are rarely pure – start lower than the displayed amounts.

                        Possession and use of controlled substances may be illegal in your country. Always be aware of applicable laws.

                        The developers accept no liability for harm resulting from use of this app. Use at your own risk.
                        """)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))

                // DE
                VStack(alignment: .leading, spacing: 12) {
                    Label("Deutsch", systemImage: "globe")
                        .font(.headline)
                        .foregroundStyle(Color.accent)

                    Text("""
                        Diese App dient ausschließlich zur Schadensminimierung (Harm Reduction) und zu Bildungszwecken. Sie ersetzt keine medizinische Beratung.

                        Alle Mengenangaben beziehen sich auf reinen Wirkstoff. Tatsächliche Substanzen sind selten rein – starte mit kleineren Mengen als angegeben.

                        Besitz und Konsum können in Ihrem Land strafbar sein. Informiere dich über die geltenden Gesetze.

                        Die Entwickler übernehmen keine Haftung für Schäden durch die Nutzung dieser App. Nutzung auf eigenes Risiko.
                        """)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
            }
            .padding()
        }
        .navigationTitle("Disclaimer & Terms")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    MainTabView()
}
