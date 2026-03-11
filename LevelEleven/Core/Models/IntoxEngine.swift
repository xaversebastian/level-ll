//
//  IntoxEngine.swift
//  LevelEleven
//
//  Pharmacokinetic calculations and dose recommendations.
//

import Foundation

struct DoseRecommendation {
    let recommendedDose: Double
    let adjustmentFactors: [String]
    let warnings: [String]
}

enum IntoxEngine {
    
    static func recommendDose(
        substance: Substance,
        route: DoseRoute,
        profile: Profile
    ) -> DoseRecommendation {
        var dose = substance.commonDose
        var factors: [String] = []
        var warnings: [String] = []
        
        // Weight adjustment (reference: 70kg)
        // Heavier people need proportionally more, lighter people need less
        let weightFactor = profile.weight / 70.0
        if abs(weightFactor - 1.0) > 0.1 {
            dose *= weightFactor
            if weightFactor > 1.0 {
                factors.append("Higher weight: +\(Int((weightFactor - 1) * 100))%")
            } else {
                factors.append("Lower weight: -\(Int((1 - weightFactor) * 100))%")
            }
        }
        
        // Tolerance adjustment
        let toleranceLevel = profile.tolerance(for: substance.category)
        if toleranceLevel > 0 {
            let toleranceMultiplier = 1.0 + Double(toleranceLevel) * 0.1
            dose *= toleranceMultiplier
            factors.append("Tolerance +\(toleranceLevel): +\(Int((toleranceMultiplier - 1) * 100))%")
        }
        
        // Route bioavailability
        let routeBioavail = route.bioavailability
        let baseBioavail = substance.primaryRoute.bioavailability
        if routeBioavail != baseBioavail {
            let routeFactor = baseBioavail / routeBioavail
            dose *= routeFactor
            factors.append("\(route.displayName): x\(String(format: "%.1f", routeFactor))")
        }
        
        // ADHD adjustment for stimulants
        if profile.hasADHD && substance.category == .stimulant {
            dose *= 1.3
            factors.append("ADHD: +30%")
        }
        
        // Sex-based metabolism
        if profile.sex == .female {
            dose *= 0.9
            factors.append("Female: -10%")
        }
        
        // Clamp to reasonable range
        dose = max(substance.lightDose * 0.5, min(dose, substance.strongDose * 1.5))
        
        // Warnings
        if dose >= substance.strongDose {
            warnings.append("Strong dose - be careful")
        }
        
        if toleranceLevel == 0 {
            warnings.append("No tolerance - start lower")
        }
        
        return DoseRecommendation(
            recommendedDose: dose,
            adjustmentFactors: factors,
            warnings: warnings
        )
    }
}
