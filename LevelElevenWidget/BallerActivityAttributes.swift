//
//  BallerActivityAttributes.swift
//  LevelEleven
//
//  Version: 1.0  |  2026-03-11
//
//  ActivityKit-Typen für die Baller-Mode-Live-Activity (iOS 16.2+).
//  BallerActivityAttributes: statische Attribute (sessionName, startDate).
//  ContentState: dynamisch aktualisierbare Werte (participantLevels, totalDoses,
//  highestLevel, participantCount). ParticipantLevel: Name, Emoji, Level je Person.
//
//  SETUP: Widget Extension Target erstellen, NSSupportsLiveActivities = YES in beiden
//  Info.plist-Dateien (App + Widget) setzen.
//  Diese Datei muss BEIDEN Targets (App + Widget) zugeordnet sein.
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
