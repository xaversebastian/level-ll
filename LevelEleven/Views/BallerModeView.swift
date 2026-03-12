//
//  BallerModeView.swift
//  LevelEleven
//
//  Version: 1.2  |  2026-03-12
//
//  Live-Gruppenscreen für aktive Baller-Mode-Sessions.
//  Zeigt Teilnehmer-Cards mit Level-Balken, Live-Statistiken (Swift Charts),
//  Gruppen-Durchschnitt und Peak-Level je Teilnehmer.
//  Timer aktualisiert alle 30 Sekunden. "End"-Button beendet die Session.
//  Enthält auch: SessionSetupView (Neue Session), GroupDoseView (Gruppen-Dose-Logger),
//  AddParticipantView (Teilnehmer nachholen).
//
//  HINWEIS: Alle Sub-Views (Setup, GroupDose, AddParticipant) sind in dieser Datei definiert.
//  calculateLiveLevelTimeline() iteriert in 10-Minuten-Schritten – bei langen Sessions ggf. optimieren.
//

import SwiftUI
import Combine
import Charts

struct BallerModeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var showSetup = false
    @State private var showAddDose = false
    @State private var showHistory = false
    @State private var showAddParticipant = false
    @State private var showEndConfirm = false
    @State private var quickDoseForProfileId: String?
    @State private var showQuickDoseForParticipant = false
    @State private var currentTime = Date()

    let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            Group {
                if let session = appState.activeSession, !session.participants.isEmpty {
                    activeSessionView(session)
                } else {
                    noSessionView
                }
            }
            .navigationTitle("Baller Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showSetup) {
                SessionSetupView()
                    .environment(appState)
            }
            .sheet(isPresented: $showAddDose) {
                if let session = appState.activeSession {
                    GroupDoseView(participantIds: session.participantIds)
                        .environment(appState)
                }
            }
            .sheet(isPresented: $showHistory) {
                SessionHistoryView()
                    .environment(appState)
            }
            .sheet(isPresented: $showAddParticipant) {
                AddParticipantView()
                    .environment(appState)
            }
            .sheet(isPresented: $showQuickDoseForParticipant) {
                if let profileId = quickDoseForProfileId {
                    QuickDoseForProfileView(profileId: profileId)
                        .environment(appState)
                }
            }
            .confirmationDialog("End Session?", isPresented: $showEndConfirm, titleVisibility: .visible) {
                Button("End & Save", role: .destructive) {
                    appState.endSession()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("The session will be archived and you can review it later.")
            }
            .onReceive(timer) { _ in
                currentTime = Date()
            }
        }
    }

    // MARK: - No Session

    private var noSessionView: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 60)

                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Color.accent.opacity(0.3), .pink.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 120, height: 120)
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.accent)
                }

                VStack(spacing: 8) {
                    Text("Baller Mode")
                        .font(.title.bold())
                    Text("Track levels together with your crew.\nSelect profiles and see everyone's status.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 32)
                }

                VStack(alignment: .leading, spacing: 16) {
                    featureRow(icon: "person.crop.circle.badge.checkmark", title: "Multi-Profile", desc: "Pick who's joining from saved profiles")
                    featureRow(icon: "pills.fill", title: "Group Dosing", desc: "See recommended doses for everyone")
                    featureRow(icon: "gauge.with.needle.fill", title: "Live Levels", desc: "Track everyone's level in real-time")
                }
                .padding(24)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 24)

                Button {
                    showSetup = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Start Session")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accent, in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(.white)
                }
                .padding(.horizontal, 24)

                if !appState.sessionHistory.isEmpty {
                    Button {
                        showHistory = true
                    } label: {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("Past Sessions")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .foregroundStyle(Color.accent)
                    .padding(.horizontal, 24)
                }

                Spacer(minLength: 60)
            }
        }
    }

    private func featureRow(icon: String, title: String, desc: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accent)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Active Session

    private func activeSessionView(_ session: BallerSession) -> some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 16) {
                    sessionHeader(session)

                    // Active Participants
                    ForEach(session.participantIds, id: \.self) { profileId in
                        if let profile = appState.profiles.first(where: { $0.id == profileId }) {
                            participantCard(profile, session: session)
                        }
                    }

                    // Removed Participants (can be re-added)
                    if !session.removedParticipantIds.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Left")
                                .font(.subheadline.bold())
                                .foregroundStyle(.secondary)
                                .padding(.leading, 4)

                            ForEach(session.removedParticipantIds, id: \.self) { profileId in
                                if let profile = appState.profiles.first(where: { $0.id == profileId }) {
                                    removedParticipantRow(profile)
                                }
                            }
                        }
                        .padding(.top, 8)
                    }

                    // MARK: - Live Statistics Section
                    liveStatsSection(session)

                    // Add Participant Button
                    Button {
                        showAddParticipant = true
                    } label: {
                        HStack {
                            Image(systemName: "person.badge.plus")
                            Text("Add Participant")
                        }
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .foregroundStyle(Color.accent)

                    // Spacer for sticky FAB
                    Color.clear.frame(height: 80)
                }
                .padding(16)
            }

            // Sticky FAB – always visible
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [.clear, Color(.systemBackground).opacity(0.95)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 32)
                .allowsHitTesting(false)

                Button {
                    showAddDose = true
                } label: {
                    Label("Log Dose for Group", systemImage: "pills.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accent, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .background(Color(.systemBackground).opacity(0.95))
            }
        }
    }

    // MARK: - Live Statistics

    private func liveStatsSection(_ session: BallerSession) -> some View {
        let sessionDoses = appState.sessionDoses(for: session)

        return VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(Color.accent)
                Text("Live Statistics")
                    .font(.headline)
                Spacer()
            }

            quickStatsGrid(session, doses: sessionDoses)

            if !sessionDoses.isEmpty {
                liveLevelChart(session)
            }

            perParticipantStats(session, doses: sessionDoses)
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func quickStatsGrid(_ session: BallerSession, doses: [Dose]) -> some View {
        let totalDoses = doses.count
        let uniqueSubstances = Set(doses.map { $0.substanceId }).count
        let groupAvgLevel = calculateGroupAvgLevel(session)
        let duration = session.durationFormatted

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            liveStatCard(value: "\(totalDoses)", label: "Total Doses", icon: "pills.fill", color: .blue)
            liveStatCard(value: "\(uniqueSubstances)", label: "Substances", icon: "flask.fill", color: .green)
            liveStatCard(value: String(format: "%.1f", groupAvgLevel), label: "Group Avg Level", icon: "gauge.with.needle.fill", color: Color.accent)
            liveStatCard(value: duration, label: "Duration", icon: "clock.fill", color: .orange)
        }
    }

    private func liveStatCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(value)
                    .font(.title3.bold())
                    .foregroundStyle(color)
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
    }

    private func liveLevelChart(_ session: BallerSession) -> some View {
        let levelData = session.participantIds.compactMap { profileId -> ProfileLevelTimeline? in
            guard let profile = appState.profiles.first(where: { $0.id == profileId }) else { return nil }
            return LevelTimelineService.buildTimeline(for: profile, from: session.startedAt, to: currentTime, appState: appState)
        }

        return VStack(alignment: .leading, spacing: 8) {
            Text("Level Timeline")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)

            Chart {
                ForEach(levelData, id: \.profileId) { profileData in
                    ForEach(profileData.points) { point in
                        LineMark(
                            x: .value("Time", point.time),
                            y: .value("Level", point.level)
                        )
                        .foregroundStyle(by: .value("Profile", profileData.name))
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)
                    }
                }
            }
            .frame(height: 180)
            .chartYScale(domain: 0...11)
            .chartLegend(position: .bottom)
        }
    }

    private func perParticipantStats(_ session: BallerSession, doses: [Dose]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Per Participant")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)

            ForEach(session.participantIds, id: \.self) { profileId in
                if let profile = appState.profiles.first(where: { $0.id == profileId }) {
                    let profileDoses = doses.filter { $0.profileId == profileId }
                    let peakLevel = calculateLivePeakLevel(for: profile, session: session)

                    HStack(spacing: 12) {
                        Text(profile.avatarEmoji)
                            .font(.title3)

                        Text(profile.name)
                            .font(.subheadline.bold())

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(profileDoses.count) doses")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 2) {
                                Text("Peak:")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(String(format: "%.1f", peakLevel))
                                    .font(.caption.bold())
                                    .foregroundStyle(appState.levelColor(for: peakLevel))
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Live Stats Helpers

    private func calculateGroupAvgLevel(_ session: BallerSession) -> Double {
        let activeIds = session.participantIds
        guard !activeIds.isEmpty else { return 0 }

        var totalLevel: Double = 0
        for profileId in activeIds {
            if let profile = appState.profiles.first(where: { $0.id == profileId }) {
                totalLevel += appState.currentLevel(for: profile, at: currentTime)
            }
        }
        return totalLevel / Double(activeIds.count)
    }

    private func calculateLivePeakLevel(for profile: Profile, session: BallerSession) -> Double {
        LevelTimelineService.peakLevel(for: profile, from: session.startedAt, to: currentTime, appState: appState)
    }

    private func sessionHeader(_ session: BallerSession) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.name)
                    .font(.title2.bold())
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(Color.accent)
                    Text(session.durationFormatted)
                    Text("•")
                        .foregroundStyle(.secondary)
                    Image(systemName: "person.2.fill")
                    Text("\(session.participantIds.count)")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                showEndConfirm = true
            } label: {
                Text("End")
                    .font(.subheadline.bold())
                    .foregroundStyle(.red)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.red.opacity(0.1), in: Capsule())
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func participantCard(_ profile: Profile, session: BallerSession) -> some View {
        let level = appState.currentLevel(for: profile, at: currentTime)
        let color = appState.levelColor(for: level)
        let atLimit = level >= Double(profile.personalLimit)

        return VStack(spacing: 12) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    Text(profile.avatarEmoji)
                        .font(.title2)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(profile.name)
                            .font(.headline)

                    }
                    Text("\(Int(profile.weight))kg • \(appState.levelDescription(for: level))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 0) {
                    Text(String(format: "%.1f", level))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(color)
                    Text("/11")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                // Remove button
                Button {
                    appState.removeSessionParticipant(profile.id)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary.opacity(0.5))
                }
            }

            // Level Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(.secondary.opacity(0.15))
                    RoundedRectangle(cornerRadius: 5)
                        .fill(color)
                        .frame(width: geo.size.width * min(level / 11.0, 1.0))
                }
            }
            .frame(height: 8)

            if atLimit {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text("Limit reached!")
                        .font(.caption.bold())
                }
                .padding(8)
                .frame(maxWidth: .infinity)
                .background(.red.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .contextMenu {
            Button {
                quickDoseForProfileId = profile.id
                showQuickDoseForParticipant = true
            } label: {
                Label("Log Dose for \(profile.name)", systemImage: "pills.fill")
            }
            Button(role: .destructive) {
                appState.removeSessionParticipant(profile.id)
            } label: {
                Label("Remove from Session", systemImage: "person.badge.minus")
            }
        }
    }

    private func removedParticipantRow(_ profile: Profile) -> some View {
        let level = appState.currentLevel(for: profile, at: currentTime)

        return HStack(spacing: 12) {
            Text(profile.avatarEmoji)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(profile.name)
                    .font(.subheadline)
                Text("Level: \(String(format: "%.1f", level))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                appState.addSessionParticipant(profile.id)
            } label: {
                Text("Rejoin")
                    .font(.caption.bold())
                    .foregroundStyle(Color.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accent.opacity(0.1), in: Capsule())
            }
        }
        .padding(12)
        .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Add Participant View

struct AddParticipantView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    var availableProfiles: [Profile] {
        guard let session = appState.activeSession else { return [] }
        return appState.profiles.filter { profile in
            !session.participantIds.contains(profile.id)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if availableProfiles.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("All profiles are already in the session")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(availableProfiles) { profile in
                        Button {
                            appState.addSessionParticipant(profile.id)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Text(profile.avatarEmoji)
                                    .font(.title2)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(profile.name)
                                        .font(.subheadline.bold())
                                    Text("\(Int(profile.weight))kg • Limit \(profile.personalLimit)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.accent)
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
            }
            .navigationTitle("Add Participant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Session Setup View

struct SessionSetupView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var sessionName = ""
    @State private var selectedProfileIds: Set<String> = []
    @State private var showNewProfile = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Session Name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Session Name")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                    TextField("e.g. Friday Night", text: $sessionName)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                }
                .padding()

                Divider()

                // Profile Selection
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Who's joining?")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            showNewProfile = true
                        } label: {
                            Label("New", systemImage: "plus")
                                .font(.caption)
                        }
                    }

                    if appState.profiles.isEmpty {
                        Text("No profiles yet. Create one to start.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 20)
                    } else {
                        ForEach(appState.profiles) { profile in
                            profileSelectRow(profile)
                        }
                    }
                }
                .padding()

                Spacer()

                // Start Button
                Button {
                    startSession()
                } label: {
                    Text("Start with \(selectedProfileIds.count) people")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(selectedProfileIds.isEmpty ? Color.gray : Color.accent, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }
                .disabled(selectedProfileIds.isEmpty)
                .padding()
            }
            .navigationTitle("New Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showNewProfile) {
                ProfileEditorView(profile: nil)
                    .environment(appState)
            }
            .onChange(of: appState.profiles.count) { _, newCount in
                // Auto-select newly added profile
                if let lastProfile = appState.profiles.last {
                    selectedProfileIds.insert(lastProfile.id)
                }
            }
        }
    }

    private func profileSelectRow(_ profile: Profile) -> some View {
        let isSelected = selectedProfileIds.contains(profile.id)

        return Button {
            if isSelected {
                selectedProfileIds.remove(profile.id)
            } else {
                selectedProfileIds.insert(profile.id)
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.accent.opacity(0.15) : .secondary.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Text(profile.avatarEmoji)
                        .font(.title3)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.name)
                        .font(.subheadline.bold())
                    Text("\(Int(profile.weight))kg • Limit \(profile.personalLimit)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color.accent : .secondary.opacity(0.3))
            }
            .padding(12)
            .background(isSelected ? Color.accent.opacity(0.08) : .clear, in: RoundedRectangle(cornerRadius: 12))
        }
        .foregroundStyle(.primary)
    }

    private func startSession() {
        let name = sessionName.trimmingCharacters(in: .whitespaces)
        appState.startSession(
            name: name.isEmpty ? "Session" : name,
            participantIds: Array(selectedProfileIds)
        )
        dismiss()
    }
}

// MARK: - Group Dose View

struct GroupDoseView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let participantIds: [String]

    @State private var selectedSubstance: Substance?
    @State private var selectedRoute: DoseRoute = .oral
    @State private var selectedProfilesForDose: Set<String> = []
    @State private var doseAmounts: [String: Double] = [:]
    @State private var showNasalGuide = false

    var participants: [Profile] {
        participantIds.compactMap { id in
            appState.profiles.first { $0.id == id }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let substance = selectedSubstance {
                    // Dose Configuration View
                    doseConfigView(substance)
                } else {
                    // Substance List (like SubstanceInfoView)
                    substanceListView
                }
            }
            .navigationTitle(selectedSubstance == nil ? "Substances" : "Set Dose")
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
            .onAppear {
                // Pre-select all participants
                selectedProfilesForDose = Set(participantIds)
            }
            .fullScreenCover(isPresented: $showNasalGuide) {
                if let substance = selectedSubstance {
                    let nasalDoses: [(profile: Profile, amount: Double)] = selectedProfilesForDose.compactMap { profileId in
                        guard let profile = appState.profiles.first(where: { $0.id == profileId }) else { return nil }
                        let rec = IntoxEngine.recommendDose(substance: substance, route: selectedRoute, profile: profile)
                        let amount = doseAmounts[profileId] ?? rec.recommendedDose
                        return (profile: profile, amount: amount)
                    }
                    NasalLineGuideView(substance: substance, doses: nasalDoses) {
                        showNasalGuide = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            performLogDoses()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Substance List View (directly showing overview)

    private var substanceListView: some View {
        List {
            ForEach(SubstanceCategory.allCases, id: \.self) { category in
                let substances = Substances.all.filter { $0.category == category }
                if !substances.isEmpty {
                    Section(category.rawValue.capitalized) {
                        ForEach(substances) { substance in
                            Button {
                                selectedSubstance = substance
                                selectedRoute = substance.primaryRoute
                            } label: {
                                HStack {
                                    Image(systemName: category.icon)
                                        .foregroundStyle(Color(hex: category.color))
                                        .frame(width: 28)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(substance.name)
                                            .font(.body)
                                        Text("\(String(format: "%.0f", substance.commonDose)) \(substance.unit.symbol) • \(substance.primaryRoute.displayName)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Dose Configuration View

    private func doseConfigView(_ substance: Substance) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Substance Header
                HStack {
                    Image(systemName: substance.category.icon)
                        .font(.title2)
                        .foregroundStyle(Color(hex: substance.category.color))
                    VStack(alignment: .leading) {
                        Text(substance.name)
                            .font(.title3.bold())
                        Text(substance.category.rawValue.capitalized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)

                // Route Picker
                routeSection(substance)

                Divider().padding(.horizontal)

                // Recommendations for all
                Text("Recommended Doses")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                ForEach(participants) { profile in
                    recommendationCard(profile: profile, substance: substance)
                }

                // Log Button
                Button {
                    logDoses()
                } label: {
                    Text("Log for \(selectedProfilesForDose.count) people")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(selectedProfilesForDose.isEmpty ? Color.gray : Color.accent, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }
                .disabled(selectedProfilesForDose.isEmpty)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }

    private func routeSection(_ substance: Substance) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Route")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(substance.routes, id: \.self) { route in
                        Button {
                            selectedRoute = route
                        } label: {
                            Text(route.displayName)
                                .font(.subheadline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(selectedRoute == route ? Color.accent : .secondary.opacity(0.1), in: Capsule())
                                .foregroundStyle(selectedRoute == route ? .white : .primary)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private func recommendationCard(profile: Profile, substance: Substance) -> some View {
        let rec = IntoxEngine.recommendDose(substance: substance, route: selectedRoute, profile: profile)
        let isSelected = selectedProfilesForDose.contains(profile.id)
        let currentAmount = doseAmounts[profile.id] ?? rec.recommendedDose
        let maxDose = substance.strongDose * 2
        let step = doseStep(for: substance)

        return VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Select checkbox
                Button {
                    if isSelected {
                        selectedProfilesForDose.remove(profile.id)
                    } else {
                        selectedProfilesForDose.insert(profile.id)
                    }
                } label: {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(isSelected ? Color.accent : .secondary.opacity(0.3))
                }

                // Profile info
                Text(profile.avatarEmoji)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.name)
                        .font(.subheadline.bold())
                    Text("\(Int(profile.weight))kg • Tol: \(profile.tolerance(for: substance.id))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Current dose amount
                VStack(alignment: .trailing, spacing: 0) {
                    Text(String(format: "%.1f", currentAmount))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.accent)
                    Text(substance.unit.symbol)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Dose Slider
            VStack(spacing: 4) {
                Slider(
                    value: Binding(
                        get: { doseAmounts[profile.id] ?? rec.recommendedDose },
                        set: { doseAmounts[profile.id] = $0 }
                    ),
                    in: 0...maxDose,
                    step: step
                )
                .tint(Color.accent)

                HStack {
                    Text("0")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        doseAmounts[profile.id] = rec.recommendedDose
                    } label: {
                        Text("Recommended: \(String(format: "%.1f", rec.recommendedDose))")
                            .font(.caption2)
                            .foregroundStyle(Color.accent)
                    }
                    Spacer()
                    Text(String(format: "%.0f", maxDose))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            // Adjustment factors
            if !rec.adjustmentFactors.isEmpty {
                HStack(spacing: 8) {
                    ForEach(rec.adjustmentFactors, id: \.self) { factor in
                        Text(factor)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.secondary.opacity(0.1), in: Capsule())
                    }
                    Spacer()
                }
            }

            // Warnings
            ForEach(rec.warnings, id: \.self) { warning in
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                    Text(warning)
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Spacer()
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
        .onAppear {
            if doseAmounts[profile.id] == nil {
                doseAmounts[profile.id] = rec.recommendedDose
            }
        }
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

    private func logDoses() {
        // Show nasal guide first if route is nasal
        if selectedRoute == .nasal {
            showNasalGuide = true
            return
        }
        performLogDoses()
    }

    private func performLogDoses() {
        guard let substance = selectedSubstance else { return }

        for profileId in selectedProfilesForDose {
            let rec = IntoxEngine.recommendDose(
                substance: substance,
                route: selectedRoute,
                profile: appState.profiles.first { $0.id == profileId } ?? Profile(id: profileId, name: "Unknown")
            )
            let amount = doseAmounts[profileId] ?? rec.recommendedDose

            let dose = Dose(
                profileId: profileId,
                substanceId: substance.id,
                route: selectedRoute,
                amount: amount,
                timestamp: Date()
            )
            appState.addDose(dose)
        }

        dismiss()
    }
}

// MARK: - Quick Dose for specific Profile (from Participant Card context menu)

struct QuickDoseForProfileView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let profileId: String

    @State private var selectedSubstance: Substance?
    @State private var selectedRoute: DoseRoute = .oral
    @State private var amount: Double = 0
    @State private var searchText = ""
    @State private var showConfirmation = false
    @State private var confirmedSubstance: Substance?
    @State private var lastLoggedDoseId: String?

    var profile: Profile? { appState.profiles.first { $0.id == profileId } }

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
            .navigationTitle(profile.map { "Dose for \($0.name)" } ?? "Log Dose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if selectedSubstance != nil { selectedSubstance = nil }
                        else { dismiss() }
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if showConfirmation, let s = confirmedSubstance {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        Text("\(s.name) logged")
                            .font(.subheadline.bold())
                        Spacer()
                        Button {
                            if let id = lastLoggedDoseId { appState.deleteDose(id) }
                            showConfirmation = false
                        } label: {
                            Text("Undo").font(.caption.bold()).foregroundStyle(.red)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(.red.opacity(0.1), in: Capsule())
                        }
                    }
                    .padding(14)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(duration: 0.3), value: showConfirmation)
        }
    }

    private var substanceList: some View {
        List {
            if let p = profile, !p.favorites.isEmpty {
                Section("Favorites") {
                    ForEach(p.favorites, id: \.self) { id in
                        if let substance = Substances.byId[id] { substanceRow(substance) }
                    }
                }
            }
            Section("All Substances") {
                ForEach(filteredSubstances) { substance in substanceRow(substance) }
            }
        }
        .searchable(text: $searchText, prompt: "Search substances")
    }

    private func substanceRow(_ substance: Substance) -> some View {
        Button {
            selectedSubstance = substance
            selectedRoute = substance.primaryRoute
            amount = substance.commonDose
        } label: {
            HStack {
                Image(systemName: substance.category.icon)
                    .foregroundStyle(Color(hex: substance.category.color)).frame(width: 30)
                VStack(alignment: .leading) {
                    Text(substance.name).font(.body)
                    Text(substance.category.rawValue.capitalized).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(String(format: "%.0f", substance.commonDose)) \(substance.unit.symbol)")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(.primary)
    }

    private func doseForm(_ substance: Substance) -> some View {
        Form {
            Section {
                HStack {
                    Image(systemName: substance.category.icon)
                        .font(.title).foregroundStyle(Color(hex: substance.category.color))
                    VStack(alignment: .leading) {
                        Text(substance.name).font(.title2.bold())
                        Text(substance.category.rawValue.capitalized).foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            Section("Route") {
                Picker("Route", selection: $selectedRoute) {
                    ForEach(substance.routes, id: \.self) { Text($0.displayName).tag($0) }
                }
                .pickerStyle(.segmented)
            }
            Section("Amount") {
                VStack(spacing: 16) {
                    HStack {
                        Text(String(format: "%.1f", amount))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                        Text(substance.unit.symbol).font(.title2).foregroundStyle(.secondary)
                    }
                    Slider(value: $amount, in: 0...substance.strongDose * 2,
                           step: substance.unit == .mg ? (substance.commonDose < 10 ? 0.5 : 5) : 1)
                    HStack {
                        quickDoseButton("Light", dose: substance.lightDose)
                        quickDoseButton("Common", dose: substance.commonDose)
                        quickDoseButton("Strong", dose: substance.strongDose)
                    }
                }
                .padding(.vertical, 8)
            }
            Section {
                Button { logDose(substance) } label: {
                    HStack { Spacer(); Text("Log Dose").font(.headline); Spacer() }
                }
                .disabled(amount <= 0)
            }
        }
    }

    private func quickDoseButton(_ label: String, dose: Double) -> some View {
        Button { amount = dose } label: {
            VStack {
                Text(String(format: "%.0f", dose)).font(.headline)
                Text(label).font(.caption)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 8)
            .background(amount == dose ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func logDose(_ substance: Substance) {
        let dose = Dose(
            profileId: profileId,
            substanceId: substance.id,
            route: selectedRoute,
            amount: amount,
            timestamp: Date()
        )
        appState.addDose(dose)
        lastLoggedDoseId = dose.id
        confirmedSubstance = substance
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        showConfirmation = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            guard showConfirmation else { return }
            showConfirmation = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { dismiss() }
        }
    }
}

#Preview {
    BallerModeView()
        .environment(AppState())
}
