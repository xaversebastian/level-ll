//
//  PersistenceTests.swift
//  LevelElevenTests
//
//  Version: 1.0  |  2026-03-11
//
//  Codable roundtrip tests for core model types.
//

import Testing
import Foundation
@testable import LevelEleven

struct PersistenceTests {

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Tolerance

    @Test func toleranceRoundtripWithLastUsedDate() throws {
        let date = Date(timeIntervalSince1970: 1_741_000_000)
        let tolerance = Tolerance(substanceId: "cocaine", level: 7, lastUsedDate: date)
        let data = try encoder.encode(tolerance)
        let decoded = try decoder.decode(Tolerance.self, from: data)
        #expect(decoded.substanceId == tolerance.substanceId)
        #expect(decoded.level == tolerance.level)
        #expect(decoded.lastUsedDate?.timeIntervalSince1970 == date.timeIntervalSince1970)
    }

    @Test func toleranceRoundtripWithoutLastUsedDate() throws {
        let tolerance = Tolerance(substanceId: "mdma", level: 3)
        let data = try encoder.encode(tolerance)
        let decoded = try decoder.decode(Tolerance.self, from: data)
        #expect(decoded.lastUsedDate == nil)
        #expect(decoded.level == 3)
    }

    // MARK: - Dose

    @Test func doseRoundtripWithNote() throws {
        let dose = Dose(
            profileId: "profile-1",
            substanceId: "cocaine",
            route: .nasal,
            amount: 40,
            timestamp: Date(timeIntervalSince1970: 1_741_000_000),
            note: "pre-party"
        )
        let data = try encoder.encode(dose)
        let decoded = try decoder.decode(Dose.self, from: data)
        #expect(decoded.note == "pre-party")
        #expect(decoded.substanceId == "cocaine")
        #expect(decoded.amount == 40)
    }

    @Test func doseRoundtripNoteNilWhenEmpty() throws {
        let dose = Dose(
            profileId: "profile-1",
            substanceId: "cocaine",
            route: .nasal,
            amount: 40,
            timestamp: Date(),
            note: "   "  // whitespace-only → should be stored as nil
        )
        let data = try encoder.encode(dose)
        let decoded = try decoder.decode(Dose.self, from: data)
        #expect(decoded.note == nil)
    }

    // MARK: - Profile

    @Test func profileRoundtripWithTakeSSRI() throws {
        let profile = Profile(
            name: "Test",
            avatarEmoji: "😎",
            age: 28,
            weightKg: 70,
            sex: .female,
            hasADHD: false,
            takeSSRI: true,
            tolerances: [],
            personalLimit: 6
        )
        let data = try encoder.encode(profile)
        let decoded = try decoder.decode(Profile.self, from: data)
        #expect(decoded.takeSSRI == true)
        #expect(decoded.name == "Test")
    }

    // MARK: - Substance route data

    @Test func cannabisOnsetByRouteRoundtrip() throws {
        guard let cannabis = Substances.byId["cannabis"] else {
            Issue.record("cannabis not found in Substances.byId")
            return
        }
        #expect(cannabis.onset(for: .smoked) == 5, "Cannabis smoked onset should be 5min")
        #expect(cannabis.onset(for: .oral) == 60, "Cannabis oral onset should be 60min")
        #expect(cannabis.duration(for: .smoked) == 120, "Cannabis smoked duration should be 120min")
        #expect(cannabis.duration(for: .oral) == 360, "Cannabis oral duration should be 360min")
    }
}
