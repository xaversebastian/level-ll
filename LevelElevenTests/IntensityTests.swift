//
//  IntensityTests.swift
//  LevelElevenTests
//
//  Version: 1.0  |  2026-03-11
//
//  Unit tests for calculateIntensity(), activeDoses(), and route-specific pharmacokinetics.
//
//  Author: Silja & Xaver
//  Created: 2026-03-11
//

import Testing
import Foundation
@testable import LevelEleven

struct IntensityTests {

    // MARK: - Helpers

    private func makeProfile(toleranceLevel: Int = 5) -> Profile {
        let tolerance = Tolerance(substanceId: "cocaine", level: toleranceLevel)
        return Profile(
            name: "Test",
            avatarEmoji: "😎",
            age: 25,
            weightKg: 75,
            sex: .male,
            hasADHD: false,
            takeSSRI: false,
            tolerances: [tolerance],
            personalLimit: 7
        )
    }

    private func makeDose(substanceId: String,
                          route: DoseRoute = .nasal,
                          amount: Double = 10,
                          minutesAgo: Double = 0) -> Dose {
        Dose(
            profileId: "test",
            substanceId: substanceId,
            route: route,
            amount: amount,
            timestamp: Date().addingTimeInterval(-minutesAgo * 60)
        )
    }

    // MARK: - calculateIntensity basics

    @Test func intensityAtPeakIsPositive() {
        let appState = AppState()
        let profile = makeProfile()
        guard let substance = Substances.byId["cocaine"] else {
            Issue.record("cocaine not found")
            return
        }
        let dose = makeDose(substanceId: "cocaine", route: .nasal, amount: 40, minutesAgo: 20)
        let intensity = appState.calculateIntensity(dose: dose, substance: substance, minutesAgo: 20, profile: profile)
        #expect(intensity > 1.0, "Peak intensity for 40mg cocaine should be > 1.0, got \(intensity)")
        #expect(intensity < 8.0, "Peak intensity should be < 8.0 (sane upper bound)")
    }

    @Test func intensityDecaysOverTime() {
        let appState = AppState()
        let profile = makeProfile()
        guard let substance = Substances.byId["cocaine"] else {
            Issue.record("cocaine not found")
            return
        }
        let dose40mg = makeDose(substanceId: "cocaine", route: .nasal, amount: 40)
        let peak = appState.calculateIntensity(dose: dose40mg, substance: substance, minutesAgo: 20, profile: profile)
        let late = appState.calculateIntensity(dose: dose40mg, substance: substance, minutesAgo: 200, profile: profile)
        #expect(peak > late, "Intensity at peak (\(peak)) should be greater than 200min later (\(late))")
    }

    @Test func intensityZeroBeforeOnset() {
        let appState = AppState()
        let profile = makeProfile()
        guard let substance = Substances.byId["cocaine"] else {
            Issue.record("cocaine not found")
            return
        }
        let dose = makeDose(substanceId: "cocaine", route: .nasal, amount: 40)
        let preonset = appState.calculateIntensity(dose: dose, substance: substance, minutesAgo: 2, profile: profile)
        #expect(preonset < 0.3, "Intensity in early onset should be small (< 0.3), got \(preonset)")
    }

    // MARK: - Route-specific pharmacokinetics

    @Test func cannabisSmokesOnsetFasterThanOral() {
        let appState = AppState()
        let profile = makeProfile()
        guard let cannabis = Substances.byId["cannabis"] else {
            Issue.record("cannabis not found")
            return
        }
        let smoked = makeDose(substanceId: "cannabis", route: .smoked, amount: 0.1)
        let oral   = makeDose(substanceId: "cannabis", route: .oral,   amount: 0.1)
        let smokedAt10 = appState.calculateIntensity(dose: smoked, substance: cannabis, minutesAgo: 10, profile: profile)
        let oralAt10   = appState.calculateIntensity(dose: oral,   substance: cannabis, minutesAgo: 10, profile: profile)
        #expect(smokedAt10 > oralAt10, "Smoked cannabis at 10min should be stronger than oral (\(smokedAt10) vs \(oralAt10))")
    }

    @Test func cannabisOralOutlastsSmoked() {
        let appState = AppState()
        let profile = makeProfile()
        guard let cannabis = Substances.byId["cannabis"] else {
            Issue.record("cannabis not found")
            return
        }
        let smoked = makeDose(substanceId: "cannabis", route: .smoked, amount: 0.1)
        let oral   = makeDose(substanceId: "cannabis", route: .oral,   amount: 0.1)
        // At 150min: smoked duration (~120min) has passed, oral peak (~150min) still active
        let smokedAt150 = appState.calculateIntensity(dose: smoked, substance: cannabis, minutesAgo: 150, profile: profile)
        let oralAt150   = appState.calculateIntensity(dose: oral,   substance: cannabis, minutesAgo: 150, profile: profile)
        #expect(oralAt150 > smokedAt150, "Oral cannabis at 150min should outlast smoked (\(oralAt150) vs \(smokedAt150))")
    }

    // MARK: - activeDoses window

    @Test func activeDosesExcludesOldDoses() {
        let appState = AppState()
        // Cocaine duration: 60min + 3×halflife(90min) = 330min total active window
        // A dose taken 400min ago should not be active
        let dose = Dose(
            profileId: "p1",
            substanceId: "cocaine",
            route: .nasal,
            amount: 40,
            timestamp: Date().addingTimeInterval(-400 * 60)
        )
        appState.doses = [dose]
        let active = appState.activeDoses(for: "p1")
        #expect(active.isEmpty, "Cocaine dose taken 400min ago should not be active")
    }

    @Test func activeDosesIncludesRecentDoses() {
        let appState = AppState()
        let dose = Dose(
            profileId: "p1",
            substanceId: "cocaine",
            route: .nasal,
            amount: 40,
            timestamp: Date().addingTimeInterval(-30 * 60)
        )
        appState.doses = [dose]
        let active = appState.activeDoses(for: "p1")
        #expect(active.count == 1, "Cocaine dose taken 30min ago should be active")
    }
}
