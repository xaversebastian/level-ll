//
//  QuickDoseView.swift
//  LevelEleven
//
//  Version: 2.1  |  2026-03-12
//
//  Schneller Dose-Logger für das aktive Profil.
//  Phase 1: Substanzliste mit Suchfeld und Favoriten.
//  Phase 2: Neue Dosiseingabe — große Zahl, Stepper-Buttons,
//           Route-Pills, Preset-Row mit personalisierten Werten.
//
//  Updates v2.2:
//  - Fixed weak self compiler errors (QuickDoseView is a struct, not class)
//  - Removed [weak self] from DispatchWorkItem closures
//
import SwiftUI

struct QuickDoseView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var selectedSubstance: Substance?
    @State private var selectedRoute: DoseRoute = .oral
    @State private var amount: Double = 0
    @State private var searchText = ""
    @State private var note = ""

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
    @State private var dismissWorkItem: DispatchWorkItem?

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
            .navigationTitle(selectedSubstance?.shortName ?? "Quick Dose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(selectedSubstance != nil ? "Back" : "Cancel") {
                        if selectedSubstance != nil {
                            withAnimation(.spring(duration: 0.25)) { selectedSubstance = nil }
                        } else {
                            dismiss()
                        }
                    }
                }
            }
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
            .overlay(alignment: .bottom) {
                VStack(spacing: 10) {
                    if showConfirmation, let s = confirmedSubstance {
                        confirmationBanner(s)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    if let substance = selectedSubstance, !showConfirmation {
                        stickyLogButton(for: substance)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
                .onDisappear {
                    dismissWorkItem?.cancel()
                }
            .animation(.spring(duration: 0.25), value: selectedSubstance?.id)
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
        .pressFeedback()
    }

    // MARK: - Dose Form (new large-entry design)

    private func doseForm(_ substance: Substance) -> some View {
        let profile = appState.activeProfile
        let lastDoseDate = profile.flatMap { p in
            appState.recentDoses(for: p.id, hours: 24)
                .first { $0.substanceId == substance.id }?.timestamp
        }
        let rec: DoseRecommendation? = profile.map {
            IntoxEngine.recommendDose(
                substance: substance,
                route: selectedRoute,
                profile: $0,
                currentLevel: appState.currentLevel(for: $0),
                lastDoseDate: lastDoseDate
            )
        }
        let smallStep = max(0.5, substance.commonDose / 20.0)
        let bigStep   = max(1.0, substance.commonDose / 10.0)
        let catColor  = Color(hex: substance.category.color)

        return ScrollView {
            VStack(spacing: 0) {

                // ── Route pills ─────────────────────────────────────────
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(substance.routes, id: \.self) { route in
                            Button { selectedRoute = route } label: {
                                Text(route.displayName)
                                    .font(.subheadline.bold())
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 9)
                                    .background(
                                        selectedRoute == route
                                        ? catColor
                                        : Color.secondary.opacity(0.1),
                                        in: Capsule()
                                    )
                                    .foregroundStyle(selectedRoute == route ? .white : .primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, DS.screenPadding)
                }
                .padding(.vertical, 20)

                // ── Large amount display ────────────────────────────────
                VStack(spacing: 6) {
                    if amount > 0 {
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text(formatAmount(amount, substance: substance))
                                .font(.system(size: 72, weight: .black, design: .rounded))
                                .foregroundStyle(catColor)
                                .contentTransition(.numericText())
                                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: amount)
                            Text(substance.unit.symbol)
                                .font(.title2.bold())
                                .foregroundStyle(catColor.opacity(0.6))
                        }
                    } else {
                        Text("— \(substance.unit.symbol)")
                            .font(.system(size: 72, weight: .black, design: .rounded))
                            .foregroundStyle(.secondary.opacity(0.3))
                    }

                    if let rec, rec.warnings.isEmpty == false {
                        // no subtitle needed, warnings shown below
                    }
                }
                .frame(minHeight: 110)

                // ── Stepper buttons ─────────────────────────────────────
                HStack(spacing: 10) {
                    stepperButton("−\(formatIncrement(bigStep, substance: substance))", color: .secondary) {
                        amount = max(0, amount - bigStep)
                    }
                    stepperButton("−\(formatIncrement(smallStep, substance: substance))", color: .secondary) {
                        amount = max(0, amount - smallStep)
                    }
                    stepperButton("+\(formatIncrement(smallStep, substance: substance))", color: catColor) {
                        let maxAmount = substance.strongDose * 3.0 // Safety limit: max 3x strong dose
                        amount = min(maxAmount, amount + smallStep)
                    }
                    stepperButton("+\(formatIncrement(bigStep, substance: substance))", color: catColor) {
                        let maxAmount = substance.strongDose * 3.0 // Safety limit: max 3x strong dose
                        amount = min(maxAmount, amount + bigStep)
                    }
                }
                .padding(.horizontal, DS.screenPadding)
                .padding(.top, 16)

                // ── Preset row ──────────────────────────────────────────
                let lightVal  = rec?.adjustedLight  ?? substance.lightDose
                let commonVal = rec?.adjustedCommon ?? substance.commonDose
                let strongVal = rec?.adjustedStrong ?? substance.strongDose

                HStack(spacing: 8) {
                    presetButton("Light",  value: lightVal,  unit: substance.unit.symbol, isActive: isPresetActive(lightVal),  color: Color.levelGreen)
                    presetButton("Common", value: commonVal, unit: substance.unit.symbol, isActive: isPresetActive(commonVal), color: catColor, isRecommended: rec != nil)
                    presetButton("Strong", value: strongVal, unit: substance.unit.symbol, isActive: isPresetActive(strongVal), color: Color.levelOrange)
                }
                .padding(.horizontal, DS.screenPadding)
                .padding(.top, 14)

                // ── Personalized factors (collapsible) ──────────────────
                if let rec, !rec.adjustmentFactors.isEmpty {
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(rec.adjustmentFactors, id: \.self) { factor in
                                HStack(spacing: 6) {
                                    Circle().fill(.secondary).frame(width: 4, height: 4)
                                    Text(factor).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "person.badge.shield.checkmark")
                                .font(.caption).foregroundStyle(catColor)
                            Text("Suggested \(Int(rec.suggestedDose.rounded())) \(substance.unit.symbol) · personalized")
                                .font(.caption.bold())
                                .foregroundStyle(catColor)
                        }
                    }
                    .padding(.horizontal, DS.screenPadding)
                    .padding(.top, 18)
                }

                // ── IntoxEngine warnings ────────────────────────────────
                if let rec, !rec.warnings.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(rec.warnings, id: \.self) { warning in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption).foregroundStyle(.orange)
                                    .padding(.top, 1)
                                Text(warning)
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, DS.screenPadding)
                    .padding(.top, 14)
                }

                // ── Note field ──────────────────────────────────────────
                HStack(spacing: 10) {
                    Image(systemName: "note.text")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                    TextField("Add a note…", text: $note)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, DS.screenPadding)
                .padding(.vertical, 12)
                .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, DS.screenPadding)
                .padding(.top, 20)

                // ── Disclaimer ──────────────────────────────────────────
                Text("Amounts refer to pure active substance weight.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 12)
                    .padding(.horizontal, DS.screenPadding)

                Color.clear.frame(height: 100) // space for sticky button
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Stepper Button

    private func stepperButton(_ label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(color == .secondary ? .primary : color)
        }
        .buttonStyle(.plain)
        .pressFeedback()
    }

    // MARK: - Preset Button

    private func presetButton(_ title: String, value: Double, unit: String, isActive: Bool, color: Color, isRecommended: Bool = false) -> some View {
        Button { amount = value } label: {
            VStack(spacing: 3) {
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(isActive ? .white : .secondary)
                Text("\(Int(value.rounded())) \(unit)")
                    .font(.subheadline.bold())
                    .foregroundStyle(isActive ? .white : .primary)
                if isRecommended {
                    Text("rec.")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(isActive ? .white.opacity(0.7) : color)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isActive ? color : color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .pressFeedback()
    }

    private func isPresetActive(_ value: Double) -> Bool {
        abs(amount - value) < max(0.1, value * 0.05)
    }

    // MARK: - Format Helpers

    private func formatAmount(_ value: Double, substance: Substance) -> String {
        if value < 1 { return String(format: "%.2f", value) }
        if value == floor(value) { return String(format: "%.0f", value) }
        return String(format: "%.1f", value)
    }

    private func formatIncrement(_ increment: Double, substance: Substance) -> String {
        if increment < 1 { return String(format: "%.1f", increment) }
        return String(format: "%.0f", increment)
    }

    // MARK: - Dose Flow

    private func tappedLogDose(_ substance: Substance) {
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
        
        // Cancel any existing work item
        dismissWorkItem?.cancel()
        
        // Create new work item for delayed dismissal
        let workItem = DispatchWorkItem {
            guard self.showConfirmation else { return }
            self.showConfirmation = false
            
            let secondWorkItem = DispatchWorkItem {
                self.dismiss()
            }
            self.dismissWorkItem = secondWorkItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: secondWorkItem)
        }
        dismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5, execute: workItem)
    }

    // MARK: - Sticky Log Button

    private func stickyLogButton(for substance: Substance) -> some View {
        Button { tappedLogDose(substance) } label: {
            HStack(spacing: 6) {
                if selectedRoute == .nasal {
                    Image(systemName: "eye.fill").font(.body)
                }
                if amount > 0 {
                    Text("Log \(formatAmount(amount, substance: substance)) \(substance.unit.symbol) \(substance.shortName)")
                        .font(.headline)
                } else {
                    Text("Set an amount above")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                amount > 0 ? Color.accent : Color.secondary.opacity(0.25),
                in: RoundedRectangle(cornerRadius: DS.cardRadius)
            )
            .foregroundStyle(.white)
            .shadow(color: amount > 0 ? Color.accent.opacity(0.25) : .clear, radius: 8, y: 3)
        }
        .disabled(amount <= 0)
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
                    Text("\(substance.name) · \(formatAmount(amount, substance: substance)) \(substance.unit.symbol) · \(selectedRoute.displayName)")
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
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(.red.opacity(0.1), in: Capsule())
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
        .onTapGesture {
            showConfirmation = false
            dismissWorkItem?.cancel()
            
            let workItem = DispatchWorkItem {
                self.dismiss()
            }
            dismissWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: workItem)
        }
    }
}

#Preview {
    QuickDoseView().environment(AppState())
}
