// Warnings.swift — LevelEleven
// v2.0 | 2026-03-12 17:18
// - Interaction and level-based warning system with severity tiers
// - Stripped legacy comments, added structured header
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
        case .info:    return .blue
        case .caution: return .yellow
        case .warning: return .orange
        case .danger:  return .red
        }
    }

    var calmColor: Color {
        switch self {
        case .info:    return Color.levelCalm
        case .caution: return Color.levelCalm
        case .warning: return Color.levelAmber
        case .danger:  return Color.levelAmber
        }
    }

    var icon: String {
        switch self {
        case .info:    return "info.circle.fill"
        case .caution: return "exclamationmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .danger:  return "xmark.octagon.fill"
        }
    }

    var calmIcon: String {
        switch self {
        case .info:    return "leaf.fill"
        case .caution: return "hand.raised.fill"
        case .warning: return "heart.circle.fill"
        case .danger:  return "exclamationmark.circle.fill"
        }
    }

    func displayColor(calm: Bool) -> Color { calm ? calmColor : color }
    func displayIcon(calm: Bool) -> String { calm ? calmIcon : icon }
}

struct Warning: Identifiable {
    let id = UUID().uuidString
    let severity: WarningSeverity
    let title: String
    let message: String
    let advice: String
}

struct WarningSystem {

    // MARK: - Interaction Checks

