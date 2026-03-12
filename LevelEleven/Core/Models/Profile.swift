//
//  Profile.swift
//  LevelEleven
//
//  Version: 1.0  |  2026-03-11
//
//  Nutzerprofil für pharmakokinetische Berechnungen und Dosisempfehlungen.
//  Enthält Name, Emoji-Avatar, Alter, Gewicht (kg), biologisches Geschlecht (BiologicalSex)
//  sowie substanzspezifische Toleranzen (Tolerance-Struct, Level 0–11).
//  metabolismFactor kombiniert Geschlecht, ADHS-Status und Alter zu einem Multiplikator.
//  toleranceFactor(for:) liefert den Verstärkungsfaktor einer Substanz für dieses Profil.
//
//  HINWEIS: Toleranz-Level 0–11 entsprechen der lEVEl-Skala; factor wird in AppState.calculateIntensity() genutzt.
//  Gewicht wird auf 30–300 kg und Alter auf 13–99 Jahre geclampt.
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
    /// Letzter Konsumierdatum – nil = unbekannt (kein Decay)
    var lastUsedDate: Date?

    init(substanceId: String, level: Int, lastUsedDate: Date? = nil) {
        self.substanceId = substanceId
        self.level = max(0, min(11, level))
        self.lastUsedDate = lastUsedDate
    }

    /// Effektiver Toleranzlevel nach Abstinenz-Decay.
    /// Decay-Kurve (Abstinenz in Tagen → verlorene Level):
    ///   0–6 Tage:  kein Abbau
    ///   7–13 Tage: -1 Level
    ///   14–27 Tage: -2 Level
    ///   28–55 Tage: -50 % (halber Peak)
    ///   56+ Tage:   vollständig zurück auf 0
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
        case 0: return 0.5
        case 1...3: return 0.6 + Double(lvl) * 0.1
        case 4...6: return 0.9 + Double(lvl - 4) * 0.15
        case 7...9: return 1.3 + Double(lvl - 7) * 0.25
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
    /// Nimmt der Nutzer SSRIs (selektive Serotonin-Wiederaufnahmehemmer)?
    /// Erhöht das Risiko eines Serotonin-Syndroms bei Kombination mit MDMA/LSD.
    var takeSSRI: Bool
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
        takeSSRI: Bool = false,
        tolerances: [Tolerance] = [],
        favorites: [String] = [],
        personalLimit: Int = 7
    ) {
        self.id = id
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        self.name = trimmed.isEmpty ? "User" : trimmed
        self.isActive = isActive
        self.avatarEmoji = avatarEmoji.isEmpty ? "😎" : avatarEmoji
        self.age = max(13, min(99, age))
        self.weightKg = max(30, min(300, weightKg))
        self.sex = sex
        self.hasADHD = hasADHD
        self.takeSSRI = takeSSRI
        self.tolerances = tolerances
        self.favorites = favorites
        self.personalLimit = max(1, min(11, personalLimit))
    }
    
    func tolerance(for substanceId: String) -> Int {
        tolerances.first { $0.substanceId == substanceId }?.effectiveLevel ?? 5
    }

    func tolerance(for category: SubstanceCategory) -> Int {
        // Find highest effective tolerance for any substance in this category
        let categorySubstances = Substances.all.filter { $0.category == category }
        let levels = categorySubstances.compactMap { substance -> Int? in
            tolerances.first { $0.substanceId == substance.id }?.effectiveLevel
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
