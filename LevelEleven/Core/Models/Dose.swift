//
//  Dose.swift
//  LevelEleven
//
//  Dose event tracking.
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
