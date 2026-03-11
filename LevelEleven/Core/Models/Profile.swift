//
//  Profile.swift
//  LevelEleven
//
//  User profile with tolerances.
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
    
    init(substanceId: String, level: Int) {
        self.substanceId = substanceId
        self.level = max(0, min(11, level))
    }
    
    var factor: Double {
        switch level {
        case 0: return 0.5
        case 1...3: return 0.6 + Double(level) * 0.1
        case 4...6: return 0.9 + Double(level - 4) * 0.15
        case 7...9: return 1.3 + Double(level - 7) * 0.25
        case 10: return 2.0
        case 11: return 2.5
        default: return 1.0
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
    var hasADHD: Bool
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
        hasADHD: Bool = false,
        tolerances: [Tolerance] = [],
        favorites: [String] = [],
        personalLimit: Int = 7
    ) {
        self.id = id
        self.name = name
        self.isActive = isActive
        self.avatarEmoji = avatarEmoji
        self.age = age
        self.weightKg = weightKg
        self.sex = sex
        self.hasADHD = hasADHD
        self.tolerances = tolerances
        self.favorites = favorites
        self.personalLimit = max(1, min(11, personalLimit))
    }
    
    func tolerance(for substanceId: String) -> Int {
        tolerances.first { $0.substanceId == substanceId }?.level ?? 5
    }
    
    func tolerance(for category: SubstanceCategory) -> Int {
        // Find highest tolerance for any substance in this category
        let categorySubstances = Substances.all.filter { $0.category == category }
        let levels = categorySubstances.compactMap { substance -> Int? in
            tolerances.first { $0.substanceId == substance.id }?.level
        }
        return levels.max() ?? 5
    }
    
    func toleranceFactor(for substanceId: String) -> Double {
        tolerances.first { $0.substanceId == substanceId }?.factor ?? 1.0
    }
    
    var metabolismFactor: Double {
        var factor = sex.metabolismFactor
        if hasADHD { factor *= 0.95 }
        if age < 21 { factor *= 0.85 }
        else if age > 50 { factor *= 0.85 }
        return factor
    }
    
    var weight: Double { weightKg }
}
