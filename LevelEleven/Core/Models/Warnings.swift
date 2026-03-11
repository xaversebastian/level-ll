//
//  Warnings.swift
//  LevelEleven
//
//  Interaction warnings and risk detection.
//

import SwiftUI

enum WarningSeverity: Int, Comparable {
    case info = 0
    case caution = 1
    case warning = 2
    case danger = 3
    
    static func < (lhs: WarningSeverity, rhs: WarningSeverity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    var color: Color {
        switch self {
        case .info: return .blue
        case .caution: return .yellow
        case .warning: return .orange
        case .danger: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .info: return "info.circle.fill"
        case .caution: return "exclamationmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .danger: return "xmark.octagon.fill"
        }
    }
}

struct Warning: Identifiable {
    let id = UUID().uuidString
    let severity: WarningSeverity
    let title: String
    let message: String
    let advice: String
}

struct WarningSystem {
    
    static func checkInteractions(substances: [String]) -> [Warning] {
        var warnings: [Warning] = []
        let set = Set(substances)
        
        // Respiratory Depression: Opioids + Depressants
        let opioids = Set(["morphine"])
        let depressants = Set(["alcohol", "ghb", "alprazolam"])
        if !opioids.isDisjoint(with: set) && !depressants.isDisjoint(with: set) {
            warnings.append(Warning(
                severity: .danger,
                title: "Respiratory Depression Risk",
                message: "Mixing opioids with depressants greatly increases overdose risk.",
                advice: "Avoid this combination. Have naloxone ready. Don't use alone."
            ))
        }
        
        // GHB + Alcohol
        if set.contains("ghb") && set.contains("alcohol") {
            warnings.append(Warning(
                severity: .danger,
                title: "Dangerous Combination",
                message: "GHB and alcohol is one of the most dangerous drug combinations.",
                advice: "Never mix G with alcohol. This can cause coma or death."
            ))
        }
        
        // Serotonin Syndrome: MDMA + other serotonergics
        let serotonergics = Set(["mdma", "lsd", "psilocybin"])
        let seroCount = set.intersection(serotonergics).count
        if seroCount >= 2 {
            warnings.append(Warning(
                severity: .warning,
                title: "Serotonin Syndrome Risk",
                message: "Multiple serotonergic substances increase risk of serotonin syndrome.",
                advice: "Symptoms: high temperature, agitation, tremor. Seek medical help if severe."
            ))
        }
        
        // Stimulant Stacking
        let stimulants = Set(["cocaine", "amphetamine", "3mmc", "4mmc", "mdma"])
        let stimCount = set.intersection(stimulants).count
        if stimCount >= 2 {
            warnings.append(Warning(
                severity: .warning,
                title: "Cardiovascular Strain",
                message: "Multiple stimulants increase heart rate and blood pressure significantly.",
                advice: "Stay hydrated (not too much), take breaks, cool down regularly."
            ))
        }
        
        // Stimulants + Alcohol dehydration
        if !stimulants.isDisjoint(with: set) && set.contains("alcohol") {
            warnings.append(Warning(
                severity: .caution,
                title: "Dehydration Risk",
                message: "Stimulants mask alcohol effects, leading to overconsumption.",
                advice: "Drink water regularly. Don't rely on feeling drunk to stop drinking."
            ))
        }
        
        // Ketamine + Depressants
        if set.contains("ketamine") && !depressants.isDisjoint(with: set) {
            warnings.append(Warning(
                severity: .warning,
                title: "Aspiration Risk",
                message: "Ketamine with depressants increases vomiting and passing out risk.",
                advice: "If unconscious, place in recovery position. Monitor breathing."
            ))
        }
        
        // MDMA Timing
        if set.contains("mdma") {
            warnings.append(Warning(
                severity: .info,
                title: "MDMA Guidelines",
                message: "Wait at least 6-8 weeks between MDMA uses for safety.",
                advice: "Stay cool, take breaks from dancing, sip water (not too much)."
            ))
        }
        
        return warnings.sorted { $0.severity > $1.severity }
    }
    
    static func checkLevel(level: Double, limit: Int) -> [Warning] {
        var warnings: [Warning] = []
        
        if level >= Double(limit) {
            warnings.append(Warning(
                severity: .warning,
                title: "Personal Limit Reached",
                message: "You've reached your personal comfort limit of \(limit).",
                advice: "Consider stopping. Take a break. Stay with friends."
            ))
        }
        
        if level >= 8 {
            warnings.append(Warning(
                severity: .warning,
                title: "High Intoxication",
                message: "Your current level is quite high.",
                advice: "Find a safe place. Stay with trusted friends. Hydrate."
            ))
        }
        
        if level >= 10 {
            warnings.append(Warning(
                severity: .danger,
                title: "Extreme Level",
                message: "You're at a very high intoxication level.",
                advice: "Do not take more. Stay safe. Consider medical help if unwell."
            ))
        }
        
        return warnings
    }
}
