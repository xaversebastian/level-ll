//
//  BallerModeView.swift
//  LevelEleven
//
//  Version: 1.3  |  2026-03-12
//
//  Live-Gruppenscreen für aktive Baller-Mode-Sessions.
//  Zeigt Teilnehmer-Cards mit Level-Balken, Live-Statistiken (Swift Charts),
//  Gruppen-Durchschnitt und Peak-Level je Teilnehmer.
//  Timer aktualisiert alle 30 Sekunden. "End"-Button beendet die Session.
//  Enthält auch: SessionSetupView (Neue Session), GroupDoseView (Gruppen-Dose-Logger),
//  AddParticipantView (Teilnehmer nachholen).
//
//  Updates v1.4:
//  - Fixed timer lifecycle with proper AnyCancellable management
//  - Fixed memory leaks in QuickDoseForProfileView with cancellable work items
//  - Fixed weak self compiler errors (structs don't support weak references)
//  - Removed [weak self] from DispatchWorkItem closures
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
    @State private var timerCancellable: AnyCancellable?

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
            .onAppear {
                timerCancellable = Timer.publish(every: 30, on: .main, in: .common)
                    .autoconnect()
                    .sink { _ in currentTime = Date() }
            }
            .onDisappear {
                timerCancellable?.cancel()
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

    private var thinDivider: some View {
        Divider().padding(.leading, 54)
    }

    // MARK: - No Session

    private var noSessionView: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero area
                VStack(spacing: 12) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.accent)
                        .padding(.top, 40)

                    Text("Baller Mode")
                        .font(.system(size: 28, weight: .black, design: .rounded))

                    Text("Track levels together with your crew.\nSelect profiles and see everyone's status.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 20)
                }

                // Features
                sectionHeader("Features", color: Color.accent)

                featureRow(icon: "person.crop.circle.badge.checkmark", title: "Multi-Profile", desc: "Pick who's joining from saved profiles")
                thinDivider
                featureRow(icon: "pills.fill", title: "Group Dosing", desc: "See recommended doses for everyone")
                thinDivider
                featureRow(icon: "gauge.with.needle.fill", title: "Live Levels", desc: "Track everyone's level in real-time")

                // Actions
                VStack(spacing: 10) {
                    Button {
                        showSetup = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                            Text("Start Session")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.accent.gradient, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                        .shadow(color: Color.accent.opacity(0.2), radius: 8, y: 3)
                    }

                    if !appState.sessionHistory.isEmpty {
                        Button {
                            showHistory = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "clock.arrow.circlepath")
                                Text("Past Sessions")
                                    .fontWeight(.medium)
                            }
                            .font(.subheadline)
                            .foregroundStyle(Color.accent)
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, DS.screenPadding)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
        .scrollIndicators(.hidden)
        .background(Color.appBackground)
    }

    private func featureRow(icon: String, title: String, desc: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accent)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, DS.screenPadding)
        .padding(.vertical, 11)
    }

    // MARK: - Active Session

    private func activeSessionView(_ session: BallerSession) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                sessionHeader(session)

                // Active Participants
                sectionHeader("Participants (\(session.participantIds.count))", color: Color.accent)

                ForEach(Array(session.participantIds.enumerated()), id: \.element) { idx, profileId in
                    if let profile = appState.profiles.first(where: { $0.id == profileId }) {
                        if idx > 0 { thinDivider }
                        participantRow(profile, session: session)
                    }
                }

                // Removed Participants
                if !session.removedParticipantIds.isEmpty {
                    sectionHeader("Left", color: .secondary)

                    ForEach(Array(session.removedParticipantIds.enumerated()), id: \.element) { idx, profileId in
                        if let profile = appState.profiles.first(where: { $0.id == profileId }) {
                            if idx > 0 { thinDivider }
                            removedParticipantRow(profile)
                        }
                    }
                }

                // Live Statistics
                liveStatsSection(session)

                // Add Participant
                Button {
                    showAddParticipant = true
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "person.badge.plus")
                            .foregroundStyle(Color.accent)
                            .frame(width: 22)
                        Text("Add Participant")
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.accent)
                        Spacer()
                    }
                    .padding(.horizontal, DS.screenPadding)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .pressFeedback()

                Color.clear.frame(height: 80)
            }
        }
        .scrollIndicators(.hidden)
        .background(Color.appBackground)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button {
                showAddDose = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "pills.fill")
                        .font(.body.bold())
                    Text("Log Dose for Group")
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
    }

    // MARK: - Live Statistics

    private func liveStatsSection(_ session: BallerSession) -> some View {
        let sessionDoses = appState.sessionDoses(for: session)

        return VStack(spacing: 0) {
            sectionHeader("Live Statistics", color: Color.accent)

            quickStatsGrid(session, doses: sessionDoses)
                .padding(.horizontal, DS.screenPadding)
                .padding(.bottom, 16)

            if !sessionDoses.isEmpty {
                liveLevelChart(session)
                    .padding(.horizontal, DS.screenPadding)
                    .padding(.bottom, 16)
            }

            perParticipantStats(session, doses: sessionDoses)
                .padding(.horizontal, DS.screenPadding)
        }
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
                    Text("·")
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
                    .background(.red.opacity(0.08), in: Capsule())
            }
            .pressFeedback()
        }
        .padding(.horizontal, DS.screenPadding)
        .padding(.vertical, 14)
    }

    private func participantRow(_ profile: Profile, session: BallerSession) -> some View {
        let level = appState.currentLevel(for: profile, at: currentTime)
        let color = appState.levelColor(for: level)
        let atLimit = level >= Double(profile.personalLimit)

        return HStack(spacing: 14) {
            // Left accent line
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 3, height: 40)

            Text(profile.avatarEmoji)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(profile.name)
                    .font(.subheadline.bold())
                HStack(spacing: 4) {
                    Text("\(Int(profile.weight))kg")
                    Text("·")
                    Text(appState.levelDescription(for: level))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Level display
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(String(format: "%.1f", level))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: level)
                Text("/11")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            // Remove button
            Button {
                appState.removeSessionParticipant(profile.id)
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
        .overlay(alignment: .bottom) {
            if atLimit {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text("Limit reached")
                        .font(.caption.bold())
                        .foregroundStyle(.red)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DS.screenPadding)
                .padding(.leading, 20)
                .padding(.vertical, 6)
                .background(.red.opacity(0.06))
            }
        }
    }

    private func removedParticipantRow(_ profile: Profile) -> some View {
        let level = appState.currentLevel(for: profile, at: currentTime)

        return HStack(spacing: 14) {
            Text(profile.avatarEmoji)
                .font(.title3)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(profile.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Level: \(String(format: "%.1f", level))")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
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
            .pressFeedback()
        }
        .padding(.horizontal, DS.screenPadding)
        .padding(.vertical, 10)
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
            ScrollView {
                VStack(spacing: 0) {
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
                        .padding(.vertical, 60)
                    } else {
                        ForEach(Array(availableProfiles.enumerated()), id: \.element.id) { idx, profile in
                            if idx > 0 { Divider().padding(.leading, 54) }
                            Button {
                                appState.addSessionParticipant(profile.id)
                                dismiss()
                            } label: {
                                HStack(spacing: 14) {
                                    Text(profile.avatarEmoji)
                                        .font(.title2)
                                        .frame(width: 22)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(profile.name)
                                            .font(.subheadline.bold())
                                        Text("\(Int(profile.weight))kg · Limit \(profile.personalLimit)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(Color.accent)
                                }
                                .padding(.horizontal, DS.screenPadding)
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(.plain)
                            .pressFeedback()
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .background(Color.appBackground)
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
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Session Name
                    sectionHeader("Session Name", color: Color.accent)

                    TextField("e.g. Friday Night", text: $sessionName)
                        .textFieldStyle(.plain)
                        .padding(14)
                        .background(.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, DS.screenPadding)

                    // Profile Selection
                    HStack {
                        sectionHeader("Who's Joining?", color: Color.accent)
                        Spacer()
                        Button {
                            showNewProfile = true
                        } label: {
                            Label("New", systemImage: "plus")
                                .font(.caption.bold())
                                .foregroundStyle(Color.accent)
                        }
                        .padding(.trailing, DS.screenPadding)
                        .padding(.top, 22)
                    }

                    if appState.profiles.isEmpty {
                        Text("No profiles yet. Create one to start.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)
                    } else {
                        ForEach(Array(appState.profiles.enumerated()), id: \.element.id) { idx, profile in
                            if idx > 0 { Divider().padding(.leading, 54) }
                            profileSelectRow(profile)
                        }
                    }
                }
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)
            .background(Color.appBackground)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Button {
                    startSession()
                } label: {
                    Text("Start with \(selectedProfileIds.count) people")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(selectedProfileIds.isEmpty ? Color.gray : Color.accent.gradient, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                        .shadow(color: Color.accent.opacity(selectedProfileIds.isEmpty ? 0 : 0.2), radius: 8, y: 3)
                }
                .disabled(selectedProfileIds.isEmpty)
                .padding(.horizontal, DS.screenPadding)
                .padding(.vertical, 12)
                .background(.regularMaterial)
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
            HStack(spacing: 14) {
                Text(profile.avatarEmoji)
                    .font(.title3)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.name)
                        .font(.subheadline.bold())
                    Text("\(Int(profile.weight))kg · Limit \(profile.personalLimit)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color.accent : .secondary.opacity(0.3))
            }
            .padding(.horizontal, DS.screenPadding)
            .padding(.vertical, 12)
            .background(isSelected ? Color.accent.opacity(0.04) : .clear)
        }
        .buttonStyle(.plain)
        .pressFeedback()
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
                    let nasalDoses: [(profile: Profile, amount: Double)] = selectedProfilesForDose.compactMap { profileId -> (profile: Profile, amount: Double)? in
                        guard let profile = appState.profiles.first(where: { $0.id == profileId }) else { return nil }
                        let rec = IntoxEngine.recommendDose(substance: substance, route: selectedRoute, profile: profile)
                        let amount = doseAmounts[profileId] ?? rec.suggestedDose
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

    // MARK: - Substance List View

    private func groupSectionHeader(_ title: String, color: Color = .secondary) -> some View {
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

    private var substanceListView: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(SubstanceCategory.allCases, id: \.self) { category in
                    let substances = Substances.all.filter { $0.category == category }
                    if !substances.isEmpty {
                        groupSectionHeader(category.rawValue.capitalized, color: Color(hex: category.color))

                        ForEach(Array(substances.enumerated()), id: \.element.id) { idx, substance in
                            if idx > 0 { Divider().padding(.leading, 54) }
                            Button {
                                selectedSubstance = substance
                                selectedRoute = substance.primaryRoute
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: category.icon)
                                        .foregroundStyle(Color(hex: category.color))
                                        .frame(width: 22)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(substance.name)
                                            .font(.subheadline.bold())
                                        Text("\(String(format: "%.0f", substance.commonDose)) \(substance.unit.symbol) · \(substance.primaryRoute.displayName)")
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
    }

    // MARK: - Dose Configuration View

    private func doseConfigView(_ substance: Substance) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // Substance Header
                HStack(spacing: 14) {
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
                .padding(.horizontal, DS.screenPadding)
                .padding(.vertical, 14)

                // Route Picker
                routeSection(substance)

                // Recommendations
                groupSectionHeader("Recommended Doses", color: Color.accent)

                ForEach(Array(participants.enumerated()), id: \.element.id) { idx, profile in
                    if idx > 0 { Divider().padding(.horizontal, DS.screenPadding) }
                    recommendationRow(profile: profile, substance: substance)
                }

                Color.clear.frame(height: 80)
            }
        }
        .scrollIndicators(.hidden)
        .background(Color.appBackground)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button {
                logDoses()
            } label: {
                Text("Log for \(selectedProfilesForDose.count) people")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(selectedProfilesForDose.isEmpty ? Color.gray : Color.accent.gradient, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
                    .shadow(color: Color.accent.opacity(selectedProfilesForDose.isEmpty ? 0 : 0.2), radius: 8, y: 3)
            }
            .disabled(selectedProfilesForDose.isEmpty)
            .padding(.horizontal, DS.screenPadding)
            .padding(.vertical, 12)
            .background(.regularMaterial)
        }
    }

    private func routeSection(_ substance: Substance) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Route")
                .font(.system(size: 12, weight: .bold))
                .tracking(1.5)
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
                                .background(selectedRoute == route ? Color.accent : .secondary.opacity(0.08), in: Capsule())
                                .foregroundStyle(selectedRoute == route ? .white : .primary)
                        }
                        .pressFeedback()
                    }
                }
            }
        }
        .padding(.horizontal, DS.screenPadding)
        .padding(.vertical, 12)
    }

    private func recommendationRow(profile: Profile, substance: Substance) -> some View {
        let rec = IntoxEngine.recommendDose(substance: substance, route: selectedRoute, profile: profile)
        let isSelected = selectedProfilesForDose.contains(profile.id)
        let currentAmount = doseAmounts[profile.id] ?? rec.suggestedDose
        let maxDose = substance.strongDose * 2
        let step = doseStep(for: substance)

        return VStack(spacing: 12) {
            HStack(spacing: 12) {
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
                        .frame(minWidth: 44, minHeight: 44)
                }
                .buttonStyle(.plain)
                .pressFeedback()

                Text(profile.avatarEmoji)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.name)
                        .font(.subheadline.bold())
                    Text("\(Int(profile.weight))kg · Tol: \(profile.tolerance(for: substance.id))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 0) {
                    Text(String(format: "%.1f", currentAmount))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.accent)
                        .contentTransition(.numericText())
                    Text(substance.unit.symbol)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 4) {
                Slider(
                    value: Binding(
                        get: { doseAmounts[profile.id] ?? rec.suggestedDose },
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
                        doseAmounts[profile.id] = rec.suggestedDose
                    } label: {
                        Text("Rec: \(String(format: "%.1f", rec.suggestedDose))")
                            .font(.caption2)
                            .foregroundStyle(Color.accent)
                    }
                    .pressFeedback()
                    Spacer()
                    Text(String(format: "%.0f", maxDose))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if !rec.adjustmentFactors.isEmpty {
                HStack(spacing: 8) {
                    ForEach(rec.adjustmentFactors, id: \.self) { factor in
                        Text(factor)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.secondary.opacity(0.06), in: Capsule())
                    }
                    Spacer()
                }
            }

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
        .padding(.horizontal, DS.screenPadding)
        .padding(.vertical, 14)
        .onAppear {
            if doseAmounts[profile.id] == nil {
                doseAmounts[profile.id] = rec.suggestedDose
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
            let amount = doseAmounts[profileId] ?? rec.suggestedDose

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
    @State private var dismissWorkItem: DispatchWorkItem?

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
            .onDisappear {
                dismissWorkItem?.cancel()
            }
        }
    }

    private var substanceList: some View {
        ScrollView {
            VStack(spacing: 0) {
                if let p = profile, !p.favorites.isEmpty {
                    profileSectionHeader("Favorites", color: Color.accent)
                    ForEach(Array(p.favorites.enumerated()), id: \.element) { idx, id in
                        if let substance = Substances.byId[id] {
                            if idx > 0 { Divider().padding(.leading, 54) }
                            substanceRow(substance)
                        }
                    }
                }
                profileSectionHeader("All Substances", color: .secondary)
                ForEach(Array(filteredSubstances.enumerated()), id: \.element.id) { idx, substance in
                    if idx > 0 { Divider().padding(.leading, 54) }
                    substanceRow(substance)
                }
            }
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
        .background(Color.appBackground)
        .searchable(text: $searchText, prompt: "Search substances")
    }

    private func profileSectionHeader(_ title: String, color: Color) -> some View {
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

    private func substanceRow(_ substance: Substance) -> some View {
        Button {
            selectedSubstance = substance
            selectedRoute = substance.primaryRoute
            amount = substance.commonDose
        } label: {
            HStack(spacing: 14) {
                Image(systemName: substance.category.icon)
                    .foregroundStyle(Color(hex: substance.category.color))
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 2) {
                    Text(substance.name).font(.subheadline.bold())
                    Text(substance.category.rawValue.capitalized).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(String(format: "%.0f", substance.commonDose)) \(substance.unit.symbol)")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(.horizontal, DS.screenPadding)
            .padding(.vertical, 11)
        }
        .buttonStyle(.plain)
        .pressFeedback()
    }

    private func doseForm(_ substance: Substance) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // Substance header
                HStack(spacing: 14) {
                    Image(systemName: substance.category.icon)
                        .font(.title2).foregroundStyle(Color(hex: substance.category.color))
                    VStack(alignment: .leading) {
                        Text(substance.name).font(.title3.bold())
                        Text(substance.category.rawValue.capitalized).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, DS.screenPadding)
                .padding(.vertical, 14)

                // Route
                VStack(alignment: .leading, spacing: 8) {
                    Text("ROUTE")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(.secondary)
                    Picker("Route", selection: $selectedRoute) {
                        ForEach(substance.routes, id: \.self) { Text($0.displayName).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal, DS.screenPadding)
                .padding(.vertical, 12)

                // Amount
                profileSectionHeader("Amount", color: Color.accent)

                VStack(spacing: 16) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", amount))
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.accent)
                            .contentTransition(.numericText())
                        Text(substance.unit.symbol).font(.title3).foregroundStyle(.secondary)
                    }
                    Slider(value: $amount, in: 0...substance.strongDose * 2,
                           step: substance.unit == .mg ? (substance.commonDose < 10 ? 0.5 : 5) : 1)
                    .tint(Color.accent)
                    HStack(spacing: 8) {
                        quickDoseButton("Light", dose: substance.lightDose)
                        quickDoseButton("Common", dose: substance.commonDose)
                        quickDoseButton("Strong", dose: substance.strongDose)
                    }
                }
                .padding(.horizontal, DS.screenPadding)
                .padding(.vertical, 8)

                Color.clear.frame(height: 80)
            }
        }
        .scrollIndicators(.hidden)
        .background(Color.appBackground)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button { logDose(substance) } label: {
                Text("Log Dose")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(amount <= 0 ? Color.gray : Color.accent.gradient, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
                    .shadow(color: Color.accent.opacity(amount <= 0 ? 0 : 0.2), radius: 8, y: 3)
            }
            .disabled(amount <= 0)
            .padding(.horizontal, DS.screenPadding)
            .padding(.vertical, 12)
            .background(.regularMaterial)
        }
    }

    private func quickDoseButton(_ label: String, dose: Double) -> some View {
        Button { amount = dose } label: {
            VStack(spacing: 4) {
                Text(String(format: "%.0f", dose)).font(.headline)
                Text(label).font(.caption)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 8)
            .background(amount == dose ? Color.accent.opacity(0.15) : .secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
            .foregroundStyle(amount == dose ? Color.accent : .primary)
        }
        .buttonStyle(.plain)
        .pressFeedback()
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
}

#Preview {
    BallerModeView()
        .environment(AppState())
}
