// AftercareEngine.swift — LevelEleven
// v1.0 | 2026-03-16
// - Aftercare data models, hint definitions, and aftercare state management
// - Timed recovery tips per substance, normalization tips, in-session care tips
//

import Foundation

// MARK: - Aftercare Data Models

enum AftercareCategory: String, Codable, CaseIterable {
    case nutrition
    case sleep
    case mental
    case physical
    case social
    case normalization

    var displayName: String {
        switch self {
        case .nutrition:     return "Nutrition"
        case .sleep:         return "Sleep"
        case .mental:        return "Mental Health"
        case .physical:      return "Physical"
        case .social:        return "Social"
        case .normalization: return "Normalization"
        }
    }

    var icon: String {
        switch self {
        case .nutrition:     return "fork.knife"
        case .sleep:         return "moon.zzz.fill"
        case .mental:        return "brain.head.profile.fill"
        case .physical:      return "figure.walk"
        case .social:        return "person.2.fill"
        case .normalization: return "arrow.down.heart.fill"
        }
    }
}

struct AftercareHint: Identifiable, Codable, Hashable {
    let id: String
    let substanceId: String?           // nil = general hint
    let title: String
    let message: String
    let category: AftercareCategory
    let triggerHoursAfterSession: Int?  // e.g. 8 = 8h after session end
    let triggerDaysAfterSession: Int?   // e.g. 3 = day 3 after session
    var isDismissed: Bool = false

    init(id: String = UUID().uuidString, substanceId: String? = nil, title: String, message: String,
         category: AftercareCategory, triggerHoursAfterSession: Int? = nil, triggerDaysAfterSession: Int? = nil) {
        self.id = id
        self.substanceId = substanceId
        self.title = title
        self.message = message
        self.category = category
        self.triggerHoursAfterSession = triggerHoursAfterSession
        self.triggerDaysAfterSession = triggerDaysAfterSession
    }
}

struct AftercareCheckIn: Codable, Identifiable, Hashable {
    let id: String
    let date: Date
    let mood: Int              // 1–5
    let energyLevel: Int       // 1–5
    let sleepQuality: Int      // 1–5
    let notes: String
    let daysAfterSession: Int

    init(id: String = UUID().uuidString, date: Date = Date(), mood: Int, energyLevel: Int,
         sleepQuality: Int, notes: String = "", daysAfterSession: Int) {
        self.id = id
        self.date = date
        self.mood = max(1, min(5, mood))
        self.energyLevel = max(1, min(5, energyLevel))
        self.sleepQuality = max(1, min(5, sleepQuality))
        self.notes = notes
        self.daysAfterSession = daysAfterSession
    }
}

struct AftercareState: Codable, Hashable {
    var activeHints: [AftercareHint] = []
    var lastSessionEndDate: Date?
    var lastSessionSubstances: [String] = []
    var checkInHistory: [AftercareCheckIn] = []

    var isActive: Bool {
        lastSessionEndDate != nil && daysSinceSession <= 7
    }

    var daysSinceSession: Int {
        guard let endDate = lastSessionEndDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: endDate, to: Date()).day ?? 0
    }

    var hoursSinceSession: Double {
        guard let endDate = lastSessionEndDate else { return 0 }
        return Date().timeIntervalSince(endDate) / 3600
    }
}

// MARK: - Session Check-in (during active session)

struct SessionCheckIn: Codable, Identifiable, Hashable {
    let id: String
    let date: Date
    let mood: String              // emoji
    let energyLevel: Int          // 1–5
    let notes: String?
    let activeSubstanceIds: [String]
    let currentLevels: [String: Double]

    init(id: String = UUID().uuidString, date: Date = Date(), mood: String, energyLevel: Int,
         notes: String? = nil, activeSubstanceIds: [String] = [], currentLevels: [String: Double] = [:]) {
        self.id = id
        self.date = date
        self.mood = mood
        self.energyLevel = max(1, min(5, energyLevel))
        self.notes = notes
        self.activeSubstanceIds = activeSubstanceIds
        self.currentLevels = currentLevels
    }