    /// Checks interactions based on active doses + dose history + profile.
    /// - Parameters:
    ///   - activeDoses: Doses currently in the active window.
    ///   - allDoses:    Full dose history for the profile (for temporal checks).
    ///   - profile:     User profile (SSRI status, personal limit, etc.)
    ///   - now:         Reference time (default: Date())
    static func checkInteractions(
        activeDoses: [Dose],
        allDoses: [Dose],
        profile: Profile,
        now: Date = Date()
    ) -> [Warning] {
        var warnings: [Warning] = []
        let activeIds = Set(activeDoses.map { $0.substanceId })
        let opioids     = Set(["morphine"])
        let depressants = Set(["alcohol", "ghb", "gbl", "alprazolam"])
        let stimulants  = Set(["cocaine", "amphetamine", "methamphetamine", "3mmc", "4mmc", "mdma"])

        // ── DANGER: Respiratory depression – Opioids + Depressants ─────────────
        if !opioids.isDisjoint(with: activeIds) && !depressants.isDisjoint(with: activeIds) {
            warnings.append(Warning(
                severity: .danger,
                title: "Respiratory Depression Risk",
                message: "Mixing opioids with depressants greatly increases overdose risk.",
                advice: "Avoid this combination. Have naloxone ready. Don't use alone."
            ))
        }

        // ── DANGER: GHB/GBL + Alcohol ──────────────────────────────────────────────────────────
        let gSubstances = Set(["ghb", "gbl"])
        if !gSubstances.isDisjoint(with: activeIds) && activeIds.contains("alcohol") {
            warnings.append(Warning(
                severity: .danger,
                title: "Lethal Combination",
                message: "GHB/GBL and alcohol is one of the most dangerous drug combinations. This kills.",
                advice: "NEVER mix G with alcohol. This combination causes respiratory arrest, coma, and death."
            ))
        }

        // ── DANGER: GHB + GBL together ────────────────────────────────────────────────────────
        if activeIds.contains("ghb") && activeIds.contains("gbl") {
            warnings.append(Warning(
                severity: .danger,
                title: "GHB + GBL Active",
                message: "Both GHB and GBL are active. GBL converts to GHB in the body — this stacks dangerously.",
                advice: "Do NOT take more of either. Monitor breathing. Have someone watch you."
            ))
        }

        // ── DANGER: SSRI/SNRI + Serotonergics ────────────────────────────────────
        if profile.hasSSRI {
            let serotonergics = Set(["mdma", "lsd", "psilocybin"])
            if !serotonergics.isDisjoint(with: activeIds) {
                warnings.append(Warning(
                    severity: .danger,
                    title: "Serotonin Syndrome Risk",
                    message: "SSRIs/SNRIs combined with serotonergic substances significantly increase serotonin syndrome risk.",
                    advice: "Symptoms: hyperthermia, agitation, tremor, rapid heart rate. Seek emergency help immediately."
                ))
            }
        }

        // ── DANGER: MAOI + Nearly Everything ──────────────────────────────────────
        if profile.hasMAOI && !activeIds.isEmpty {
            warnings.append(Warning(
                severity: .danger,
                title: "MAOI: Lethal Interactions",
                message: "MAOIs interact dangerously with nearly all recreational substances. Hypertensive crisis, serotonin syndrome, and death are possible.",
                advice: "Do NOT use recreational substances with MAOIs. Seek emergency help if you experience severe headache, chest pain, or confusion."
            ))
        }

        // ── DANGER: Opioid Prescription + Any Depressant ──────────────────────────
        if profile.hasOpioidPrescription && !depressants.isDisjoint(with: activeIds) {
            warnings.append(Warning(
                severity: .danger,
                title: "Opioid Rx + Depressant: Fatal Risk",
                message: "Your opioid prescription combined with depressants (alcohol, GHB, benzos) can cause fatal respiratory depression.",
                advice: "This combination kills. Do NOT mix. Have naloxone available. Never use alone."
            ))
        }

        // ── DANGER: Serotonergic Painkillers + Serotonergics ──────────────────────
        if profile.hasSerotonergicPainkillers {
            let serotonergics = Set(["mdma", "lsd", "psilocybin"])
            if !serotonergics.isDisjoint(with: activeIds) {
                warnings.append(Warning(
                    severity: .danger,
                    title: "Tramadol/Tilidin + Serotonergics",
                    message: "Tramadol and tilidin have serotonergic properties. Combined with MDMA, LSD, or psilocybin this can cause serotonin syndrome.",
                    advice: "Symptoms: hyperthermia, agitation, seizures. Seek emergency help immediately."
                ))
            }
        }

        // ── WARNING: Heart Medication + Stimulants ────────────────────────────────
        if profile.hasHeartMedication && !stimulants.isDisjoint(with: activeIds) {
            let severity: WarningSeverity = activeIds.contains("cocaine") ? .danger : .warning
            warnings.append(Warning(
                severity: severity,
                title: "Heart Medication + Stimulants",
                message: activeIds.contains("cocaine")
                    ? "Cocaine with heart medication (especially beta-blockers) can cause paradoxical hypertension and cardiac emergency."
                    : "Stimulants counteract your heart medication and increase cardiovascular strain significantly.",
                advice: "Monitor heart rate closely. Chest pain or irregular heartbeat = call emergency services."
            ))
        }

        // ── WARNING: Blood Thinners + Nasal Route ─────────────────────────────────
        if profile.hasBloodThinners {
            let nasalDoses = activeDoses.filter { $0.route == .nasal }
            if !nasalDoses.isEmpty {
                warnings.append(Warning(
                    severity: .warning,
                    title: "Blood Thinners + Nasal Use",
                    message: "Blood thinners significantly increase nosebleed risk with nasal drug use. Bleeding may be prolonged and hard to stop.",
                    advice: "Consider a different route of administration. If nosebleed occurs, apply pressure for 15+ minutes."
                ))
            }
            if activeIds.contains("alcohol") {
                warnings.append(Warning(
                    severity: .warning,
                    title: "Blood Thinners + Alcohol",
                    message: "Alcohol increases bleeding risk when on blood thinners. Internal bleeding risk is elevated.",
                    advice: "Minimize alcohol consumption. Be careful with physical activity. Seek help for any unusual bruising or bleeding."
                ))
            }
        }

        // ── WARNING: Serotonin syndrome – multiple serotonergics ────────────────
        let serotonergics = Set(["mdma", "lsd", "psilocybin"])
        if activeIds.intersection(serotonergics).count >= 2 {
            warnings.append(Warning(
                severity: .warning,
                title: "Serotonin Syndrome Risk",
                message: "Multiple serotonergic substances increase risk of serotonin syndrome.",
                advice: "Symptoms: high temperature, agitation, tremor. Seek medical help if severe."
            ))
        }

        // ── WARNING: Stimulant Stacking ─────────────────────────────────────────
        if activeIds.intersection(stimulants).count >= 2 {
            warnings.append(Warning(
                severity: .warning,
                title: "Cardiovascular Strain",
                message: "Multiple stimulants increase heart rate and blood pressure significantly.",
                advice: "Stay hydrated (not too much), take breaks, cool down regularly."
            ))
        }

        // ── WARNING: Bupropion + Stimulants (seizure threshold) ───────────────────
        let hasBupropion = profile.medications.contains { $0.isActive && $0.id == "bupropion" }
        if hasBupropion && !stimulants.isDisjoint(with: activeIds) {
            warnings.append(Warning(
                severity: .warning,
                title: "Bupropion + Stimulants: Seizure Risk",
                message: "Bupropion lowers the seizure threshold. Stimulants increase this risk further.",
                advice: "Avoid stimulants while on bupropion. Seek help immediately if you experience a seizure."
            ))
        }

        // ── WARNING: Stimulants + Alcohol – cardiac risk ────────────────────────
        if !stimulants.isDisjoint(with: activeIds) && activeIds.contains("alcohol") {
            warnings.append(Warning(
                severity: .warning,
                title: "Heart Strain & Masked Intoxication",
                message: "Stimulants mask alcohol effects, leading to overconsumption and increased cardiac load.",
                advice: "Drink water regularly. Monitor heart rate. Don't rely on how drunk you feel to stop drinking."
            ))
        }

        // ── WARNING: Ketamine + Depressants ──────────────────────────────────────
        if activeIds.contains("ketamine") && !depressants.isDisjoint(with: activeIds) {
            warnings.append(Warning(
                severity: .warning,
                title: "Aspiration Risk",
                message: "Ketamine with depressants increases vomiting and passing out risk.",
                advice: "If unconscious, place in recovery position. Monitor breathing."
            ))
        }

        // ── TEMPORAL CHECKS ─────────────────────────────────────────────────────

        // GHB/GBL Early Redose Warning: any G dose in last 2h → DANGER
        let recentG = allDoses.filter { (($0.substanceId == "ghb") || ($0.substanceId == "gbl")) && $0.minutesAgo(from: now) < 120 }
        let gNowActive = !gSubstances.isDisjoint(with: activeIds)
        if !recentG.isEmpty && gNowActive {
            let lastGMinutes = recentG.map { $0.minutesAgo(from: now) }.min() ?? 0
            if lastGMinutes < 90 {
                warnings.append(Warning(
                    severity: .danger,
                    title: "DO NOT REDOSE G",
                    message: "Last GHB/GBL dose was only \(Int(lastGMinutes)) minutes ago. Redosing within 2 hours is extremely dangerous and the most common cause of G-lock.",
                    advice: "WAIT at least 2 full hours from your last dose. Set a timer. The urge to redose is deceptive — effects may still be building."
                ))
            }
        }

        // GHB/GBL Rebound: G taken in last 4h but no longer active
        let recentGRebound = allDoses.filter { (($0.substanceId == "ghb") || ($0.substanceId == "gbl")) && $0.minutesAgo(from: now) < 240 }
        if !recentGRebound.isEmpty && !gNowActive {
            warnings.append(Warning(
                severity: .danger,
                title: "GHB/GBL Rebound Risk",
                message: "GHB/GBL was taken within the last 4 hours and is now wearing off. Rebound effects are common and dangerous.",
                advice: "Do NOT redose during the rebound period. Rebound can cause severe anxiety, insomnia, tremors. If you feel unwell, seek help."
            ))
        }

        // Cocaine → MDMA Timing
        let recentCocaine = allDoses.filter { $0.substanceId == "cocaine" && $0.minutesAgo(from: now) < 360 }
        if activeIds.contains("mdma") && !recentCocaine.isEmpty {
            let minAgo = recentCocaine.map { $0.minutesAgo(from: now) }.min() ?? 0
            if minAgo < 60 {
                warnings.append(Warning(
                    severity: .warning,
                    title: "Cocaine + MDMA: Cardiac Risk",
                    message: "Cocaine and MDMA taken simultaneously puts severe strain on the heart.",
                    advice: "Monitor heart rate closely. Avoid redosing. Cool down."
                ))
            } else {
                warnings.append(Warning(
                    severity: .caution,
                    title: "Recent Cocaine + MDMA",
                    message: "Cocaine \(Int(minAgo / 60))h before MDMA – heart still under residual stress.",
                    advice: "Keep doses low. Monitor heart rate. Stay cool and hydrated."
                ))
            }
        }

        // Seizure risk: stimulants active + alcohol recently worn off
        let recentAlcohol = allDoses.filter { $0.substanceId == "alcohol" && $0.minutesAgo(from: now) < 480 }
        let alcoholNowActive = activeIds.contains("alcohol")
        if !stimulants.isDisjoint(with: activeIds) && !recentAlcohol.isEmpty && !alcoholNowActive {
            warnings.append(Warning(
                severity: .warning,
                title: "Seizure Risk",
                message: "Stimulants while alcohol is wearing off can trigger seizures in susceptible individuals.",
                advice: "Avoid stimulants during alcohol withdrawal. Stay with friends. Seek help if you feel unwell."
            ))
        }

        // ── INFO: MDMA Guidelines ───────────────────────────────────────────────
        if activeIds.contains("mdma") {
            warnings.append(Warning(
                severity: .info,
                title: "MDMA Guidelines",
                message: "Wait at least 6-8 weeks between MDMA uses for safety.",
                advice: "Stay cool, take breaks from dancing, sip water (not too much)."
            ))
        }

        // ── PROLEVEL: Beginner educational warnings ───────────────────────────────
        if profile.proLevel <= 2 {
            if !activeIds.isEmpty {
                warnings.append(Warning(
                    severity: .info,
                    title: "Stay Hydrated",
                    message: "Drink water regularly but not excessively (~250ml/h).",
                    advice: "Small sips every 15-20 minutes. Avoid alcohol as your only fluid."
                ))
            }
            if !stimulants.isDisjoint(with: activeIds) {
                warnings.append(Warning(
                    severity: .info,
                    title: "Stimulant Safety",
                    message: "Stimulants mask tiredness and hunger. Your body still needs rest.",
                    advice: "Take breaks, eat something light, monitor your heart rate."
                ))
            }
            if activeIds.contains("ketamine") {
                warnings.append(Warning(
                    severity: .info,
                    title: "K-Hole Awareness",
                    message: "Higher doses of ketamine can cause intense dissociation (K-hole).",
                    advice: "Start low, wait 15+ minutes. Sit or lie down in a safe place."
                ))
            }
        }

        // ── PROLEVEL: Experienced users — filter out info-level clutter ────────────
        if profile.proLevel >= 4 {
            return warnings.filter { $0.severity > .info }.sorted { $0.severity > $1.severity }
        }

        return warnings.sorted { $0.severity > $1.severity }
    }

    // MARK: - Level Checks

    static func checkLevel(level: Double, limit: Int, proLevel: Int = 3) -> [Warning] {
        var warnings: [Warning] = []

        if level >= Double(limit) {
            warnings.append(Warning(
                severity: .warning,
                title: "Personal Limit Reached",
                message: "You've reached your personal comfort limit of \(limit).",
                advice: "Consider stopping. Take a break. Stay with friends."
            ))
        }

        // Beginners get earlier high-level warnings
        let highThreshold: Double = proLevel <= 2 ? 6 : 8
        if level >= highThreshold {
            warnings.append(Warning(
                severity: .warning,
                title: "High Intoxication",
                message: proLevel <= 2
                    ? "Your level is getting high. This is stronger than recommended for your experience."
                    : "Your current level is quite high.",
                advice: "Find a safe place. Stay with trusted friends. Hydrate."
            ))
        }

        let extremeThreshold: Double = proLevel <= 2 ? 8 : 10
        if level >= extremeThreshold {
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
