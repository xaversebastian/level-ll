//
//  Session.swift
//  LevelEleven
//
//  Version: 1.0  |  2026-03-11
//
//  Datenmodell für Baller-Mode-Gruppensessions (lokal, kein Server).
//  BallerSession hält startedAt/endedAt, Teilnehmerliste (SessionParticipant)
//  und liefert berechnete Felder wie durationMinutes, durationFormatted.
//  SessionParticipant trackt joinedAt/leftAt und ob ein Profil noch aktiv teilnimmt.
//  addParticipant() / removeParticipant() erlauben dynamisches Hinzufügen/Entfernen.
//
//  HINWEIS: Sessions werden in AppState.sessionHistory persistiert (Codable + UserDefaults).
//  Doses sind NICHT Teil der Session-Struct – sie werden über AppState.sessionDoses() gefiltert.

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

struct BallerSession: Identifiable, Codable {
    let id: String
    var name: String
    var participants: [SessionParticipant]
    var startedAt: Date
    var endedAt: Date?
    var isActive: Bool
    
    // Computed for backwards compatibility
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
    }
    
    var isArchived: Bool {
        !isActive && endedAt != nil
    }
    
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
        // Check if already exists (was removed before)
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