    var isNegative: Bool {
        ["😵‍💫", "🤢", "😰"].contains(mood)
    }

    var isPositive: Bool {
        ["😊"].contains(mood)
    }
}

// MARK: - Aftercare Engine

struct AftercareEngine {

    /// Determine if aftercare should activate for a session
    static func shouldActivateAftercare(sessionDurationMinutes: Double, doseCount: Int, substanceIds: Set<String>) -> Bool {
        if sessionDurationMinutes >= 120 { return true }
        if doseCount >= 3 { return true }
        let comedownSubstances: Set<String> = [
            "cocaine", "amphetamine", "methamphetamine", "mdma", "ecstasy",
            "3mmc", "4mmc", "alcohol", "lsd", "psilocybin"
        ]
        if !substanceIds.isDisjoint(with: comedownSubstances) { return true }
        return false
    }

    /// Generate aftercare hints for given substances at current time after session
    static func hintsForSubstances(_ substanceIds: [String], hoursSinceSession: Double, daysSinceSession: Int) -> [AftercareHint] {
        var result: [AftercareHint] = []

        for hint in allTimedHints {
            guard hint.substanceId == nil || substanceIds.contains(hint.substanceId!) else { continue }

            if let hours = hint.triggerHoursAfterSession {
                if hoursSinceSession >= Double(hours) && daysSinceSession < 2 {
                    result.append(hint)
                }
            }
            if let days = hint.triggerDaysAfterSession {
                if daysSinceSession >= days && daysSinceSession <= days + 1 {
                    result.append(hint)
                }
            }
        }

        return result
    }

    // MARK: - Timed Aftercare Hints

    static let allTimedHints: [AftercareHint] = mdmaHints + cocaineHints + amphetamineHints +
        methamphetamineHints + ketamineHints + alcoholHints + ghbHints + lsdHints +
        psilocybinHints + cannabisHints + cathinoneHints + alprazolamHints + morphineHints + generalHints

    private static let mdmaHints: [AftercareHint] = [
        AftercareHint(substanceId: "mdma", title: "MDMA Recovery: Nutrition",
            message: "Eat vitamin-C-rich food (oranges, kiwi). 5-HTP can help serotonin recovery, but wait at least 24h after your last dose before taking it.",
            category: .nutrition, triggerHoursAfterSession: 8),
        AftercareHint(substanceId: "mdma", title: "MDMA: Serotonin Recovery",
            message: "Serotonin recovery takes days. Mild depressive feelings are completely normal and expected. Be patient with yourself.",
            category: .mental, triggerDaysAfterSession: 1),
        AftercareHint(substanceId: "mdma", title: "MDMA: Midweek Blues",
            message: "Feeling down today is normal and expected — this is the classic 'midweek blues'. It will pass. Be kind to yourself, eat well, and get sunlight.",
            category: .mental, triggerDaysAfterSession: 3),
        AftercareHint(substanceId: "mdma", title: "MDMA: Week Recovery",
            message: "Your serotonin levels are recovering. Light exercise and sunlight help. You should start feeling more like yourself.",
            category: .physical, triggerDaysAfterSession: 7),
    ]

    private static let cocaineHints: [AftercareHint] = [
        AftercareHint(substanceId: "cocaine", title: "Cocaine: Comedown",
            message: "Irritability and fatigue are normal comedown effects. Eat something nutritious, drink water, and allow yourself to rest.",
            category: .physical, triggerHoursAfterSession: 6),
        AftercareHint(substanceId: "cocaine", title: "Cocaine: Sleep & Recovery",
            message: "Sleep as much as you can. Vitamin B and C support recovery. Your body needs time to replenish dopamine.",
            category: .sleep, triggerDaysAfterSession: 1),
        AftercareHint(substanceId: "cocaine", title: "Cocaine: Cravings",
            message: "Cravings may be strong today. Distraction helps — get fresh air, move your body, call a friend.",
            category: .mental, triggerDaysAfterSession: 2),
    ]

