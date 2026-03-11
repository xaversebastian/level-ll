//
//  AppState.swift
//  LevelEleven
//
//  Version: 1.1  |  2026-03-11
//
//  Zentraler App-State als @Observable-Klasse (iOS 17+).
//  Verwaltet Profile, Doses, aktive Session und sessionHistory.
//  Persistenz über UserDefaults + JSON (alle Typen sind Codable).
//  Views greifen per @Environment(AppState.self) darauf zu – kein EnvironmentObject nötig.
//  Kapselt außerdem Live-Activity-Start/-Stop/-Update für Baller Mode.
//
//  HINWEIS: @Observable ersetzt ObservableObject; keine @Published Properties erforderlich.
//  UserDefaults-Keys sind als private StorageKey-Enum definiert.
//  currentLevel() und levelColor() können direkt aus Views aufgerufen werden.
//
//  Author: Silja & Xaver / ChatGPT 5 – K3/4
//  Created: 2026-02-23
//

import Foundation
import SwiftUI
#if canImport(ActivityKit)
import ActivityKit
#endif

@Observable
final class AppState {
    // MARK: - Stored State

    var profiles: [Profile] = []
    var doses: [Dose] = []
    var activeProfileId: String?

    var activeSession: BallerSession?
    var sessionHistory: [BallerSession] = []
    var liveActivityEnabled: Bool = true

    // MARK: - Persistence Keys

    private enum StorageKey {
        static let profiles = "profiles"
        static let doses = "doses"
        static let activeProfileId = "activeProfileId"

        static let sessionHistory = "sessionHistory"
        static let activeSession = "activeSession"
        static let liveActivityEnabled = "liveActivityEnabled"
    }

    // MARK: - Init

    init() {
        // Load persisted state first (so defaults don't overwrite persisted data).
        loadCoreState()

        // If nothing persisted yet, create defaults once.
        if profiles.isEmpty {
            setupDefaultProfiles()
            saveCoreState()
        } else {
            // Ensure activeProfileId points to an existing profile.
            if let activeId = activeProfileId, profiles.contains(where: { $0.id == activeId }) {
                // ok
            } else {
                activeProfileId = profiles.first?.id
            }
            normalizeActiveProfileFlag()
        }

        migrateAvatarEmojis()

        loadSessionHistory()
        loadActiveSession()
        loadLiveActivityEnabled()
    }

    // MARK: - HomeView Convenience API

    struct LastDoseSummary {
        let substance: String
        let elapsed: String
    }

    func lastDose(for profileId: String, at date: Date = Date()) -> Dose? {
        // Most recent dose for this profile up to 'date'
        doses
            .filter { $0.profileId == profileId && $0.timestamp <= date }
            .max(by: { $0.timestamp < $1.timestamp })
    }

    func lastDoseSummary(for profileId: String, now: Date = Date()) -> LastDoseSummary {
        guard let d = lastDose(for: profileId, at: now) else {
            return LastDoseSummary(substance: "—", elapsed: "—")
        }

        let substanceName: String = {
            // Try common fields, fall back safely.
            if let s = Substances.byId[d.substanceId] {
                // Prefer shortName if available in your codebase, else name, else id.
                // (We avoid assuming the exact model; these compile only if property exists.)
                // We'll do the safest: use id-derived fallback when anything is uncertain.
                // Since we can't reflect at runtime in Swift, use the fields we KNOW appear in HomeView:
                // HomeView uses `Substances.byId[dose.substanceId]` and then `substance.shortName`.
                return s.shortName
            }
            return d.substanceId
        }()

        let elapsedString = formatElapsed(since: d.timestamp, now: now)

        return LastDoseSummary(substance: substanceName, elapsed: elapsedString)
    }

    private func formatElapsed(since timestamp: Date, now: Date) -> String {
        let seconds = max(0, now.timeIntervalSince(timestamp))
        let minutes = Int(seconds / 60)

        if minutes < 1 { return "just now" }
        if minutes < 60 { return "\(minutes)m" }

        let hours = minutes / 60
        let rem = minutes % 60
        if hours < 24 {
            return rem == 0 ? "\(hours)h" : "\(hours)h \(rem)m"
        }

        let days = hours / 24
        let remH = hours % 24
        return remH == 0 ? "\(days)d" : "\(days)d \(remH)h"
    }

    // MARK: - Core State Persistence (Profiles / Doses / Active Profile)

