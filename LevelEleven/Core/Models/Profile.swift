// Profile.swift — LevelEleven
// v2.0 | 2026-03-12 17:18
// - Added proLevel (1-5) internal experience rating from onboarding assessment
// - Stripped legacy comments, added structured header
//

import Foundation

enum BiologicalSex: String, Codable, CaseIterable {
    case male, female
    
    var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        }
    }
    
    var metabolismFactor: Double {
        switch self {
        case .male: return 1.0
        case .female: return 0.85
        }
    }
}

struct Tolerance: Codable, Hashable, Identifiable {
    var id: String { substanceId }
    let substanceId: String
    var subjectiveLevel: Int      // 0–11, user-set (onboarding / profile editor)
    var computedLevel: Int        // 0–11, auto-adjusted from consumption behavior
    var lastUsedDate: Date?
    var totalLifetimeDoses: Int = 0

    init(substanceId: String, subjectiveLevel: Int, computedLevel: Int, lastUsedDate: Date? = nil, totalLifetimeDoses: Int = 0) {
        self.substanceId = substanceId
        self.subjectiveLevel = max(0, min(11, subjectiveLevel))
        self.computedLevel = max(0, min(11, computedLevel))
        self.lastUsedDate = lastUsedDate
        self.totalLifetimeDoses = max(0, totalLifetimeDoses)
    }

    /// Convenience init — sets both layers to the same value (migration / backward compat)
    init(substanceId: String, level: Int, lastUsedDate: Date? = nil, totalLifetimeDoses: Int = 0) {
        self.init(substanceId: substanceId, subjectiveLevel: level, computedLevel: level,
                  lastUsedDate: lastUsedDate, totalLifetimeDoses: totalLifetimeDoses)
    }

    // MARK: - Floor (heavy users never decay to 0)

    var floor: Int {
        min(3, totalLifetimeDoses / 50)
    }

    // MARK: - Computed layer after decay

    var decayedComputedLevel: Int {
        guard let lastUsed = lastUsedDate else { return computedLevel }
        let days = Calendar.current.dateComponents([.day], from: lastUsed, to: Date()).day ?? 0
        let decay: Int
        switch days {
        case 0...6:    decay = 0
        case 7...13:   decay = 1
        case 14...27:  decay = 2
        case 28...55:  decay = computedLevel / 2
        case 56...180: decay = (computedLevel * 3) / 4
        default:       decay = max(0, computedLevel - floor)
        }
        return max(floor, computedLevel - decay)
    }

    // MARK: - Effective level (60% subjective + 40% computed after decay)

    var effectiveLevel: Int {
        let blended = Double(subjectiveLevel) * 0.6 + Double(decayedComputedLevel) * 0.4
        return max(0, min(11, Int(blended.rounded())))
    }

    var factor: Double { factorFor(effectiveLevel) }

    private func factorFor(_ lvl: Int) -> Double {
        switch lvl {
        case 0:  return 0.50
        case 1:  return 0.65
        case 2:  return 0.80
        case 3:  return 1.00   // neutral — default for new profiles
        case 4:  return 1.10
        case 5:  return 1.20
        case 6:  return 1.35
        case 7:  return 1.50
        case 8:  return 1.65
        case 9:  return 1.80
        case 10: return 2.00
        case 11: return 2.30
        default: return 1.00
        }
    }

    // MARK: - Codable (backward-compatible)

    private enum CodingKeys: String, CodingKey {
        case substanceId, subjectiveLevel, computedLevel, lastUsedDate, totalLifetimeDoses
        case level // legacy key
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        substanceId = try container.decode(String.self, forKey: .substanceId)
        lastUsedDate = try container.decodeIfPresent(Date.self, forKey: .lastUsedDate)
        totalLifetimeDoses = try container.decodeIfPresent(Int.self, forKey: .totalLifetimeDoses) ?? 0

        if let subjective = try container.decodeIfPresent(Int.self, forKey: .subjectiveLevel),
           let computed = try container.decodeIfPresent(Int.self, forKey: .computedLevel) {
            subjectiveLevel = max(0, min(11, subjective))
            computedLevel = max(0, min(11, computed))
        } else {
            let legacy = try container.decodeIfPresent(Int.self, forKey: .level) ?? 3
            subjectiveLevel = max(0, min(11, legacy))
            computedLevel = max(0, min(11, legacy))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(substanceId, forKey: .substanceId)
        try container.encode(subjectiveLevel, forKey: .subjectiveLevel)
        try container.encode(computedLevel, forKey: .computedLevel)
        try container.encodeIfPresent(lastUsedDate, forKey: .lastUsedDate)
        try container.encode(totalLifetimeDoses, forKey: .totalLifetimeDoses)
    }
}

// MARK: - Wellbeing Scoring

struct SubstanceScore: Codable, Hashable, Identifiable {
    var id: String { substanceId }
    let substanceId: String
    var score: Double = 0         // starts at 0; positive = good, negative = bad
    var dataPoints: Int = 0
    var lastUpdated: Date?
}

struct ComboScore: Codable, Hashable, Identifiable {
    let id: String                // sorted combo key, e.g. "alcohol+cocaine"
    var score: Double = 0
    var dataPoints: Int = 0
    var lastUpdated: Date?

