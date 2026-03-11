//
//  AppStateTests.swift
//  LevelElevenTests
//
//  Version: 1.0  |  2026-03-11
//
//  Unit tests for AppState: cache invalidation, tolerance decay, warnings, minutesUntilBaseline.
//
//  Author: Silja & Xaver
//  Created: 2026-03-11
//

import Testing
import Foundation
@testable import LevelEleven

struct AppStateTests {

    private func baseProfile(takeSSRI: Bool = false) -> Profile {
        Profile(
            name: "Test",
            avatarEmoji: "😎",
            age: 25,
            weightKg: 75,
            sex: .male,
            hasADHD: false,
            takeSSRI: takeSSRI,
            tolerances: [],
            personalLimit: 7
        )
    }

    // MARK: - Tolerance Decay

    @Test func toleranceEffectiveLevelTodayUnchanged() {
        let tol = Tolerance(substanceId: "cocaine", level: 8, lastUsedDate: Date())
        #expect(tol.effectiveLevel == 8)
    }

    @Test func toleranceDecayAfter10Days() {
        let tenDaysAgo = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let tol = Tolerance(substanceId: "cocaine", level: 8, lastUsedDate: tenDaysAgo)
        #expect(tol.effectiveLevel == 7, "10 days → -1 decay, expected 7 got \(tol.effectiveLevel)")
    }

    @Test func toleranceDecayAfter20Days() {
        let twentyDaysAgo = Calendar.current.date(byAdding: .day, value: -20, to: Date())!
        let tol = Tolerance(substanceId: "cocaine", level: 8, lastUsedDate: twentyDaysAgo)
        #expect(tol.effectiveLevel == 6, "20 days → -2 decay, expected 6 got \(tol.effectiveLevel)")
    }

    @Test func toleranceDecayAfter35Days() {
        let thirtyFiveDaysAgo = Calendar.current.date(byAdding: .day, value: -35, to: Date())!
        let tol = Tolerance(substanceId: "cocaine", level: 8, lastUsedDate: thirtyFiveDaysAgo)
        #expect(tol.effectiveLevel == 4, "35 days → 50% decay (8/2=4), expected 4 got \(tol.effectiveLevel)")
    }

    @Test func toleranceDecayAfter60Days() {
        let sixtyDaysAgo = Calendar.current.date(byAdding: .day, value: -60, to: Date())!
        let tol = Tolerance(substanceId: "cocaine", level: 8, lastUsedDate: sixtyDaysAgo)
        #expect(tol.effectiveLevel == 0, "60+ days → full decay, expected 0 got \(tol.effectiveLevel)")
    }

    // MARK: - minutesUntilBaseline

    @Test func minutesUntilBaselineNilWhenNoActiveDoses() {
        let appState = AppState()
        let profile = baseProfile()
        appState.profiles = [profile]
        appState.activeProfileId = profile.id
        appState.doses = []
        let result = appState.minutesUntilBaseline(for: profile, from: Date())
        #expect(result == nil, "No active doses → should return nil")
    }

    @Test func minutesUntilBaselinePositiveWithActiveDose() {
        let appState = AppState()
        let profile = baseProfile()
        appState.profiles = [profile]
        appState.activeProfileId = profile.id
        let dose = Dose(
            profileId: profile.id,
            substanceId: "cocaine",
            route: .nasal,
            amount: 100,
            timestamp: Date().addingTimeInterval(-10 * 60)  // 10min ago, still active
        )
        appState.doses = [dose]
        let result = appState.minutesUntilBaseline(for: profile, from: Date())
        #expect(result != nil, "Active dose → minutesUntilBaseline should not be nil")
        if let minutes = result {
            #expect(minutes > 0, "minutesUntilBaseline should be > 0")
        }
    }

    // MARK: - Warnings

    @Test func ssriPlusMDMAisDanger() {
        let profile = baseProfile(takeSSRI: true)
        let now = Date()
        let mdmaDose = Dose(
            profileId: profile.id,
            substanceId: "mdma",
            route: .oral,
            amount: 100,
            timestamp: now.addingTimeInterval(-30 * 60)  // 30min ago
        )
        let warnings = WarningSystem.checkInteractions(
            activeDoses: [mdmaDose],
            allDoses: [mdmaDose],
            profile: profile,
            now: now
        )
        let hasDanger = warnings.contains { $0.severity == .danger }
        #expect(hasDanger, "SSRI + MDMA should produce a danger warning")
    }

    @Test func ghbPlusAlcoholIsDanger() {
        let profile = baseProfile()
        let now = Date()
        let ghbDose = Dose(profileId: profile.id, substanceId: "ghb",     route: .oral, amount: 1.5, timestamp: now.addingTimeInterval(-30 * 60))
        let alcDose = Dose(profileId: profile.id, substanceId: "alcohol",  route: .oral, amount: 3,   timestamp: now.addingTimeInterval(-60 * 60))
        let warnings = WarningSystem.checkInteractions(
            activeDoses: [ghbDose, alcDose],
            allDoses: [ghbDose, alcDose],
            profile: profile,
            now: now
        )
        let hasDanger = warnings.contains { $0.severity == .danger }
        #expect(hasDanger, "GHB + Alcohol should produce a danger warning")
    }

    @Test func ghbReboundWarningWhenNotActive() {
        let profile = baseProfile()
        let now = Date()
        // GHB taken 3h ago – just stopped being active but within 4h rebound window
        let ghbDose = Dose(
            profileId: profile.id,
            substanceId: "ghb",
            route: .oral,
            amount: 1.5,
            timestamp: now.addingTimeInterval(-180 * 60)  // 3h ago
        )
        let warnings = WarningSystem.checkInteractions(
            activeDoses: [],      // not active anymore
            allDoses: [ghbDose],
            profile: profile,
            now: now
        )
        let hasGHBWarning = warnings.contains { $0.title.lowercased().contains("ghb") || $0.title.lowercased().contains("rebound") }
        #expect(hasGHBWarning, "GHB taken 3h ago (not active) should produce a rebound warning")
    }

    // MARK: - Cache invalidation

    @Test func cacheInvalidatedAfterLogDose() {
        let appState = AppState()
        var profile = baseProfile()
        appState.profiles = [profile]
        appState.activeProfileId = profile.id

        // First call primes the cache
        let levelBefore = appState.currentLevel(for: profile, at: Date())

        // Log a dose – should invalidate cache
        appState.logDose(substanceId: "cocaine", route: .nasal, amount: 80)

        // Level should be higher after logging a dose
        // (we can't directly inspect the cache, but re-computing should give different result)
        profile = appState.profiles.first ?? profile
        let levelAfter = appState.currentLevel(for: profile, at: Date())
        #expect(levelAfter > levelBefore, "Level should be higher after logging a dose (cache invalidated)")
    }
}