    private static let amphetamineHints: [AftercareHint] = [
        AftercareHint(substanceId: "amphetamine", title: "Speed: Nutrition",
            message: "Try to eat even if you're not hungry. Magnesium helps with muscle tension. Your body is running on empty.",
            category: .nutrition, triggerHoursAfterSession: 12),
        AftercareHint(substanceId: "amphetamine", title: "Speed: Sleep Recovery",
            message: "Your body needs sleep. Don't fight the fatigue — rest is recovery. Melatonin can help if you can't fall asleep.",
            category: .sleep, triggerDaysAfterSession: 1),
        AftercareHint(substanceId: "amphetamine", title: "Speed: Crash",
            message: "Extreme tiredness is normal after amphetamine use. Allow yourself to rest and eat well. This will pass.",
            category: .physical, triggerDaysAfterSession: 2),
    ]

    private static let methamphetamineHints: [AftercareHint] = [
        AftercareHint(substanceId: "methamphetamine", title: "Meth: Immediate Care",
            message: "Force yourself to eat and drink. Your body is depleted even if you don't feel it. Electrolytes help.",
            category: .nutrition, triggerHoursAfterSession: 12),
        AftercareHint(substanceId: "methamphetamine", title: "Meth: Sleep Priority",
            message: "Sleep is the most important thing right now. Melatonin or a benzodiazepine can help. Do not resist the urge to rest.",
            category: .sleep, triggerDaysAfterSession: 1),
        AftercareHint(substanceId: "methamphetamine", title: "Meth: Crash Warning",
            message: "The crash can be severe. Reach out to someone you trust. This emotional low is temporary and will pass.",
            category: .mental, triggerDaysAfterSession: 3),
        AftercareHint(substanceId: "methamphetamine", title: "Meth: Seeking Help",
            message: "If cravings are persistent, consider talking to a professional. There's no shame in asking for help. You deserve support.",
            category: .social, triggerDaysAfterSession: 7),
    ]

    private static let ketamineHints: [AftercareHint] = [
        AftercareHint(substanceId: "ketamine", title: "Ketamine: Hydration",
            message: "Drink plenty of water. Bladder health is important — regular ketamine use can cause serious bladder damage.",
            category: .physical, triggerHoursAfterSession: 4),
        AftercareHint(substanceId: "ketamine", title: "Ketamine: Grounding",
            message: "Some dissociative feelings may linger. Ground yourself: name 5 things you can see, 4 you can touch, 3 you can hear.",
            category: .mental, triggerDaysAfterSession: 1),
    ]

    private static let alcoholHints: [AftercareHint] = [
        AftercareHint(substanceId: "alcohol", title: "Hangover Care",
            message: "Electrolytes and light food. Avoid paracetamol (acetaminophen) — it's toxic to the liver combined with alcohol. Ibuprofen is safer.",
            category: .nutrition, triggerHoursAfterSession: 8),
        AftercareHint(substanceId: "alcohol", title: "Alcohol: Day After",
            message: "Hydrate throughout the day. B vitamins support recovery. Light movement helps but don't push yourself.",
            category: .physical, triggerDaysAfterSession: 1),
    ]

    private static let ghbHints: [AftercareHint] = [
        AftercareHint(substanceId: "ghb", title: "GHB/GBL: Rebound Warning",
            message: "Rebound effects possible: anxiety, insomnia, tremors. Do NOT redose. Seek medical help if symptoms are severe.",
            category: .physical, triggerHoursAfterSession: 6),
        AftercareHint(substanceId: "gbl", title: "GHB/GBL: Rebound Warning",
            message: "Rebound effects possible: anxiety, insomnia, tremors. Do NOT redose. Seek medical help if symptoms are severe.",
            category: .physical, triggerHoursAfterSession: 6),
        AftercareHint(substanceId: "ghb", title: "G: Sleep Recovery",
            message: "Sleep disturbances are common after G use. Melatonin may help. If you experience tremors or severe anxiety, seek medical help.",
            category: .sleep, triggerDaysAfterSession: 1),
        AftercareHint(substanceId: "gbl", title: "G: Sleep Recovery",
            message: "Sleep disturbances are common after G use. Melatonin may help. If you experience tremors or severe anxiety, seek medical help.",
            category: .sleep, triggerDaysAfterSession: 1),
    ]

