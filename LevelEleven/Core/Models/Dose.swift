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
        self.amount = amount
        self.timestamp = timestamp
    }
    
    func minutesAgo(from date: Date = Date()) -> Double {
        date.timeIntervalSince(timestamp) / 60.0
    }
}
