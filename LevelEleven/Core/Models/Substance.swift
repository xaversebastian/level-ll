// Substance.swift — LevelEleven
// v2.0 | 2026-03-12 17:18
// - Substance data model with pharmacokinetic params, categories, routes, static registry
// - Stripped legacy comments, added structured header
//

import Foundation

enum SubstanceCategory: String, Codable, CaseIterable {
    case alcohol, stimulant, depressant, psychedelic, dissociative, entactogen, opioid, cannabinoid
    
    var icon: String {
        switch self {
        case .alcohol: return "drop.fill"
        case .stimulant: return "bolt.fill"
        case .depressant: return "moon.fill"
        case .psychedelic: return "sparkles"
        case .dissociative: return "cube.transparent"
        case .entactogen: return "heart.fill"
        case .opioid: return "pills.fill"
        case .cannabinoid: return "leaf.fill"
        }
    }
    
    var color: String {
        switch self {
        case .alcohol: return "FFB347"
        case .stimulant: return "FF6B6B"
        case .depressant: return "4ECDC4"
        case .psychedelic: return "9B59B6"
        case .dissociative: return "3498DB"
        case .entactogen: return "E91E63"
        case .opioid: return "607D8B"
        case .cannabinoid: return "7CB342"
        }
    }
}

enum DoseRoute: String, Codable, CaseIterable {
    case oral, nasal, smoked, iv, sublingual, rectal
    
    var displayName: String {
        switch self {
        case .oral: return "Oral"
        case .nasal: return "Nasal"
        case .smoked: return "Smoked"
        case .iv: return "IV"
        case .sublingual: return "Sublingual"
        case .rectal: return "Rectal"
        }
    }
    
    var bioavailability: Double {
        switch self {
        case .iv: return 1.0
        case .rectal: return 0.9
        case .smoked: return 0.85
        case .sublingual: return 0.8
        case .nasal: return 0.75
        case .oral: return 0.5
        }
    }
    
    var onsetMultiplier: Double {
        switch self {
        case .iv: return 0.1
        case .smoked: return 0.2
        case .nasal: return 0.5
        case .sublingual: return 0.6
        case .rectal: return 0.7
        case .oral: return 1.0
        }
    }
}

enum DoseUnit: String, Codable {
    case mg, ml, drinks, ug, puffs, g
    
    var symbol: String { rawValue }
}

struct Substance: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let shortName: String
    let category: SubstanceCategory
    let routes: [DoseRoute]
    let onsetMinutes: Double
    let peakMinutes: Double
    let durationMinutes: Double
    let halfLifeMinutes: Double
    let unit: DoseUnit
    let lightDose: Double
    let commonDose: Double
    let strongDose: Double
    let description: String
    let risks: [String]
    let saferUse: [String]

    // Route-spezifische Pharmakokinetik – nil bedeutet: globalen Wert + Route-Multiplikator nutzen
    var onsetByRoute:    [DoseRoute: Double]? = nil
    var peakByRoute:     [DoseRoute: Double]? = nil
    var durationByRoute: [DoseRoute: Double]? = nil

    var primaryRoute: DoseRoute { routes.first ?? .oral }

    // MARK: - Route-aware accessors

    func onset(for route: DoseRoute) -> Double {
        onsetByRoute?[route] ?? onsetMinutes * route.onsetMultiplier
    }

    func peak(for route: DoseRoute) -> Double {
        peakByRoute?[route] ?? peakMinutes
    }

    func duration(for route: DoseRoute) -> Double {
        durationByRoute?[route] ?? durationMinutes
    }

    // Legacy – keeps existing call sites compiling
    func adjustedOnset(for route: DoseRoute) -> Double { onset(for: route) }
}