    /// Build a canonical combo key from a set of substance IDs
    static func comboKey(from substanceIds: Set<String>) -> String {
        substanceIds.sorted().joined(separator: "+")
    }
}

// MARK: - Medication

enum MedicationCategory: String, Codable, CaseIterable {
    case heartMedication      // Heart & Blood Pressure
    case opioidPrescription   // Opioid Prescription (BTM)
    case painkillers          // Painkillers
    case bloodThinners        // Blood Thinners
    case antidepressants      // Antidepressants (absorbs SSRI toggle)
    case other                // Other

    var displayName: String {
        switch self {
        case .heartMedication:    return "Heart & Blood Pressure"
        case .opioidPrescription: return "Opioid Prescription (BTM)"
        case .painkillers:        return "Painkillers"
        case .bloodThinners:      return "Blood Thinners"
        case .antidepressants:    return "Antidepressants"
        case .other:              return "Other"
        }
    }

    var icon: String {
        switch self {
        case .heartMedication:    return "heart.fill"
        case .opioidPrescription: return "cross.vial.fill"
        case .painkillers:        return "pills.fill"
        case .bloodThinners:      return "drop.triangle.fill"
        case .antidepressants:    return "brain.head.profile.fill"
        case .other:              return "pill.fill"
        }
    }
}

struct MedicationEntry: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    let category: MedicationCategory
    var isActive: Bool = true
    /// Why this medication interacts with recreational substances
    var interactionInfo: String?
}

