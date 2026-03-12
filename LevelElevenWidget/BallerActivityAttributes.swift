// BallerActivityAttributes.swift — LevelEleven
// v2.0 | 2026-03-12 17:18
// - ActivityKit types for Baller Mode live activity (iOS 16.2+)
// - Stripped legacy comments, added structured header
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
        /// Anzahl aktiver Warnungen (severity >= warning) über alle Teilnehmer
        var warningCount: Int
    }

    struct ParticipantLevel: Codable, Hashable {
        let name: String
        let emoji: String
        let level: Double
        /// Minuten bis nüchtern (nil = bereits nüchtern)
        let minutesToSober: Int?
    }

    let sessionName: String
    let startDate: Date
}
#endif