    private func saveCoreState() {
        saveProfiles()
        saveDoses()
        saveActiveProfileId()
    }

    private func loadCoreState() {
        loadProfiles()
        loadDoses()
        loadActiveProfileId()
    }

    private func saveProfiles() {
        do {
            let data = try JSONEncoder().encode(profiles)
            UserDefaults.standard.set(data, forKey: StorageKey.profiles)
        } catch {
            #if DEBUG
            print("[AppState] saveProfiles failed: \(error)")
            #endif
        }
    }

    private func loadProfiles() {
        guard let data = UserDefaults.standard.data(forKey: StorageKey.profiles) else { return }
        do {
            profiles = try JSONDecoder().decode([Profile].self, from: data)
        } catch {
            #if DEBUG
            print("[AppState] loadProfiles decode failed: \(error) — falling back to defaults")
            #endif
        }
    }

    private func saveDoses() {
        do {
            let data = try JSONEncoder().encode(doses)
            UserDefaults.standard.set(data, forKey: StorageKey.doses)
        } catch {
            #if DEBUG
            print("[AppState] saveDoses failed: \(error)")
            #endif
        }
    }

    private func loadDoses() {
        guard let data = UserDefaults.standard.data(forKey: StorageKey.doses) else { return }
        do {
            doses = try JSONDecoder().decode([Dose].self, from: data)
        } catch {
            #if DEBUG
            print("[AppState] loadDoses decode failed: \(error) — doses cleared")
            #endif
        }
    }

    private func saveActiveProfileId() {
        if let id = activeProfileId {
            UserDefaults.standard.set(id, forKey: StorageKey.activeProfileId)
        } else {
            UserDefaults.standard.removeObject(forKey: StorageKey.activeProfileId)
        }
    }

    private func loadActiveProfileId() {
        activeProfileId = UserDefaults.standard.string(forKey: StorageKey.activeProfileId)
    }

    private func normalizeActiveProfileFlag() {
        guard let activeId = activeProfileId else { return }
        for i in profiles.indices {
            profiles[i].isActive = profiles[i].id == activeId
        }
    }

    // MARK: - Session Management

    func startSession(name: String, participantIds: [String]) {
        activeSession = BallerSession(name: name, participantIds: participantIds)
        saveActiveSession()
        startLiveActivity()
    }

    func endSession() {
        guard var session = activeSession else { return }
        session.end()
        sessionHistory.insert(session, at: 0)
        saveSessionHistory()
        activeSession = nil
        saveActiveSession()
        endLiveActivity()
    }

    func resumeSession(_ session: BallerSession) {
        if activeSession != nil {
            endSession()
        }
        var resumed = session
        resumed.resume()
        activeSession = resumed
        sessionHistory.removeAll { $0.id == session.id }
        saveSessionHistory()
        saveActiveSession()
        startLiveActivity()
    }

    func deleteSession(_ sessionId: String) {
        sessionHistory.removeAll { $0.id == sessionId }
        saveSessionHistory()
    }

    func addSessionParticipant(_ profileId: String) {
        activeSession?.addParticipant(profileId)
        saveActiveSession()
        updateLiveActivity()
    }

    func removeSessionParticipant(_ profileId: String) {
        activeSession?.removeParticipant(profileId)
        saveActiveSession()
        updateLiveActivity()
    }

    // MARK: - Session Persistence

    private func saveSessionHistory() {
        do {
            let data = try JSONEncoder().encode(sessionHistory)
            UserDefaults.standard.set(data, forKey: StorageKey.sessionHistory)
        } catch {
            #if DEBUG
            print("[AppState] saveSessionHistory failed: \(error)")
            #endif
        }
    }

    private func loadSessionHistory() {
        guard let data = UserDefaults.standard.data(forKey: StorageKey.sessionHistory) else { return }
        do {
            sessionHistory = try JSONDecoder().decode([BallerSession].self, from: data)
        } catch {
            #if DEBUG
            print("[AppState] loadSessionHistory decode failed: \(error) — history cleared")
            #endif
        }
    }

    func saveActiveSession() {
        if let session = activeSession {
            do {
                let data = try JSONEncoder().encode(session)
                UserDefaults.standard.set(data, forKey: StorageKey.activeSession)
            } catch {
                #if DEBUG
                print("[AppState] saveActiveSession failed: \(error)")
                #endif
            }
        } else {
            UserDefaults.standard.removeObject(forKey: StorageKey.activeSession)
        }
    }

