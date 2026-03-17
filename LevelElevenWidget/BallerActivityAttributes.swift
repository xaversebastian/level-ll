// BallerActivityAttributes.swift — LevelEleven
// v2.0 | 2026-03-12 17:18
// - ActivityKit types for Session Mode live activity (iOS 16.2+)
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
        /// Number of active warnings (severity >= warning) across all participants
        var warningCount: Int
    }

    struct ParticipantLevel: Codable, Hashable {
        let name: String
        let emoji: String
        let level: Double
        /// Minutes until sober (nil = already sober)
        let minutesToSober: Int?
    }

    let sessionName: String
    let startDate: Date
}
#endif
