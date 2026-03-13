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
            .scrollIndicators(.hidden)
            .background(Color.appBackground)
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
            }
            .buttonStyle(.plain)
            .pressFeedback()
            
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
            }
            .buttonStyle(.plain)
            .pressFeedback()
            
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
            }
            .buttonStyle(.plain)
            .pressFeedback()
            
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
                }
                .buttonStyle(.plain)
                .pressFeedback()
            }
        }
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
            
            Divider().padding(.leading, 54)
            
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
            }
            .buttonStyle(.plain)
            .pressFeedback()
        }
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
            
            Divider().padding(.leading, 54)
            
            // Calm Mode
            HStack(spacing: 14) {
                Image(systemName: "leaf.fill")
                    .foregroundStyle(Color.levelCalm)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Calm Mode")
                        .font(.subheadline.bold())
                    Text("Trip-safe UI — softer colors, supportive guidance instead of alarm")
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
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("level-ll-Export.csv")
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        return appState.doses.isEmpty ? nil : url
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
