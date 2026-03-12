//
//  Dose.swift
//  LevelEleven
//
//  Version: 1.0  |  2026-03-11
//
//  Einzelnes Einnahme-Ereignis (immutable Value-Type).
//  Enthält UUID, profileId (Referenz auf Profile.id), substanceId (Referenz auf Substance.id),
//  DoseRoute, Menge (in der substanzspezifischen Einheit) und Zeitstempel.
//  minutesAgo() berechnet die verstrichene Zeit relativ zu einem Referenzdatum.
//
//  HINWEIS: Negative Dosen und Zukunft-Timestamps werden im Init abgefangen.
//  DoseRoute-Enum ist in Substance.swift definiert.
//  Doses werden gesammelt in AppState.doses persistiert (Codable + UserDefaults).
//

import Foundation

struct Dose: Identifiable, Codable, Hashable {
    let id: String
    let profileId: String
    let substanceId: String
    let route: DoseRoute
    let amount: Double
    let timestamp: Date
    /// Optionale Notiz (Kontext, Ort, Stimmung, …)
    var note: String?

    init(
        id: String = UUID().uuidString,
        profileId: String,
        substanceId: String,
        route: DoseRoute,
        amount: Double,
        timestamp: Date = Date(),
        note: String? = nil
    ) {
        self.id = id
        self.profileId = profileId
        self.substanceId = substanceId
        self.route = route
        self.amount = max(0, amount) // prevent negative doses
        self.timestamp = min(timestamp, Date()) // prevent future timestamps
        self.note = note?.trimmingCharacters(in: .whitespaces).nilIfEmpty
    }

    func minutesAgo(from date: Date = Date()) -> Double {
        date.timeIntervalSince(timestamp) / 60.0
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
