//
//  IntoxEngine.swift
//  LevelEleven
//
//  Version: 2.0  |  2026-03-12
//
//  Pharmakokinetiksystem für individuelle Dosisempfehlungen.
//  Verwendet substanzspezifische Toleranz, non-lineare Toleranz-Multiplikatoren,
//  aktuellen Intoxikationslevel, Zeit seit letzter Dosis und SSRI-Interaktion
//  für realistischere Empfehlungen. Gibt personalisierte Light/Common/Strong-Werte
//  zurück, nicht nur eine einzelne Dosis.
//
//  HINWEIS: Für klinische oder forensische Zwecke NICHT geeignet – vereinfachtes Modell.
//  Die eigentliche Level-Berechnung (currentLevel, calculateIntensity) liegt in AppState.

import Foundation

struct DoseRecommendation {
    let suggestedDose: Double      // primäre konservative Empfehlung
    let adjustedLight: Double      // personalisierte Light-Dosis
    let adjustedCommon: Double     // personalisierte Common-Dosis
    let adjustedStrong: Double     // personalisierte Strong-Dosis
    let adjustmentFactors: [String]
    let warnings: [String]
}

enum IntoxEngine {

    // MARK: - Tolerance Dose Multiplier (non-linear, realistic)

    /// Wie viel mehr Substanz bei diesem Toleranzlevel nötig ist, um den gleichen Effekt zu erzielen.
    /// Level 0 = naiv → konservativ 0.50×. Level 11 = sehr hohe Toleranz → max 2.2×.
    /// Flachere, sicherere Kurve: oberes Ende drastisch reduziert.
    static func toleranceDoseMultiplier(for level: Int) -> Double {
        switch level {
        case 0:  return 0.50   // keine Toleranz: stark konservativ
        case 1:  return 0.65
        case 2:  return 0.80
        case 3:  return 0.95
        case 4:  return 1.10
        case 5:  return 1.25
        case 6:  return 1.40
        case 7:  return 1.55
        case 8:  return 1.70
        case 9:  return 1.85
        case 10: return 2.00
        case 11: return 2.20   // maximale Toleranz: max 2.2×, nicht 5.5×
        default: return 1.00
        }
    }

    // MARK: - Serotonergic substances (SSRI interaction risk)

    private static let serotonergicIds: Set<String> = ["mdma", "mda", "lsd", "psilocybin", "dmt", "2cb"]

    // MARK: - Main Recommendation