    private static let lsdHints: [AftercareHint] = [
        AftercareHint(substanceId: "lsd", title: "LSD: Integration",
            message: "Write down what you experienced. Some afterglow or fatigue is normal. The experience may continue to process over the coming days.",
            category: .mental, triggerHoursAfterSession: 12),
        AftercareHint(substanceId: "lsd", title: "LSD: Day After",
            message: "If you feel 'different' — that's normal after a psychedelic experience. Talk to someone about it. Journaling helps integration.",
            category: .mental, triggerDaysAfterSession: 1),
    ]

    private static let psilocybinHints: [AftercareHint] = [
        AftercareHint(substanceId: "psilocybin", title: "Mushrooms: Rest & Process",
            message: "Eat well and rest. Emotional processing may continue — let it happen. Be gentle with yourself.",
            category: .mental, triggerHoursAfterSession: 8),
        AftercareHint(substanceId: "psilocybin", title: "Mushrooms: Integration",
            message: "Journaling helps integrate the experience. Be gentle with yourself. Talk to someone you trust if you need to process.",
            category: .mental, triggerDaysAfterSession: 1),
    ]

    private static let cannabisHints: [AftercareHint] = [
        AftercareHint(substanceId: "cannabis", title: "Cannabis: Clarity",
            message: "Some brain fog is normal after heavy cannabis use. Stay hydrated, eat well, get some fresh air.",
            category: .physical, triggerHoursAfterSession: 12),
    ]

    private static let cathinoneHints: [AftercareHint] = [
        AftercareHint(substanceId: "3mmc", title: "3-MMC: Comedown",
            message: "Comedown similar to MDMA/cocaine. Eat, hydrate, sleep. Resist the urge to redose — it will make everything worse.",
            category: .physical, triggerHoursAfterSession: 8),
        AftercareHint(substanceId: "4mmc", title: "4-MMC: Comedown",
            message: "Comedown similar to MDMA/cocaine. Eat, hydrate, sleep. Resist the urge to redose — it will make everything worse.",
            category: .physical, triggerHoursAfterSession: 8),
        AftercareHint(substanceId: "3mmc", title: "3-MMC: Mood Recovery",
            message: "Mood dip is expected. Exercise and social contact help. This is temporary.",
            category: .mental, triggerDaysAfterSession: 2),
        AftercareHint(substanceId: "4mmc", title: "4-MMC: Mood Recovery",
            message: "Mood dip is expected. Exercise and social contact help. This is temporary.",
            category: .mental, triggerDaysAfterSession: 2),
    ]

    private static let alprazolamHints: [AftercareHint] = [
        AftercareHint(substanceId: "alprazolam", title: "Xanax: Rebound Anxiety",
            message: "Rebound anxiety is common after benzodiazepine use. Do not take more to counter it. Breathe deeply, ground yourself.",
            category: .mental, triggerHoursAfterSession: 12),
    ]

    private static let morphineHints: [AftercareHint] = [
        AftercareHint(substanceId: "morphine", title: "Opioid: Post-Use Care",
            message: "Do not redose to avoid starting a withdrawal cycle. Hydrate and eat light food. Have naloxone available.",
            category: .physical, triggerHoursAfterSession: 8),
    ]

    private static let generalHints: [AftercareHint] = [
        AftercareHint(title: "Basic Recovery",
            message: "Drink water, eat something light and nutritious, get some fresh air if you can.",
            category: .nutrition, triggerHoursAfterSession: 4),
        AftercareHint(title: "Rest Day",
            message: "Today is a recovery day. Light movement and good food help your body and mind recover. Be gentle with yourself.",
            category: .physical, triggerDaysAfterSession: 1),
        AftercareHint(title: "Mood Check",
            message: "A post-consumption mood dip is normal and temporary. Talk to friends about how you feel — connection helps.",
            category: .mental, triggerDaysAfterSession: 3),
        AftercareHint(title: "One Week Reflection",
            message: "One week done! Take a moment to reflect: what went well, what would you change next time?",
            category: .social, triggerDaysAfterSession: 7),
    ]

