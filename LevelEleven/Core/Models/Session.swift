// Session.swift — LevelEleven
// v2.0 | 2026-03-12 17:18
// - Added SessionFeedback model (deferrable post-session feedback)
// - Added feedback field to BallerSession
// - Stripped legacy comments, added structured header
//

import Foundation

struct SessionParticipant: Identifiable, Codable, Hashable {
    let profileId: String
    var isActive: Bool
    var joinedAt: Date
    var leftAt: Date?

    var id: String { profileId }

    init(profileId: String) {
        self.profileId = profileId
        self.isActive = true
        self.joinedAt = Date()
        self.leftAt = nil
    }

    mutating func leave() {
        isActive = false
        leftAt = Date()
    }

    mutating func rejoin() {
        isActive = true
        leftAt = nil
        joinedAt = Date()
    }
}

// MARK: - Session Feedback

struct SessionFeedback: Codable, Hashable {
    var overallRating: Int // 1-5 stars
    var mood: String // emoji
    var sideEffects: [String]
    var notes: String
    var submittedAt: Date
    /// Per-substance tolerance adjustments applied after feedback (substanceId → delta)
    var toleranceAdjustments: [String: Int]?

    static let moodOptions = ["😊", "😐", "😵‍💫", "🤢", "😴", "🥳", "😰"]
    static let sideEffectOptions = [
        "Nausea", "Headache", "Jaw clenching", "Anxiety",
        "Sweating", "Heart racing", "Insomnia", "Comedown",
        "Memory gaps", "Dehydration", "Paranoia", "None"
    ]

    /// Side effects that indicate the experience was too intense
    static let intenseSideEffects: Set<String> = [
        "Nausea", "Anxiety", "Heart racing", "Memory gaps", "Paranoia"
    ]

    /// Compute tolerance suggestions based on rating + side effects + peak levels
    static func suggestToleranceAdjustments(
        rating: Int,
        sideEffects: Set<String>,
        substancesUsed: [String],
        peakLevelPerSubstance: [String: Double]
    ) -> [String: Int] {
        var adjustments: [String: Int] = [:]
        let hasIntenseSideEffects = !sideEffects.isDisjoint(with: intenseSideEffects)
        let noneSelected = sideEffects.contains("None")

        for substanceId in substancesUsed {
            let peak = peakLevelPerSubstance[substanceId] ?? 0

            if rating <= 2 && (hasIntenseSideEffects || peak >= 7) {
                // Too intense → suggest lowering tolerance (means lower future doses)
                adjustments[substanceId] = -1
            } else if rating >= 4 && !hasIntenseSideEffects && (noneSelected || sideEffects.isEmpty) && peak <= 5 {
                // Comfortable, low peak, no bad effects → suggest raising tolerance
                adjustments[substanceId] = 1
            }
            // Rating 3 or mixed signals → no suggestion
        }
        return adjustments
    }
}

// MARK: - Baller Session

struct BallerSession: Identifiable, Codable {
    let id: String
    var name: String
    var participants: [SessionParticipant]
    var startedAt: Date
    var endedAt: Date?
    var isActive: Bool
    var feedback: SessionFeedback?
    var checkIns: [SessionCheckIn]
    var isManual: Bool

    var participantIds: [String] {
        participants.filter { $0.isActive }.map { $0.profileId }
    }

    var allParticipantIds: [String] {
        participants.map { $0.profileId }
    }

    var removedParticipantIds: [String] {
        participants.filter { !$0.isActive }.map { $0.profileId }
    }

    init(id: String = UUID().uuidString, name: String, participantIds: [String]) {
        self.id = id
        self.name = name
        self.participants = participantIds.map { SessionParticipant(profileId: $0) }
        self.startedAt = Date()
        self.endedAt = nil
        self.isActive = true
        self.feedback = nil
        self.checkIns = []
        self.isManual = false
    }

    /// Init for manually created past sessions
    init(id: String = UUID().uuidString, name: String, participantIds: [String],
         startedAt: Date, endedAt: Date, substanceIds: [String] = []) {
        self.id = id
        self.name = name
        self.participants = participantIds.map { SessionParticipant(profileId: $0) }
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.isActive = false
        self.feedback = nil
        self.checkIns = []
        self.isManual = true
    }

    // Backward-compatible decoder
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        participants = try container.decode([SessionParticipant].self, forKey: .participants)
        startedAt = try container.decode(Date.self, forKey: .startedAt)
        endedAt = try container.decodeIfPresent(Date.self, forKey: .endedAt)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        feedback = try container.decodeIfPresent(SessionFeedback.self, forKey: .feedback)
        checkIns = try container.decodeIfPresent([SessionCheckIn].self, forKey: .checkIns) ?? []
        isManual = try container.decodeIfPresent(Bool.self, forKey: .isManual) ?? false
    }

    var isArchived: Bool {
        !isActive && endedAt != nil
    }

    var hasFeedback: Bool { feedback != nil }

    var durationMinutes: Double {
        let endTime = endedAt ?? Date()
        return endTime.timeIntervalSince(startedAt) / 60.0
    }

    var durationFormatted: String {
        let hours = Int(durationMinutes) / 60
        let mins = Int(durationMinutes) % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }

    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: startedAt)
    }

    mutating func addParticipant(_ profileId: String) {
        if let idx = participants.firstIndex(where: { $0.profileId == profileId }) {
            participants[idx].rejoin()
        } else {
            participants.append(SessionParticipant(profileId: profileId))
        }
    }

    mutating func removeParticipant(_ profileId: String) {
        if let idx = participants.firstIndex(where: { $0.profileId == profileId }) {
            participants[idx].leave()
        }
    }

    func isParticipantActive(_ profileId: String) -> Bool {
        participants.first(where: { $0.profileId == profileId })?.isActive ?? false
    }

    mutating func end() {
        isActive = false
        endedAt = Date()
    }

    mutating func resume() {
        isActive = true
        endedAt = nil
    }
}
