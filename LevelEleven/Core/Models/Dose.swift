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
//  Author: Silja & Xaver
//  Created: 2026-01-04
//

import Foundation

struct Dose: Identifiable, Codable, Hashable {
    let id: String
    let profileId: String
    let substanceId: String
    let route: DoseRoute
    let amount: Double
    let timestamp: Date
    
    init(
        id: String = UUID().uuidString,
        profileId: String,
        substanceId: String,
        route: DoseRoute,
        amount: Double,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.profileId = profileId
        self.substanceId = substanceId
        self.route = route
        self.amount = max(0, amount) // prevent negative doses
        self.timestamp = min(timestamp, Date()) // prevent future timestamps
    }
    
    func minutesAgo(from date: Date = Date()) -> Double {
        date.timeIntervalSince(timestamp) / 60.0
    }
}
