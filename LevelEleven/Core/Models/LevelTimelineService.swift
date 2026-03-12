//
//  LevelTimelineService.swift
//  LevelEleven
//
//  Version: 1.0  |  2026-03-11
//
//  Gemeinsamer Service für Level-Timeline-Berechnung.
//  Vorher dupliziert in BallerModeView (LiveProfileLevelData / calculateLiveLevelTimeline)
//  und SessionDetailView (ProfileLevelData / calculateLevelTimeline).
//

import Foundation

// MARK: - Shared Data Structs

struct LevelPoint: Identifiable {
    let id = UUID()
    let time: Date
    let level: Double
}

struct ProfileLevelTimeline: Identifiable {
    let id = UUID()
    let profileId: String
    let name: String
    let points: [LevelPoint]
}

// MARK: - Service

enum LevelTimelineService {

    /// Baut eine Level-Timeline für ein einzelnes Profil von `start` bis `end` in `interval`-Schritten.
    static func buildTimeline(
        for profile: Profile,
        from start: Date,
        to end: Date,
        appState: AppState,
        interval: TimeInterval = 10 * 60
    ) -> ProfileLevelTimeline {
        var points: [LevelPoint] = []
        var time = start
        while time <= end {
            let level = appState.currentLevel(for: profile, at: time)
            points.append(LevelPoint(time: time, level: level))
            time = time.addingTimeInterval(interval)
        }
        // Endpunkt immer anhängen (vermeidet Lücke wenn `end` nicht exakt auf Intervall fällt)
        if points.last?.time != end {
            let level = appState.currentLevel(for: profile, at: end)
            points.append(LevelPoint(time: end, level: level))
        }
        return ProfileLevelTimeline(profileId: profile.id, name: profile.name, points: points)
    }

    /// Berechnet den Peak-Level eines Profils zwischen `start` und `end` (5-min Sampling).
    static func peakLevel(
        for profile: Profile,
        from start: Date,
        to end: Date,
        appState: AppState,
        interval: TimeInterval = 5 * 60
    ) -> Double {
        var maxLevel: Double = 0
        var time = start
        while time <= end {
            let level = appState.currentLevel(for: profile, at: time)
            if level > maxLevel { maxLevel = level }
            time = time.addingTimeInterval(interval)
        }
        let finalLevel = appState.currentLevel(for: profile, at: end)
        if finalLevel > maxLevel { maxLevel = finalLevel }
        return maxLevel
    }

    /// Berechnet den maximalen Gruppen-Level über alle Profile (für Statistiken).
    static func maxGroupLevel(
        for profiles: [Profile],
        from start: Date,
        to end: Date,
        appState: AppState,
        interval: TimeInterval = 5 * 60
    ) -> Double {
        profiles.map { peakLevel(for: $0, from: start, to: end, appState: appState, interval: interval) }
                .max() ?? 0
    }
}
