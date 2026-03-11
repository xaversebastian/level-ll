//
//  BallerActivityAttributes.swift
//  LevelEleven
//
//  ActivityKit attributes for Baller Mode Live Activity on Lock Screen & Dynamic Island.
//
//  SETUP: Add a Widget Extension target in Xcode, enable "Supports Live Activities" in Info.plist,
//  and add NSSupportsLiveActivities = YES to the main app's Info.plist.
//

#if canImport(ActivityKit)
import ActivityKit
import Foundation

struct BallerActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var participantLevels: [ParticipantLevel]
        var totalDoses: Int
        var highestLevel: Double
        var participantCount: Int
    }
    
    struct ParticipantLevel: Codable, Hashable {
        let name: String
        let emoji: String
        let level: Double
    }
    
    let sessionName: String
    let startDate: Date
}
#endif