    private func loadActiveSession() {
        guard let data = UserDefaults.standard.data(forKey: StorageKey.activeSession) else { return }
        do {
            let session = try JSONDecoder().decode(BallerSession.self, from: data)
            if session.isActive {
                activeSession = session
            }
        } catch {
            #if DEBUG
            print("[AppState] loadActiveSession decode failed: \(error) — no active session restored")
            #endif
        }
    }

    func sessionDoses(for session: BallerSession) -> [Dose] {
        // Include doses from ALL participants (active + removed)
        doses.filter { dose in
            session.allParticipantIds.contains(dose.profileId) &&
            dose.timestamp >= session.startedAt &&
            (session.endedAt == nil || dose.timestamp <= session.endedAt!)
        }
    }

    // MARK: - Emoji Migration

    /// Fixes avatarEmojis that don't render on all iOS versions.
    /// Some standalone person emojis (🧑, 👩 without skin tone) render as [?] on certain devices.
    private func migrateAvatarEmojis() {
        // Known problematic emojis → safe replacements
        let emojiReplacements: [String: String] = [
            "\u{1F9D1}": "😎",   // 🧑 (Person) → 😎
            "\u{1F469}": "🥰",   // 👩 (Woman) → 🥰
        ]

        var needsSave = false
        for i in profiles.indices {
            if let replacement = emojiReplacements[profiles[i].avatarEmoji] {
                profiles[i].avatarEmoji = replacement
                needsSave = true
            }
            // Also fix empty or whitespace-only emojis
            if profiles[i].avatarEmoji.trimmingCharacters(in: .whitespaces).isEmpty {
                profiles[i].avatarEmoji = "😎"
                needsSave = true
            }
        }
        if needsSave {
            saveProfiles()
        }
    }

    // MARK: - Default Profiles

    private func setupDefaultProfiles() {
        let xaver = Profile(
            id: "xaver",
            name: "Xaver",
            isActive: true,
            avatarEmoji: "😎",
            age: 31,
            weightKg: 83,
            sex: .male,
            hasADHD: true,
            tolerances: [
                Tolerance(substanceId: "cocaine", level: 11),
                Tolerance(substanceId: "amphetamine", level: 8),
                Tolerance(substanceId: "mdma", level: 8),
                Tolerance(substanceId: "ketamine", level: 1),
                Tolerance(substanceId: "3mmc", level: 7),
                Tolerance(substanceId: "4mmc", level: 9)
            ],
            favorites: ["cocaine", "amphetamine", "alcohol"],
            personalLimit: 8
        )

        let silja = Profile(
            id: "silja",
            name: "Silja",
            isActive: false,
            avatarEmoji: "🥰",
            age: 35,
            weightKg: 57,
            sex: .female,
            tolerances: [
                Tolerance(substanceId: "cocaine", level: 9),
                Tolerance(substanceId: "amphetamine", level: 11),
                Tolerance(substanceId: "ketamine", level: 0),
                Tolerance(substanceId: "3mmc", level: 9),
                Tolerance(substanceId: "4mmc", level: 7)
            ],
            favorites: ["amphetamine", "mdma"],
            personalLimit: 7
        )

        profiles = [xaver, silja]
        activeProfileId = xaver.id
        normalizeActiveProfileFlag()
    }

    var activeProfile: Profile? {
        profiles.first { $0.id == activeProfileId }
    }

    func setActiveProfile(_ profile: Profile) {
        activeProfileId = profile.id
        normalizeActiveProfileFlag()
        saveActiveProfileId()
        saveProfiles()
    }

    func addProfile(_ profile: Profile) {
        profiles.append(profile)
        saveProfiles()

        if activeProfileId == nil {
            activeProfileId = profile.id
            normalizeActiveProfileFlag()
            saveActiveProfileId()
            saveProfiles()
        }
    }

