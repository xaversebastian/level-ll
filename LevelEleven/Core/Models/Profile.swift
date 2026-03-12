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
    var level: Int
    var lastUsedDate: Date?

    init(substanceId: String, level: Int, lastUsedDate: Date? = nil) {
        self.substanceId = substanceId
        self.level = max(0, min(11, level))
        self.lastUsedDate = lastUsedDate
    }

    // Decay: 0-6d=0, 7-13d=-1, 14-27d=-2, 28-55d=-50%, 56d+=reset
    var effectiveLevel: Int {
        guard let lastUsed = lastUsedDate else { return level }
        let days = Calendar.current.dateComponents([.day], from: lastUsed, to: Date()).day ?? 0
        let decay: Int
        switch days {
        case 0...6:    decay = 0
        case 7...13:   decay = 1
        case 14...27:  decay = 2
        case 28...55:  decay = level / 2
        default:       decay = level
        }
        return max(0, level - decay)
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
}

struct Profile: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var isActive: Bool
    var avatarEmoji: String
    var age: Int
    var weightKg: Double
    var sex: BiologicalSex
    var isNeurodivergent: Bool
    var takeSSRI: Bool
    /// Internal experience rating (1=beginner … 5=very experienced). Set during onboarding.
    var proLevel: Int
    var tolerances: [Tolerance]
    var favorites: [String]
    var personalLimit: Int

    init(
        id: String = UUID().uuidString,
        name: String,
        isActive: Bool = false,
        avatarEmoji: String = "😎",
        age: Int = 30,
        weightKg: Double = 70,
        sex: BiologicalSex = .male,
        isNeurodivergent: Bool = false,
        takeSSRI: Bool = false,
        proLevel: Int = 3,
        tolerances: [Tolerance] = [],
        favorites: [String] = [],
        personalLimit: Int? = nil
    ) {
        self.id = id
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        self.name = trimmed.isEmpty ? "User" : trimmed
        self.isActive = isActive
        self.avatarEmoji = avatarEmoji.isEmpty ? "😎" : avatarEmoji
        self.age = max(13, min(99, age))
        self.weightKg = max(30, min(300, weightKg))
        self.sex = sex
        self.isNeurodivergent = isNeurodivergent
        self.takeSSRI = takeSSRI
        self.proLevel = max(1, min(5, proLevel))
        self.tolerances = tolerances
        self.favorites = favorites
        // Default personal limit scales with experience
        let defaultLimit = Self.defaultPersonalLimit(for: proLevel)
        self.personalLimit = max(1, min(11, personalLimit ?? defaultLimit))
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