struct Profile: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var isActive: Bool
    var isPrimaryUser: Bool
    var avatarEmoji: String
    var age: Int
    var weightKg: Double
    var sex: BiologicalSex
    var isNeurodivergent: Bool
    var takeSSRI: Bool              // kept for backward compat; new code should check medications
    var medications: [MedicationEntry]
    /// Internal experience rating (1=beginner … 5=very experienced). Set during onboarding.
    var proLevel: Int
    var tolerances: [Tolerance]
    var favorites: [String]
    var personalLimit: Int
    var substanceScores: [SubstanceScore]
    var comboScores: [ComboScore]

    /// True if any active medication is an SSRI or SNRI
    var hasSSRI: Bool {
        takeSSRI || medications.contains { $0.isActive && $0.category == .antidepressants &&
            MedicationData.serotonergicMedIds.contains($0.id) }
    }

    /// True if any active medication is an MAOI
    var hasMAOI: Bool {
        medications.contains { $0.isActive && MedicationData.maoiMedIds.contains($0.id) }
    }

    /// True if user takes any active heart medication
    var hasHeartMedication: Bool {
        medications.contains { $0.isActive && $0.category == .heartMedication }
    }

    /// True if user takes any active opioid prescription
    var hasOpioidPrescription: Bool {
        medications.contains { $0.isActive && $0.category == .opioidPrescription }
    }

    /// True if user takes any active blood thinner
    var hasBloodThinners: Bool {
        medications.contains { $0.isActive && $0.category == .bloodThinners }
    }

    /// True if user takes tramadol or tilidin (serotonergic painkillers)
    var hasSerotonergicPainkillers: Bool {
        medications.contains { $0.isActive && MedicationData.serotonergicPainkillerIds.contains($0.id) }
    }

    init(
        id: String = UUID().uuidString,
        name: String,
        isActive: Bool = false,
        isPrimaryUser: Bool = false,
        avatarEmoji: String = "😎",
        age: Int = 30,
        weightKg: Double = 70,
        sex: BiologicalSex = .male,
        isNeurodivergent: Bool = false,
        takeSSRI: Bool = false,
        medications: [MedicationEntry] = [],
        proLevel: Int = 3,
        tolerances: [Tolerance] = [],
        favorites: [String] = [],
        personalLimit: Int? = nil,
        substanceScores: [SubstanceScore] = [],
        comboScores: [ComboScore] = []
    ) {
        self.id = id
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        self.name = trimmed.isEmpty ? "User" : trimmed
        self.isActive = isActive
        self.isPrimaryUser = isPrimaryUser
        self.avatarEmoji = Self.sanitizeEmoji(avatarEmoji)
        self.age = max(13, min(99, age))
        self.weightKg = max(30, min(300, weightKg))
        self.sex = sex
        self.isNeurodivergent = isNeurodivergent
        self.takeSSRI = takeSSRI
        self.medications = medications
        self.proLevel = max(1, min(5, proLevel))
        self.tolerances = tolerances
        self.favorites = favorites
        // Default personal limit scales with experience
        let defaultLimit = Self.defaultPersonalLimit(for: proLevel)
        self.personalLimit = max(1, min(11, personalLimit ?? defaultLimit))
        self.substanceScores = substanceScores
        self.comboScores = comboScores
    }
    
    /// Emojis known to render as "?" on some iOS versions
    private static let brokenEmojis: Set<String> = [
        "\u{1F9D1}", "\u{1F469}", "\u{1F468}", "\u{1FAF1}",
        "\u{1F9D1}\u{200D}\u{1F9B0}", "\u{1F9D1}\u{200D}\u{1F9B1}",
        "\u{1F9D1}\u{200D}\u{1F9B3}", "\u{1F9D1}\u{200D}\u{1F9B2}"
    ]

    static func sanitizeEmoji(_ emoji: String) -> String {
        if emoji.isEmpty || brokenEmojis.contains(emoji) { return "😎" }
        // Use .first to get a full Character (preserves multi-scalar grapheme
        // clusters like skin-tone variants) instead of prefix(1) which may split them.
        guard let first = emoji.first else { return "😎" }
        return String(first)
    }

    // Custom decoder to sanitize avatarEmoji from stored data + backward compat for new fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        isPrimaryUser = try container.decodeIfPresent(Bool.self, forKey: .isPrimaryUser) ?? false
        let rawEmoji = try container.decode(String.self, forKey: .avatarEmoji)
        avatarEmoji = Self.sanitizeEmoji(rawEmoji)
        age = try container.decode(Int.self, forKey: .age)
        weightKg = try container.decode(Double.self, forKey: .weightKg)
        sex = try container.decode(BiologicalSex.self, forKey: .sex)
        isNeurodivergent = try container.decode(Bool.self, forKey: .isNeurodivergent)
        takeSSRI = try container.decodeIfPresent(Bool.self, forKey: .takeSSRI) ?? false
        medications = try container.decodeIfPresent([MedicationEntry].self, forKey: .medications) ?? []
        proLevel = try container.decodeIfPresent(Int.self, forKey: .proLevel) ?? 3
        tolerances = try container.decode([Tolerance].self, forKey: .tolerances)
        favorites = try container.decode([String].self, forKey: .favorites)
        personalLimit = try container.decode(Int.self, forKey: .personalLimit)
        substanceScores = try container.decodeIfPresent([SubstanceScore].self, forKey: .substanceScores) ?? []
        comboScores = try container.decodeIfPresent([ComboScore].self, forKey: .comboScores) ?? []
    }

    static func defaultPersonalLimit(for proLevel: Int) -> Int {
        switch proLevel {
        case 1:  return 5
        case 2:  return 6
        case 3:  return 7
        case 4:  return 8
        case 5:  return 9
        default: return 7
        }
    }

    func tolerance(for substanceId: String) -> Int {
        tolerances.first { $0.substanceId == substanceId }?.effectiveLevel ?? 3
    }

    func tolerance(for category: SubstanceCategory) -> Int {
        let categorySubstances = Substances.all.filter { $0.category == category }
        let levels = categorySubstances.compactMap { substance -> Int? in
            tolerances.first { $0.substanceId == substance.id }?.effectiveLevel
        }
        return levels.max() ?? 3
    }

    /// Score for a specific substance (0 if never scored)
    func substanceScore(for substanceId: String) -> Double {
        substanceScores.first { $0.substanceId == substanceId }?.score ?? 0
    }

    /// Score for a combination of substances
    func comboScore(for substanceIds: Set<String>) -> Double {
        guard substanceIds.count >= 2 else { return 0 }
        let key = ComboScore.comboKey(from: substanceIds)
        return comboScores.first { $0.id == key }?.score ?? 0
    }

    var proLevelLabel: String {
        switch proLevel {
        case 1: return "Beginner"
        case 2: return "Casual"
        case 3: return "Intermediate"
        case 4: return "Experienced"
        case 5: return "Very Experienced"
        default: return "Unknown"
        }
    }

    func toleranceFactor(for substanceId: String) -> Double {
        tolerances.first { $0.substanceId == substanceId }?.factor ?? 1.0
    }
    
    var metabolismFactor: Double {
        var factor = sex.metabolismFactor
        if isNeurodivergent { factor *= 0.95 }
        if age < 21 { factor *= 0.85 }
        else if age > 50 { factor *= 0.85 }
        return factor
    }
    
    var weight: Double { weightKg }
}