    func updateProfile(_ profile: Profile) {
        if let idx = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[idx] = profile
            normalizeActiveProfileFlag()
            saveProfiles()
        }
    }

    func deleteProfile(_ id: String) {
        profiles.removeAll { $0.id == id }
        doses.removeAll { $0.profileId == id }

        if activeProfileId == id {
            activeProfileId = profiles.first?.id
            normalizeActiveProfileFlag()
            saveActiveProfileId()
        }

        saveProfiles()
        saveDoses()
    }

    // MARK: - Dose Management

    func addDose(_ dose: Dose) {
        doses.append(dose)
        saveDoses()

        if activeSession != nil {
            saveActiveSession()
            updateLiveActivity()
        }
    }

    func logDose(substanceId: String, route: DoseRoute, amount: Double) {
        guard let profileId = activeProfileId else { return }
        let dose = Dose(
            profileId: profileId,
            substanceId: substanceId,
            route: route,
            amount: amount,
            timestamp: Date()
        )
        doses.append(dose)
        saveDoses()
    }

    func activeDoses(for profileId: String, at date: Date = Date()) -> [Dose] {
        doses.filter { dose in
            guard dose.profileId == profileId,
                  let substance = Substances.byId[dose.substanceId] else { return false }
            let minutesAgo = dose.minutesAgo(from: date)
            // Active window: peak duration + 3 half-lives (≈2.5% remaining — pharmacologically negligible)
            let activeWindow = substance.durationMinutes + substance.halfLifeMinutes * 3
            return minutesAgo >= 0 && minutesAgo < activeWindow
        }
    }

    func recentDoses(for profileId: String, hours: Double = 24) -> [Dose] {
        let cutoffSeconds = hours * 3600
        return doses.filter { dose in
            dose.profileId == profileId &&
            dose.minutesAgo() < (cutoffSeconds / 60)
        }.sorted { $0.timestamp > $1.timestamp }
    }

    func clearDoses(for profileId: String) {
        doses.removeAll { $0.profileId == profileId }
        saveDoses()
    }

    // MARK: - Level Calculations

    func currentLevel(for profile: Profile? = nil, at date: Date = Date()) -> Double {
        let p = profile ?? activeProfile
        guard let profile = p else { return 0 }

        let active = activeDoses(for: profile.id, at: date)
        guard !active.isEmpty else { return 0 }

        var totalIntensity: Double = 0

        for dose in active {
            guard let substance = Substances.byId[dose.substanceId] else { continue }

            let minutesAgo = dose.minutesAgo(from: date)
            let intensity = calculateIntensity(
                dose: dose,
                substance: substance,
                minutesAgo: minutesAgo,
                profile: profile
            )
            totalIntensity += intensity
        }

        return min(11, totalIntensity)
    }

    private func calculateIntensity(
        dose: Dose,
        substance: Substance,
        minutesAgo: Double,
        profile: Profile
    ) -> Double {
        guard minutesAgo >= 0 else { return 0 }

        let onset = substance.onsetMinutes
        let peak = substance.peakMinutes
        let duration = substance.durationMinutes
        let halfLife = substance.halfLifeMinutes

        var phase: Double = 0

        if minutesAgo < onset {
            // Onset: 0 → 0.3
            phase = minutesAgo / onset * 0.3
        } else if minutesAgo < peak {
            // Rising: 0.3 → 1.0
            let progress = (minutesAgo - onset) / (peak - onset)
            phase = 0.3 + progress * 0.7
        } else if minutesAgo < duration {
            // Falling: 1.0 → 0.2
            let progress = (minutesAgo - peak) / (duration - peak)
            phase = 1.0 - progress * 0.8
        } else {
            // Exponential decay using substance half-life (pharmacokinetically accurate)
            phase = 0.2 * pow(0.5, (minutesAgo - duration) / halfLife)
        }

        let doseRatio = dose.amount / substance.commonDose
        let bioavail = dose.route.bioavailability
        let toleranceFactor = 1.0 / profile.toleranceFactor(for: substance.id)
        let metabolism = profile.metabolismFactor

        let baseIntensity = doseRatio * bioavail * toleranceFactor * metabolism
        let scaledIntensity = baseIntensity * 3.5

        return scaledIntensity * phase
    }

    func levelDescription(for level: Double) -> String {
        switch Int(level.rounded()) {
        case 0: return "Sober"
        case 1: return "Threshold"
        case 2: return "Light"
        case 3: return "Light+"
        case 4: return "Moderate"
        case 5: return "Moderate+"
        case 6: return "Strong"
        case 7: return "Strong+"
        case 8: return "Heavy"
        case 9: return "Very Heavy"
        case 10: return "Extreme"
        case 11: return "Maximum"
        default: return "Unknown"
        }
    }

    func levelColor(for level: Double) -> Color {
        switch Int(level.rounded()) {
        case 0: return .gray
        case 1...2: return .green
        case 3...4: return .yellow
        case 5...6: return .orange
        case 7...8: return .red
        case 9...11: return .levelMagenta
        default: return .gray
        }
    }

    // MARK: - Live Activity Settings

    func setLiveActivityEnabled(_ enabled: Bool) {
        liveActivityEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: StorageKey.liveActivityEnabled)
        if enabled {
            if activeSession != nil {
                startLiveActivity()
            }
        } else {
            endLiveActivity()
        }
    }

    private func loadLiveActivityEnabled() {
        if UserDefaults.standard.object(forKey: StorageKey.liveActivityEnabled) != nil {
            liveActivityEnabled = UserDefaults.standard.bool(forKey: StorageKey.liveActivityEnabled)
        } else {
            liveActivityEnabled = true
        }
    }

    // MARK: - Live Activity (ActivityKit)

    func startLiveActivity() {
        #if canImport(ActivityKit)
        guard liveActivityEnabled else {
            print("[LiveActivity] Disabled in settings")
            return
        }
        guard let session = activeSession else {
            print("[LiveActivity] No active session")
            return
        }

        if #available(iOS 16.2, *) {
            let authInfo = ActivityAuthorizationInfo()
            print("[LiveActivity] areActivitiesEnabled: \(authInfo.areActivitiesEnabled)")
            guard authInfo.areActivitiesEnabled else {
                print("[LiveActivity] Activities not enabled by user")
                return
            }

            for activity in Activity<BallerActivityAttributes>.activities {
                print("[LiveActivity] Ending existing activity: \(activity.id)")
                Task { await activity.end(nil, dismissalPolicy: .immediate) }
            }

            let attributes = BallerActivityAttributes(
                sessionName: session.name,
                startDate: session.startedAt
            )

            let levels = session.participantIds.compactMap { profileId -> BallerActivityAttributes.ParticipantLevel? in
                guard let profile = profiles.first(where: { $0.id == profileId }) else { return nil }
                let level = currentLevel(for: profile)
                return BallerActivityAttributes.ParticipantLevel(
                    name: profile.name,
                    emoji: profile.avatarEmoji,
                    level: level
                )
            }

            let highestLevel = levels.map { $0.level }.max() ?? 0
            let totalDoses = sessionDoses(for: session).count

            let state = BallerActivityAttributes.ContentState(
                participantLevels: levels,
                totalDoses: totalDoses,
                highestLevel: highestLevel,
                participantCount: session.participantIds.count
            )

            print("[LiveActivity] Requesting with \(levels.count) participants, \(totalDoses) doses")

            do {
                let activity = try Activity<BallerActivityAttributes>.request(
                    attributes: attributes,
                    content: ActivityContent(state: state, staleDate: nil),
                    pushType: nil
                )
                print("[LiveActivity] Started successfully: \(activity.id)")
            } catch {
                print("[LiveActivity] Failed to start: \(error)")
            }
        } else {
            print("[LiveActivity] iOS 16.2+ required")
        }
        #endif
    }

    func updateLiveActivity() {
        #if canImport(ActivityKit)
        guard liveActivityEnabled else { return }
        guard let session = activeSession else { return }

        if #available(iOS 16.2, *) {
            let activities = Activity<BallerActivityAttributes>.activities
            guard !activities.isEmpty else {
                print("[LiveActivity] No active activities to update, starting new one")
                startLiveActivity()
                return
            }

            let levels = session.participantIds.compactMap { profileId -> BallerActivityAttributes.ParticipantLevel? in
                guard let profile = profiles.first(where: { $0.id == profileId }) else { return nil }
                let level = currentLevel(for: profile)
                return BallerActivityAttributes.ParticipantLevel(
                    name: profile.name,
                    emoji: profile.avatarEmoji,
                    level: level
                )
            }

            let highestLevel = levels.map { $0.level }.max() ?? 0
            let totalDoses = sessionDoses(for: session).count

            let state = BallerActivityAttributes.ContentState(
                participantLevels: levels,
                totalDoses: totalDoses,
                highestLevel: highestLevel,
                participantCount: session.participantIds.count
            )

            Task {
                for activity in activities {
                    await activity.update(ActivityContent(state: state, staleDate: nil))
                }
            }
        }
        #endif
    }

    func endLiveActivity() {
        #if canImport(ActivityKit)
        if #available(iOS 16.2, *) {
            let activities = Activity<BallerActivityAttributes>.activities
            print("[LiveActivity] Ending \(activities.count) activities")
            Task {
                for activity in activities {
                    await activity.end(nil, dismissalPolicy: .immediate)
                }
            }
        }
        #endif
    }
}
