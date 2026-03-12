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

    static let moodOptions = ["😊", "😐", "😵‍💫", "🤢", "😴", "🥳", "😰"]
    static let sideEffectOptions = [
        "Nausea", "Headache", "Jaw clenching", "Anxiety",
        "Sweating", "Heart racing", "Insomnia", "Comedown",
        "Memory gaps", "Dehydration", "Paranoia", "None"
    ]
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
