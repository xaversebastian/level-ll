//
//  Warnings.swift
//  LevelEleven
//
//  Version: 1.1  |  2026-03-11
//
//  Warnsystem für Substanz-Interaktionen und Level-basierte Risiken.
//  WarningSeverity-Enum (info, caution, warning, danger) ist Comparable und
//  liefert Farbe + SF-Symbol je Stufe.
//
//  checkInteractions() prüft:
//  - Klassische Kombinations-Risiken (GHB+Alkohol, Opioid+Depressant, …)
//  - Temporale Checks: GHB-Rebound, Kokain→MDMA-Timing, SSRI-Interaktionen
//  - Neue: Stimulants+Alkohol als .warning (Herzrisiko), Entzugs-Krampfrisiko
//
//  HINWEIS: Beim Hinzufügen neuer Substanzen auch Interaktionen hier ergänzen.
//  Warnungen sind nach Severity absteigend sortiert (danger zuerst).
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

    var icon: String {
        switch self {
        case .info:    return "info.circle.fill"
        case .caution: return "exclamationmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .danger:  return "xmark.octagon.fill"
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

    // MARK: - Interaction Checks

    /// Prüft Interaktionen basierend auf aktiven Dosen + Dosishistorie + Profil.
    /// - Parameters:
    ///   - activeDoses: Dosen die aktuell noch im aktiven Fenster liegen.
    ///   - allDoses:    Gesamte Dosishistorie des Profils (für temporale Checks).
    ///   - profile:     Nutzerprofil (SSRI-Status, persönliches Limit, etc.)
    ///   - now:         Referenz-Zeitpunkt (default: Date())
    static func checkInteractions(
        activeDoses: [Dose],
        allDoses: [Dose],
        profile: Profile,
        now: Date = Date()
    ) -> [Warning] {
        var warnings: [Warning] = []
        let activeIds = Set(activeDoses.map { $0.substanceId })

        // ── DANGER: Atemwegslähmung – Opioide + Depressiva ─────────────────────
        let opioids     = Set(["morphine"])
        let depressants = Set(["alcohol", "ghb", "alprazolam"])
        if !opioids.isDisjoint(with: activeIds) && !depressants.isDisjoint(with: activeIds) {
            warnings.append(Warning(
                severity: .danger,
                title: "Respiratory Depression Risk",
                message: "Mixing opioids with depressants greatly increases overdose risk.",
                advice: "Avoid this combination. Have naloxone ready. Don't use alone."
            ))
        }

        // ── DANGER: GHB + Alkohol ────────────────────────────────────────────────
        if activeIds.contains("ghb") && activeIds.contains("alcohol") {
            warnings.append(Warning(
                severity: .danger,
                title: "Dangerous Combination",
                message: "GHB and alcohol is one of the most dangerous drug combinations.",
                advice: "Never mix G with alcohol. This can cause coma or death."
            ))
        }

        // ── DANGER: SSRI + Serotonergika ────────────────────────────────────────
        if profile.takeSSRI {
            let serotonergics = Set(["mdma", "lsd", "psilocybin"])
            if !serotonergics.isDisjoint(with: activeIds) {
                warnings.append(Warning(
                    severity: .danger,
                    title: "Serotonin Syndrome Risk",
                    message: "SSRIs combined with serotonergic substances significantly increase serotonin syndrome risk.",
                    advice: "Symptoms: hyperthermia, agitation, tremor, rapid heart rate. Seek emergency help immediately."
                ))
            }
        }

        // ── WARNING: Serotonin-Syndrom – mehrere Serotonergika ─────────────────
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
        let stimulants = Set(["cocaine", "amphetamine", "3mmc", "4mmc", "mdma"])
        if activeIds.intersection(stimulants).count >= 2 {
            warnings.append(Warning(
                severity: .warning,
                title: "Cardiovascular Strain",
                message: "Multiple stimulants increase heart rate and blood pressure significantly.",
                advice: "Stay hydrated (not too much), take breaks, cool down regularly."
            ))
        }

        // ── WARNING: Stimulants + Alkohol – Herzrisiko ──────────────────────────
        // Upgrade von .caution → .warning: Alkohol maskiert Überkonsumption + Herzbelastung
        if !stimulants.isDisjoint(with: activeIds) && activeIds.contains("alcohol") {
            warnings.append(Warning(
                severity: .warning,
                title: "Heart Strain & Masked Intoxication",
                message: "Stimulants mask alcohol effects, leading to overconsumption and increased cardiac load.",
                advice: "Drink water regularly. Monitor heart rate. Don't rely on how drunk you feel to stop drinking."
            ))
        }

        // ── WARNING: Ketamin + Depressiva ───────────────────────────────────────
        if activeIds.contains("ketamine") && !depressants.isDisjoint(with: activeIds) {
            warnings.append(Warning(
                severity: .warning,
                title: "Aspiration Risk",
                message: "Ketamine with depressants increases vomiting and passing out risk.",
                advice: "If unconscious, place in recovery position. Monitor breathing."
            ))
        }

        // ── TEMPORALE CHECKS ────────────────────────────────────────────────────

        // GHB Rebound: GHB in letzten 4h gewesen, aber jetzt nicht mehr aktiv
        let recentGHB = allDoses.filter { $0.substanceId == "ghb" && $0.minutesAgo(from: now) < 240 }
        if !recentGHB.isEmpty && !activeIds.contains("ghb") {
            warnings.append(Warning(
                severity: .warning,
                title: "GHB Rebound Risk",
                message: "GHB was taken within the last 4 hours and is now wearing off. Rebound effects possible.",
                advice: "Do NOT redose. Rebound can cause anxiety and distress. Wait it out."
            ))
        }

        // Kokain → MDMA Timing: Kokain in letzten 6h + MDMA aktiv
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

        // Krampfanfallrisiko: Stimulanzien aktiv + Alkohol kürzlich (aber jetzt nicht mehr aktiv)
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

        return warnings.sorted { $0.severity > $1.severity }
    }

    // MARK: - Level Checks

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