    static func recommendDose(
        substance: Substance,
        route: DoseRoute,
        profile: Profile,
        currentLevel: Double = 0,
        lastDoseDate: Date? = nil
    ) -> DoseRecommendation {

        var factors: [String] = []
        var warnings: [String] = []

        // --- Base: substance common dose ---
        let base = substance.commonDose

        // --- 1. Tolerance adjustment (substance-specific, non-linear) ---
        let tolLevel: Int = {
            let specific = profile.tolerance(for: substance.id)
            if specific > 0 {
                return specific
            }
            // Category fallback – cross-tolerance is partial (×0.7)
            let catLevel = profile.tolerance(for: substance.category)
            return catLevel > 0 ? max(0, Int(Double(catLevel) * 0.7)) : 0
        }()

        let toleranceMult = toleranceDoseMultiplier(for: tolLevel)

        if tolLevel == 0 {
            factors.append("No tolerance: ×0.6 (start low)")
            warnings.append("No tolerance recorded – start well below the suggestion")
        } else if tolLevel <= 2 {
            factors.append("Low tolerance (\(tolLevel)): ×\(String(format: "%.2f", toleranceMult))")
        } else {
            factors.append("Tolerance lvl \(tolLevel): ×\(String(format: "%.1f", toleranceMult))")
        }

        // Build adjusted scale points
        var adjLight  = substance.lightDose  * toleranceMult
        var adjCommon = base                 * toleranceMult
        var adjStrong = substance.strongDose * toleranceMult

        // --- 2. Weight adjustment (reference: 70kg, capped to avoid extreme outliers) ---
        let weightFactor = max(0.6, min(1.5, profile.weightKg / 70.0))
        if abs(weightFactor - 1.0) > 0.08 {
            adjLight  *= weightFactor
            adjCommon *= weightFactor
            adjStrong *= weightFactor
            let pct = Int((weightFactor - 1.0) * 100)
            factors.append("Weight \(Int(profile.weightKg))kg: \(pct >= 0 ? "+" : "")\(pct)%")
        }

        // --- 3. Route bioavailability adjustment ---
        let routeBioavail = route.bioavailability
        let baseBioavail  = substance.primaryRoute.bioavailability
        if abs(routeBioavail - baseBioavail) > 0.05 {
            let routeFactor = baseBioavail / routeBioavail
            adjLight  *= routeFactor
            adjCommon *= routeFactor
            adjStrong *= routeFactor
            factors.append("\(route.displayName) route: ×\(String(format: "%.1f", routeFactor))")
        }

        // --- 4. ADHD (stimulants only) ---
        if profile.hasADHD && substance.category == .stimulant {
            adjLight  *= 1.2
            adjCommon *= 1.2
            adjStrong *= 1.2
            factors.append("ADHD (stimulant): +20%")
        }

        // --- 5. Biological sex ---
        if profile.sex == .female {
            adjLight  *= 0.90
            adjCommon *= 0.90
            adjStrong *= 0.90
            factors.append("Female metabolism: -10%")
        }

        // --- 6. SSRI interaction ---
        if profile.takeSSRI && serotonergicIds.contains(substance.id) {
            adjLight  *= 0.60
            adjCommon *= 0.60
            adjStrong *= 0.60
            warnings.append("⚠ SSRI + \(substance.shortName): serotonin syndrome risk. Strongly consider avoiding.")
            factors.append("SSRI interaction: -40%")
        }

        // --- 7. Current intoxication level penalty ---
        if currentLevel > 5 {
            adjLight  *= 0.40
            adjCommon *= 0.40
            adjStrong *= 0.40
            warnings.append("Active level \(String(format: "%.1f", currentLevel)) – strongly reduce or skip")
            factors.append("Active level >5: ×0.4")
        } else if currentLevel > 3 {
            adjLight  *= 0.65
            adjCommon *= 0.65
            adjStrong *= 0.65
            warnings.append("Active level \(String(format: "%.1f", currentLevel)) – reduce dose")
            factors.append("Active level >3: ×0.65")
        }

        // --- 8. Time since last dose ---
        if let last = lastDoseDate {
            let minAgo = Date().timeIntervalSince(last) / 60
            let onset = substance.onset(for: route)
            let peak  = substance.peakMinutes
            if minAgo < onset {
                adjLight  *= 0.60
                adjCommon *= 0.60
                adjStrong *= 0.60
                warnings.append("Within onset window (~\(Int(onset))min) – wait, effects still building")
                factors.append("Before onset: ×0.6")
            } else if minAgo < peak {
                adjLight  *= 0.75
                adjCommon *= 0.75
                adjStrong *= 0.75
                warnings.append("Before peak (~\(Int(peak))min) – dose will still increase")
                factors.append("Before peak: ×0.75")
            }
        }

        // --- 9. Hard clamps ---
        // Max = strongDose × toleranceMult, Strong darf nicht über den Clamp hinausgehen
        let maxAllowed = substance.strongDose * max(1.0, toleranceMult)
        adjLight  = max(0.1, min(adjLight,  maxAllowed))
        adjCommon = max(0.1, min(adjCommon, maxAllowed))
        adjStrong = max(0.1, min(adjStrong, maxAllowed))

        // --- 10. Suggested dose: conservative (slightly below adjusted common) ---
        let suggested = min(adjCommon * 0.80, adjCommon)

        // Final range warnings
        if adjCommon >= substance.strongDose * toleranceMult {
            warnings.append("Strong dose territory – go slow, wait for effects")
        }

        return DoseRecommendation(
            suggestedDose: suggested,
            adjustedLight: adjLight,
            adjustedCommon: adjCommon,
            adjustedStrong: adjStrong,
            adjustmentFactors: factors,
            warnings: warnings
        )
    }
}