    // MARK: - Normalization Tips (static reference — always available in CareView)

    struct NormalizationTip: Identifiable {
        let id: String          // substanceId
        let substanceName: String
        let tips: String
    }

    static let normalizationTips: [NormalizationTip] = [
        NormalizationTip(id: "lsd", substanceName: "LSD",
            tips: "A benzodiazepine (e.g., 0.5mg alprazolam) can significantly reduce a trip. Vitamin C (orange juice) may help mildly. Change environment — go to a quiet, dim room. Have a trusted person talk you through it calmly. Remember: it WILL end."),
        NormalizationTip(id: "psilocybin", substanceName: "Psilocybin",
            tips: "Similar to LSD: benzos help. Lie down in a dark quiet room. Sweet drinks can help. Duration is shorter than LSD — remind yourself it will pass within hours."),
        NormalizationTip(id: "mdma", substanceName: "MDMA",
            tips: "If overheating: cool environment, wet cloth on neck, stop dancing. If jaw clenching: magnesium, chew gum. If anxious: quiet space, reassurance. Do NOT take more."),
        NormalizationTip(id: "ecstasy", substanceName: "Ecstasy",
            tips: "Same as MDMA — if overheating: cool down immediately. If anxious: quiet space with a trusted person. Do NOT take another pill."),
        NormalizationTip(id: "cocaine", substanceName: "Cocaine",
            tips: "If heart racing: sit down, breathe slowly, no more stimulants. A small dose of alcohol or benzo can take the edge off (but don't combine heavily). Cold water on wrists."),
        NormalizationTip(id: "amphetamine", substanceName: "Amphetamine",
            tips: "Cannot be easily 'stopped' due to long duration. Eat, hydrate, try to rest. Melatonin or a small benzo dose may help with sleep. Do not take more."),
        NormalizationTip(id: "methamphetamine", substanceName: "Methamphetamine",
            tips: "Extremely long duration — you cannot speed this up. Focus on harm reduction: eat, hydrate, try to sleep. Benzos can help with anxiety/insomnia. Seek help if you feel psychotic."),
        NormalizationTip(id: "ketamine", substanceName: "Ketamine",
            tips: "If in a K-hole: it will pass in 15–30 minutes. Lie in recovery position. Do not try to walk. Quiet, dim environment."),
        NormalizationTip(id: "cannabis", substanceName: "Cannabis",
            tips: "Black pepper (chew 2–3 peppercorns) can reduce anxiety. Sweet food/drink helps. CBD counteracts THC. Lie down, breathe slowly. It will pass."),
        NormalizationTip(id: "alcohol", substanceName: "Alcohol",
            tips: "Cannot be sped up — only time works. Water and electrolytes. Eat starchy food. Do not induce vomiting. Recovery position if someone is unconscious."),
        NormalizationTip(id: "ghb", substanceName: "GHB",
            tips: "If someone is unresponsive: RECOVERY POSITION immediately. Monitor breathing. Call emergency services. Do NOT give stimulants to 'wake them up'."),
        NormalizationTip(id: "gbl", substanceName: "GBL",
            tips: "Same as GHB — if unresponsive: RECOVERY POSITION. Monitor breathing. Call 112/911. Do NOT try to wake with stimulants or cold water."),
        NormalizationTip(id: "alprazolam", substanceName: "Alprazolam",
            tips: "Effects cannot be reversed without medical help (flumazenil). Do not take more. Do not mix with other depressants. Monitor breathing."),
        NormalizationTip(id: "morphine", substanceName: "Morphine",
            tips: "Naloxone reverses opioid overdose. If breathing slows: call emergency services immediately. Recovery position. Do NOT let them 'sleep it off'."),
        NormalizationTip(id: "3mmc", substanceName: "3-MMC",
            tips: "Similar to cocaine/MDMA normalization. Stop redosing — this is critical. Hydrate, eat, rest. Magnesium for muscle tension. The urge to redose is deceptive — resist it."),
        NormalizationTip(id: "4mmc", substanceName: "4-MMC",
            tips: "Similar to cocaine/MDMA normalization. Stop redosing. Hydrate, eat, rest. Magnesium for muscle tension. The urge to redose is deceptive — resist it."),
    ]

