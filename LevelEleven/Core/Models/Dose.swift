// Dose.swift — LevelEleven
// v2.0 | 2026-03-12 17:18
// - Single dose event value type with profile/substance refs, route, amount, timestamp
// - Stripped legacy comments, added structured header
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