struct Substances {
    static let all: [Substance] = [
        // ALCOHOL
        Substance(
            id: "alcohol",
            name: "Alcohol",
            shortName: "Alcohol",
            category: .alcohol,
            routes: [.oral],
            onsetMinutes: 15,
            peakMinutes: 45,
            durationMinutes: 180,
            halfLifeMinutes: 90,
            unit: .drinks,
            lightDose: 1,
            commonDose: 3,
            strongDose: 6,
            description: "Central nervous system depressant. Disinhibiting, relaxing, and euphoric at low doses.",
            risks: ["Respiratory depression at high doses", "Liver damage with chronic use", "High addiction potential", "Dangerous with other depressants"],
            saferUse: ["Drink slowly", "Drink water between drinks", "Do not mix with GHB/benzos", "Eat beforehand"]
        ),
        
        // COCAINE
        Substance(
            id: "cocaine",
            name: "Cocaine",
            shortName: "Coke",
            category: .stimulant,
            routes: [.nasal, .smoked, .iv],
            onsetMinutes: 5,
            peakMinutes: 20,
            durationMinutes: 60,
            halfLifeMinutes: 90,
            unit: .mg,
            lightDose: 20,
            commonDose: 40,
            strongDose: 80,
            description: "Powerful stimulant derived from coca leaves. Blocks dopamine reuptake, producing intense euphoria.",
            risks: ["Cardiovascular strain", "Very high addiction potential", "Nasal membrane damage", "Overheating", "Psychosis with prolonged use"],
            saferUse: ["Small lines, long breaks", "Do not mix with alcohol (cocaethylene)", "Monitor heart rate", "Do not share straws (hepatitis risk)"],
            // IV/smoked: near-instant onset, short intense peak, shorter total duration
            onsetByRoute:    [.nasal: 5, .smoked: 1, .iv: 1],
            peakByRoute:     [.nasal: 20, .smoked: 10, .iv: 10],
            durationByRoute: [.nasal: 60, .smoked: 30, .iv: 30]
        ),
        
        // AMPHETAMINE
        Substance(
            id: "amphetamine",
            name: "Amphetamine",
            shortName: "Speed",
            category: .stimulant,
            routes: [.nasal, .oral],
            onsetMinutes: 20,
            peakMinutes: 90,
            durationMinutes: 420,
            halfLifeMinutes: 600,
            unit: .mg,
            lightDose: 20,
            commonDose: 40,
            strongDose: 60,
            description: "Synthetic stimulant. Increases dopamine and norepinephrine. Long duration, strongly stimulating.",
            risks: ["Sleep deprivation", "Dehydration", "Overheating", "Psychosis with prolonged use", "Cardiovascular strain", "Appetite suppression"],
            saferUse: ["Oral is gentler than nasal", "Remember to eat and drink", "Plan sleep breaks", "Use saline nasal spray if snorting"]
        ),
        
        // MDMA
        Substance(
            id: "mdma",
            name: "MDMA",
            shortName: "MDMA",
            category: .entactogen,
            routes: [.oral, .nasal],
            onsetMinutes: 45,
            peakMinutes: 90,
            durationMinutes: 300,
            halfLifeMinutes: 480,
            unit: .mg,
            lightDose: 50,
            commonDose: 100,
            strongDose: 150,
            description: "Entactogen that releases serotonin. Produces empathy, euphoria, and connectedness. Popular party drug.",
            risks: ["Serotonin syndrome with other serotonergics", "Hyperthermia", "Hyponatremia (drinking too much water)", "Neurotoxicity", "Comedown/hangover"],
            saferUse: ["Max 1.5mg/kg body weight", "At least 3 months between uses", "Do not redose", "Electrolytes, not just water", "Stay cool"]
        ),
        
        // KETAMINE
        Substance(
            id: "ketamine",
            name: "Ketamine",
            shortName: "Ket",
            category: .dissociative,
            routes: [.nasal, .iv, .oral],
            onsetMinutes: 5,
            peakMinutes: 20,
            durationMinutes: 60,
            halfLifeMinutes: 150,
            unit: .mg,
            lightDose: 10,
            commonDose: 30,
            strongDose: 50,
            description: "Dissociative anesthetic. Produces dissociation and altered perception. 'K-hole' at high doses.",
            risks: ["Bladder damage with frequent use", "Immobility", "Aspiration risk if vomiting", "Dangerous with depressants"],
            saferUse: ["Start with low doses", "Safe environment", "Do not mix with alcohol/GHB", "Take long breaks between sessions"],
            // IV: near-instant with very short duration; oral: slower, longer
            onsetByRoute:    [.nasal: 5, .iv: 1, .oral: 20],
            peakByRoute:     [.nasal: 20, .iv: 10, .oral: 30],
            durationByRoute: [.nasal: 60, .iv: 30, .oral: 90]
        ),
        
        // GHB
        Substance(
            id: "ghb",
            name: "GHB",
            shortName: "G",
            category: .depressant,
            routes: [.oral],
            onsetMinutes: 15,
            peakMinutes: 45,
            durationMinutes: 120,
            halfLifeMinutes: 30,
            unit: .ml,
            lightDose: 0.1,
            commonDose: 0.2,
            strongDose: 0.3,
            description: "GABAergic depressant. Relaxing, disinhibiting, and euphoric. Very narrow therapeutic window.",
            risks: ["Respiratory depression", "NEVER mix with alcohol", "Loss of consciousness", "G-lock", "Physical dependence", "Withdrawal can be fatal"],
            saferUse: ["Dose precisely (use a pipette)", "At least 2 hours between doses", "NO alcohol", "Sober supervisor present", "Set a timer"]
        ),
        
        // CANNABIS
        Substance(
            id: "cannabis",
            name: "Cannabis",
            shortName: "THC",
            category: .cannabinoid,
            routes: [.smoked, .oral],
            onsetMinutes: 5,
            peakMinutes: 30,
            durationMinutes: 180,
            halfLifeMinutes: 120,
            unit: .puffs,
            lightDose: 3,
            commonDose: 6,
            strongDose: 9,
            description: "Cannabinoid agonist. Relaxing, euphoric, enhances sensory perception. Oral route is much stronger!",
            risks: ["Anxiety/paranoia with overdose", "Delayed onset when oral (do not redose!)", "Impairs reaction time", "Developmental risks for adolescents"],
            saferUse: ["Start low", "Wait 2 hours with edibles", "Mind set & setting", "Do not drive"],
            // Oral (edible) differs drastically from smoked: 12× longer onset, 2× longer duration
            onsetByRoute:    [.smoked: 5, .oral: 60],
            peakByRoute:     [.smoked: 20, .oral: 150],
            durationByRoute: [.smoked: 120, .oral: 360]
        ),
        
        // 3-MMC
        Substance(
            id: "3mmc",
            name: "3-MMC",
            shortName: "3-MMC",
            category: .stimulant,
            routes: [.oral, .nasal],
            onsetMinutes: 20,
            peakMinutes: 60,
            durationMinutes: 180,
            halfLifeMinutes: 120,
            unit: .mg,
            lightDose: 30,
            commonDose: 60,
            strongDose: 90,
            description: "Synthetic cathinone. Stimulating with mild entactogenic effects. High addiction potential, strong urge to redose.",
            risks: ["Extreme urge to redose", "Cardiovascular strain", "Overheating", "Insomnia", "Severe comedown"],
            saferUse: ["Pre-weigh your dose", "Lock away remaining supply", "Set a time limit", "Stay hydrated"]
        ),
        
        // 4-MMC (Mephedrone)
        Substance(
            id: "4mmc",
            name: "4-MMC",
            shortName: "Mephedrone",
            category: .stimulant,
            routes: [.oral, .nasal],
            onsetMinutes: 15,
            peakMinutes: 45,
            durationMinutes: 120,
            halfLifeMinutes: 90,
            unit: .mg,
            lightDose: 30,
            commonDose: 50,
            strongDose: 70,
            description: "Synthetic cathinone, also known as 'meow'. Strongly stimulating and euphoric. Short duration.",
            risks: ["Very high addiction potential", "Vasoconstriction", "Overheating", "Bruxism (jaw clenching)", "Nasal damage"],
            saferUse: ["Strict dosing", "Do not redose", "Take breaks", "Monitor heart"]
        ),
        
        // LSD
        Substance(
            id: "lsd",
            name: "LSD",
            shortName: "LSD",
            category: .psychedelic,
            routes: [.oral, .sublingual],
            onsetMinutes: 45,
            peakMinutes: 180,
            durationMinutes: 720,
            halfLifeMinutes: 210, // ~3.5h biological half-life (literature: 2.5–5h)
            unit: .ug,
            lightDose: 25,
            commonDose: 75,
            strongDose: 125,
            description: "Classic psychedelic. Produces intense visual and cognitive changes. Very long duration.",
            risks: ["Bad trip possible", "HPPD (persistent perceptual changes)", "Can trigger latent psychoses", "Uncertain dosage on blotters"],
            saferUse: ["Set & setting", "Experienced trip sitter", "Safe location", "Avoid with psychiatric conditions", "Benzos as emergency option"]
        ),
        
        // PSILOCYBIN
        Substance(
            id: "psilocybin",
            name: "Psilocybin",
            shortName: "Shrooms",
            category: .psychedelic,
            routes: [.oral],
            onsetMinutes: 30,
            peakMinutes: 90,
            durationMinutes: 360,
            halfLifeMinutes: 180,
            unit: .g,
            lightDose: 1,
            commonDose: 2.5,
            strongDose: 5,
            description: "Natural psychedelic from mushrooms. Shorter duration than LSD. Often perceived as gentler.",
            risks: ["Nausea possible", "Bad trip", "Uncertain potency (mushroom species)", "Risk of misidentification with poisonous mushrooms"],
            saferUse: ["Ensure proper mushroom identification", "Set & setting", "Trip sitter", "Lemon tek for faster onset", "Start sober"]
        ),
        
        // ALPRAZOLAM
        Substance(
            id: "alprazolam",
            name: "Alprazolam",
            shortName: "Xanax",
            category: .depressant,
            routes: [.oral],
            onsetMinutes: 20,
            peakMinutes: 90,
            durationMinutes: 360,
            halfLifeMinutes: 720,
            unit: .mg,
            lightDose: 0.25,
            commonDose: 0.5,
            strongDose: 1.0,
            description: "Fast-acting benzodiazepine. Anxiolytic and sedating. High addiction potential.",
            risks: ["Physical dependence", "Withdrawal can be fatal", "Blackouts", "Respiratory depression with opiates", "Disinhibition"],
            saferUse: ["Lowest effective dose", "Do not use regularly", "NEVER with opiates/GHB/alcohol", "Taper slowly when stopping"]
        ),
        
        // MORPHINE
        Substance(
            id: "morphine",
            name: "Morphine",
            shortName: "Morphine",
            category: .opioid,
            routes: [.oral, .iv],
            onsetMinutes: 30,
            peakMinutes: 60,
            durationMinutes: 300,
            halfLifeMinutes: 180,
            unit: .mg,
            lightDose: 10,
            commonDose: 20,
            strongDose: 40,
            description: "Classic opioid analgesic. Strong pain relief and euphoria. High addiction potential.",
            risks: ["Respiratory depression (can be fatal!)", "Rapid tolerance development", "Severe physical dependence", "Overdose risk"],
            saferUse: ["Have naloxone available", "Never use alone", "Start with low doses", "DO NOT mix with other depressants", "Mind tolerance after breaks"],
            // IV morphine: rapid onset, shorter peak and total duration vs. oral
            onsetByRoute:    [.oral: 30, .iv: 5],
            peakByRoute:     [.oral: 60, .iv: 20],
            durationByRoute: [.oral: 300, .iv: 180]
        )
    ]
    
    static let byId: [String: Substance] = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
}
