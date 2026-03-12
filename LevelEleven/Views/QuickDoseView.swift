//
//  QuickDoseView.swift
//  LevelEleven
//
//  Version: 1.3  |  2026-03-12
//
//  Schneller Dose-Logger für das aktive Profil.
//  Phase 1: Substanzliste mit Suchfeld und Favoriten-Sektion.
//  Phase 2: Dosis-Formular mit Route-Picker (Segmented), Menge-Slider,
//           Light/Common/Strong-Schnellwahl und personalisierten Infos.
//  Phase 4: Redose-Warnung, Interaction-Pre-Check, Dose-Bestätigung (Banner fix: Overlay auf
//           NavigationStack-Ebene), Notizfeld + "Last Used" Badge.
//  Phase 5: Nasal Line Guide (fullScreenCover bei Route = nasal),
//           Inline-Disclaimer, Pre-Consumption Interaction Alert.
//
//  HINWEIS: Wird über MoreView → "Quick Dose" aufgerufen.
//  Für Gruppen-Dosing: GroupDoseView in BallerModeView.swift.

import SwiftUI

struct QuickDoseView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var selectedSubstance: Substance?
    @State private var selectedRoute: DoseRoute = .oral
    @State private var amount: Double = 0
    @State private var searchText = ""
    @State private var note = ""
    @State private var showNoteField = false

    // Redose alert
    @State private var pendingRedoseSubstance: Substance?
    @State private var showRedoseAlert = false

    // Pre-consumption interaction alert
    @State private var pendingInteractionWarning: Warning?
    @State private var showInteractionAlert = false

    // Nasal guide
    @State private var showNasalGuide = false

    // Confirmation overlay
    @State private var showConfirmation = false
    @State private var confirmedSubstance: Substance?
    @State private var confirmedLevelDelta: Double = 0
    @State private var lastLoggedDoseId: String?

    var filteredSubstances: [Substance] {
        if searchText.isEmpty { return Substances.all }
        return Substances.all.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.shortName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let substance = selectedSubstance {
                    doseForm(substance)
                } else {
                    substanceList
                }
            }
            .navigationTitle(selectedSubstance == nil ? "Quick Dose" : "Log Dose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if selectedSubstance != nil {
                            selectedSubstance = nil
                        } else {
                            dismiss()
                        }
                    }
                }
            }
            // Redose Alert
            .alert("Redose Warning", isPresented: $showRedoseAlert, presenting: pendingRedoseSubstance) { substance in
                Button("Cancel", role: .cancel) { pendingRedoseSubstance = nil }
                Button("Log anyway", role: .destructive) {
                    if let s = pendingRedoseSubstance { continueAfterRedoseCheck(s) }
                    pendingRedoseSubstance = nil
                }
            } message: { substance in
                let mins = Int(appState.recentDoses(for: appState.activeProfileId ?? "", hours: 24)
                    .filter { $0.substanceId == substance.id }
                    .map { $0.minutesAgo() }.min() ?? 0)
                Text("\(substance.name) was taken \(mins) min ago — still within the onset window. Redosing now may cause unexpected intensity.")
            }
            // Pre-Consumption Interaction Alert (always direct, ignores Calm Mode)
            .alert("⚠️ Interaction Warning", isPresented: $showInteractionAlert, presenting: pendingInteractionWarning) { _ in
                Button("Cancel", role: .cancel) { pendingInteractionWarning = nil }
                Button("Log anyway", role: .destructive) {
                    guard let s = selectedSubstance else { return }
                    pendingInteractionWarning = nil
                    continueAfterInteractionCheck(s)
                }
            } message: { warning in
                Text(warning.title + "\n\n" + warning.message + "\n\n" + warning.advice)
            }
            // Nasal Guide
            .fullScreenCover(isPresented: $showNasalGuide) {
                if let substance = selectedSubstance, let profile = appState.activeProfile {
                    NasalLineGuideView(
                        substance: substance,
                        doses: [(profile: profile, amount: amount)]
                    ) {
                        showNasalGuide = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            performLog(substance)
                        }
                    }
                }
            }
            // BANNER FIX: Overlay auf NavigationStack-Ebene (nicht auf Group/Form)
            .overlay(alignment: .bottom) {
                if showConfirmation, let s = confirmedSubstance {
                    confirmationBanner(s)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 24)
                }
            }
            .animation(.spring(duration: 0.3), value: showConfirmation)
        }
    }

    // MARK: - Substance List

    private var substanceList: some View {
        let profileId = appState.activeProfileId ?? ""
        let recentDoses = appState.recentDoses(for: profileId, hours: 24)

        return List {
            if let profile = appState.activeProfile, !profile.favorites.isEmpty {
                Section("Favorites") {
                    ForEach(profile.favorites, id: \.self) { id in
                        if let substance = Substances.byId[id] {
                            substanceRow(substance, recentDoses: recentDoses)
                        }
                    }
                }
            }

            Section("All Substances") {
                ForEach(filteredSubstances) { substance in
                    substanceRow(substance, recentDoses: recentDoses)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search substances")
    }

    @ViewBuilder
    private func substanceRow(_ substance: Substance, recentDoses: [Dose]) -> some View {
        let lastDose = recentDoses.filter { $0.substanceId == substance.id }.first
        Button {
            selectedSubstance = substance
            selectedRoute = substance.primaryRoute
            amount = substance.commonDose
        } label: {
            HStack {
                Image(systemName: substance.category.icon)
                    .foregroundStyle(Color(hex: substance.category.color))
                    .frame(width: 30)

                VStack(alignment: .leading) {
                    Text(substance.name).font(.body)
                    Text(substance.category.rawValue.capitalized)
                        .font(.caption).foregroundStyle(.secondary)
                }

                Spacer()

                if let dose = lastDose {
                    let mins = dose.minutesAgo()
                    let label = mins < 60 ? "\(Int(mins))m ago" : "\(Int(mins / 60))h ago"
                    Text(label)
                        .font(.caption2)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.accent.opacity(0.15), in: Capsule())
                        .foregroundStyle(Color.accent)
                }

                Text("\(String(format: "%.0f", substance.commonDose)) \(substance.unit.symbol)")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(.primary)
    }

    // MARK: - Dose Form

    private func doseForm(_ substance: Substance) -> some View {
        Form {
            Section {
                HStack {
                    Image(systemName: substance.category.icon)
                        .font(.title)
                        .foregroundStyle(Color(hex: substance.category.color))
                    VStack(alignment: .leading) {
                        Text(substance.name).font(.title2.bold())
                        Text(substance.category.rawValue.capitalized).foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Route") {
                Picker("Route", selection: $selectedRoute) {
                    ForEach(substance.routes, id: \.self) { route in
                        Text(route.displayName).tag(route)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Amount") {
                VStack(spacing: 16) {
                    HStack {
                        Text(String(format: "%.1f", amount))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                        Text(substance.unit.symbol)
                            .font(.title2).foregroundStyle(.secondary)
                    }

                    Slider(value: $amount, in: 0...substance.strongDose * 2, step: doseStep(for: substance))

                    HStack {
                        doseButton("Light", dose: substance.lightDose)
                        doseButton("Common", dose: substance.commonDose)
                        doseButton("Strong", dose: substance.strongDose)
                    }

                    // Inline disclaimer – pure substance note
                    Text("Amounts refer to pure active substance weight")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.vertical, 8)
            }

            if let profile = appState.activeProfile {
                Section("Personalized Info") {
                    let tolerance = profile.tolerance(for: substance.id)
                    HStack {
                        Text("Tolerance")
                        Spacer()
                        Text("Level \(tolerance)").foregroundStyle(.secondary)
                    }
                    let recommended = substance.commonDose * profile.toleranceFactor(for: substance.id)
                    HStack {
                        Text("Recommended")
                        Spacer()
                        Text("\(String(format: "%.0f", recommended)) \(substance.unit.symbol)").foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                DisclosureGroup(isExpanded: $showNoteField) {
                    TextField("e.g. pre-workout, party, festival…", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                } label: {
                    Label("Add Note", systemImage: "note.text")
                        .foregroundStyle(showNoteField ? Color.accent : .secondary)
                }
            }

            Section {
                Button { tappedLogDose(substance) } label: {
                    HStack {
                        Spacer()
                        if selectedRoute == .nasal {
                            Label("Log Dose", systemImage: "eye.fill")
                                .font(.headline)
                        } else {
                            Text("Log Dose").font(.headline)
                        }
                        Spacer()
                    }
                }
                .disabled(amount <= 0)
            }
        }
    }

    // MARK: - Dose Flow (Interaction → Redose → Nasal Guide → Log)

    /// Entry point: runs interaction check first, then redose, then nasal guide.
    private func tappedLogDose(_ substance: Substance) {
        // Step 1: Pre-consumption interaction check (always alarming, ignores Calm Mode)
        if let profile = appState.activeProfile {
            let simulatedDose = Dose(
                profileId: profile.id,
                substanceId: substance.id,
                route: selectedRoute,
                amount: amount,
                timestamp: Date()
            )
            let currentActive = appState.activeDoses(for: profile.id, at: Date())
            let currentAll = appState.recentDoses(for: profile.id, hours: 8)
            let existingWarnings = WarningSystem.checkInteractions(
                activeDoses: currentActive, allDoses: currentAll, profile: profile
            )
            let withNewWarnings = WarningSystem.checkInteractions(
                activeDoses: currentActive + [simulatedDose],
                allDoses: currentAll + [simulatedDose],
                profile: profile
            )
            let existingTitles = Set(existingWarnings.map { $0.title })
            let newDangerWarnings = withNewWarnings.filter {
                ($0.severity == .danger || $0.severity == .warning) && !existingTitles.contains($0.title)
            }
            if let topWarning = newDangerWarnings.first {
                pendingInteractionWarning = topWarning
                showInteractionAlert = true
                return
            }
        }
        continueAfterInteractionCheck(substance)
    }

    private func continueAfterInteractionCheck(_ substance: Substance) {
        // Step 2: Redose check
        let onsetHours = substance.onset(for: selectedRoute) / 60
        let recent = appState.recentDoses(for: appState.activeProfileId ?? "", hours: onsetHours)
            .filter { $0.substanceId == substance.id }
        if !recent.isEmpty {
            pendingRedoseSubstance = substance
            showRedoseAlert = true
            return
        }
        continueAfterRedoseCheck(substance)
    }

    private func continueAfterRedoseCheck(_ substance: Substance) {
        // Step 3: Nasal guide if route = nasal
        if selectedRoute == .nasal {
            showNasalGuide = true
            return
        }
        performLog(substance)
    }

    private func performLog(_ substance: Substance) {
        let levelBefore = appState.currentLevel()
        let doseId = appState.logDose(
            substanceId: substance.id,
            route: selectedRoute,
            amount: amount,
            note: note.trimmingCharacters(in: .whitespaces).isEmpty ? nil : note
        )
        let levelAfter = appState.currentLevel()
        lastLoggedDoseId = doseId
        confirmedSubstance = substance
        confirmedLevelDelta = levelAfter - levelBefore
        showConfirmation = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            guard showConfirmation else { return }
            showConfirmation = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { dismiss() }
        }
    }

    // MARK: - Helpers

    private func doseButton(_ label: String, dose: Double) -> some View {
        Button { amount = dose } label: {
            VStack {
                Text(String(format: "%.0f", dose)).font(.headline)
                Text(label).font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(amount == dose ? Color.accent.opacity(0.2) : Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func doseStep(for substance: Substance) -> Double {
        switch substance.unit {
        case .mg: return substance.commonDose < 10 ? 0.5 : 5
        case .ml: return 0.1
        case .drinks: return 0.5
        case .ug: return 5
        case .puffs: return 1
        case .g: return 0.5
        }
    }

    // MARK: - Confirmation Banner

    private func confirmationBanner(_ substance: Substance) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: substance.category.color).opacity(0.2))
                    .frame(width: 44, height: 44)
                Image(systemName: substance.category.icon)
                    .font(.title3)
                    .foregroundStyle(Color(hex: substance.category.color))
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Text("\(substance.name) • \(String(format: "%.0f", amount)) \(substance.unit.symbol) • \(selectedRoute.displayName)")
                        .font(.subheadline.bold())
                }
                if confirmedLevelDelta > 0.05 {
                    Text(String(format: "Level +%.1f", confirmedLevelDelta))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                if let id = lastLoggedDoseId {
                    appState.deleteDose(id)
                    lastLoggedDoseId = nil
                }
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                showConfirmation = false
            } label: {
                Text("Undo")
                    .font(.caption.bold())
                    .foregroundStyle(.red)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.red.opacity(0.1), in: Capsule())
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
        .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
        .onTapGesture {
            showConfirmation = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { dismiss() }
        }
    }
}

#Preview {
    QuickDoseView()
        .environment(AppState())
}