    // MARK: - In-Session Care Tips (shown in CareView when substances are active)

    struct InSessionTip: Identifiable {
        let id = UUID().uuidString
        let substanceIds: Set<String>?   // nil = applies to any active substance
        let categoryFilter: SubstanceCategory?
        let comboFilter: Set<String>?    // specific combo of substance IDs
        let tip: String
    }

    static let inSessionTips: [InSessionTip] = [
        // Any stimulant
        InSessionTip(substanceIds: nil, categoryFilter: .stimulant, comboFilter: nil,
            tip: "Drink water (max 250ml/h). Eat something light. Take breaks from activity."),
        // MDMA
        InSessionTip(substanceIds: ["mdma", "ecstasy"], categoryFilter: nil, comboFilter: nil,
            tip: "Sip electrolytes, not just water. Don't drink too much water. Cool down regularly. Chew gum for jaw tension."),
        // Cocaine
        InSessionTip(substanceIds: ["cocaine"], categoryFilter: nil, comboFilter: nil,
            tip: "Rinse nose with saline after use. Long breaks between lines. Monitor heart rate."),
        // Ketamine
        InSessionTip(substanceIds: ["ketamine"], categoryFilter: nil, comboFilter: nil,
            tip: "Sit or lie down in a safe place. Don't mix with alcohol. Low doses — wait at least 15 minutes between bumps."),
        // Cannabis
        InSessionTip(substanceIds: ["cannabis"], categoryFilter: nil, comboFilter: nil,
            tip: "If anxious: change setting, breathe slowly, drink something sweet. Avoid mixing with alcohol."),
        // GHB/GBL
        InSessionTip(substanceIds: ["ghb", "gbl"], categoryFilter: nil, comboFilter: nil,
            tip: "Timer is CRITICAL — DO NOT redose within 2 hours. Stay with your sober supervisor."),
        // Psychedelics
        InSessionTip(substanceIds: ["lsd", "psilocybin"], categoryFilter: nil, comboFilter: nil,
            tip: "Set & setting are everything. If uncomfortable: change music, room, or lighting."),
        // Alcohol + Stimulants combo
        InSessionTip(substanceIds: nil, categoryFilter: nil, comboFilter: ["alcohol", "cocaine"],
            tip: "You feel less drunk than you are — don't drink more. Cocaethylene is toxic to your heart."),
        InSessionTip(substanceIds: nil, categoryFilter: nil, comboFilter: ["alcohol", "amphetamine"],
            tip: "You feel less drunk than you are — don't drink more."),
        InSessionTip(substanceIds: nil, categoryFilter: nil, comboFilter: ["alcohol", "3mmc"],
            tip: "You feel less drunk than you are — stimulants mask alcohol's effects."),
        InSessionTip(substanceIds: nil, categoryFilter: nil, comboFilter: ["alcohol", "4mmc"],
            tip: "You feel less drunk than you are — stimulants mask alcohol's effects."),
    ]

    /// Get relevant in-session tips for currently active substances
    static func inSessionTips(for activeSubstanceIds: Set<String>) -> [String] {
        guard !activeSubstanceIds.isEmpty else { return [] }
        var tips: [String] = []

        let activeSubstances = activeSubstanceIds.compactMap { Substances.byId[$0] }
        let activeCategories = Set(activeSubstances.map { $0.category })

        for tip in inSessionTips {
            // Check combo filter
            if let combo = tip.comboFilter {
                if combo.isSubset(of: activeSubstanceIds) {
                    tips.append(tip.tip)
                    continue
                }
            }

            // Check category filter
            if let category = tip.categoryFilter {
                if activeCategories.contains(category) {
                    tips.append(tip.tip)
                    continue
                }
            }

            // Check specific substance IDs
            if let ids = tip.substanceIds {
                if !ids.isDisjoint(with: activeSubstanceIds) {
                    tips.append(tip.tip)
                }
            }
        }

        return Array(Set(tips)) // deduplicate
    }
}
