// MedicationData.swift — LevelEleven
// v1.0 | 2026-03-16
// - Predefined medication list grouped by category with interaction info
// - Static ID sets for quick lookup in warnings/profile computed properties
//

import Foundation

struct MedicationData {

    // MARK: - Quick-lookup ID sets

    /// SSRIs and SNRIs — serotonergic antidepressants
    static let serotonergicMedIds: Set<String> = [
        "sertraline", "fluoxetine", "citalopram", "escitalopram",
        "venlafaxine", "duloxetine"
    ]

    /// MAOIs
    static let maoiMedIds: Set<String> = ["maoi"]

    /// Serotonergic painkillers (tramadol, tilidin)
    static let serotonergicPainkillerIds: Set<String> = ["tramadol", "tilidin"]

    // MARK: - Full predefined list

    static let all: [MedicationEntry] = heartMedications + opioidPrescriptions + painkillers + bloodThinners + antidepressants

    // MARK: Heart & Blood Pressure

    static let heartMedications: [MedicationEntry] = [
        MedicationEntry(
            id: "metoprolol", name: "Metoprolol", category: .heartMedication,
            interactionInfo: "Beta-blocker. Stimulants can override its heart-rate-lowering effect, causing dangerous blood pressure spikes."
        ),
        MedicationEntry(
            id: "bisoprolol", name: "Bisoprolol", category: .heartMedication,
            interactionInfo: "Beta-blocker. Cocaine specifically can cause paradoxical hypertension when combined."
        ),
        MedicationEntry(
            id: "ramipril", name: "Ramipril", category: .heartMedication,
            interactionInfo: "ACE inhibitor. Stimulants counteract its blood-pressure-lowering effect. Dehydration from drug use worsens kidney stress."
        ),
        MedicationEntry(
            id: "enalapril", name: "Enalapril", category: .heartMedication,
            interactionInfo: "ACE inhibitor. Similar risks as Ramipril — stimulants and dehydration increase cardiovascular strain."
        ),
        MedicationEntry(
            id: "amlodipine", name: "Amlodipine", category: .heartMedication,
            interactionInfo: "Calcium channel blocker. Stimulants can cause severe blood pressure fluctuations."
        ),
        MedicationEntry(
            id: "verapamil", name: "Verapamil", category: .heartMedication,
            interactionInfo: "Calcium channel blocker. Dangerous with stimulants (arrhythmia risk) and depressants (excessive heart rate reduction)."
        ),
        MedicationEntry(
            id: "digoxin", name: "Digoxin", category: .heartMedication,
            interactionInfo: "Cardiac glycoside. Very narrow therapeutic window. Stimulants and electrolyte imbalance from drug use can trigger fatal arrhythmias."
        ),
    ]

    // MARK: Opioid Prescription (BTM)

    static let opioidPrescriptions: [MedicationEntry] = [
        MedicationEntry(
            id: "methadone_rx", name: "Methadone", category: .opioidPrescription,
            interactionInfo: "Opioid substitute. Any additional depressant (alcohol, GHB, benzos) massively increases overdose risk. Respiratory depression can be fatal."
        ),
        MedicationEntry(
            id: "buprenorphine", name: "Buprenorphine (Subutex)", category: .opioidPrescription,
            interactionInfo: "Partial opioid agonist. Mixing with depressants causes respiratory depression. Stimulants mask overdose symptoms."
        ),
        MedicationEntry(
            id: "levomethadone", name: "Levomethadone (Polamidon)", category: .opioidPrescription,
            interactionInfo: "Opioid substitute. Same risks as methadone — never combine with alcohol, GHB, or benzodiazepines."
        ),
        MedicationEntry(
            id: "fentanyl_patch", name: "Fentanyl Patch", category: .opioidPrescription,
            interactionInfo: "Extremely potent opioid. Any additional CNS depressant can be fatal. Heat (dancing, saunas) increases absorption from patches."
        ),
        MedicationEntry(
            id: "oxycodone_rx", name: "Oxycodone", category: .opioidPrescription,
            interactionInfo: "Strong opioid. Combining with any depressant greatly increases overdose risk. Have naloxone available."
        ),
        MedicationEntry(
            id: "morphine_rx", name: "Morphine (Prescription)", category: .opioidPrescription,
            interactionInfo: "Strong opioid analgesic. Respiratory depression risk with any depressant. Never combine with alcohol or GHB."
        ),
    ]

    // MARK: Painkillers

    static let painkillers: [MedicationEntry] = [
        MedicationEntry(
            id: "ibuprofen_high", name: "Ibuprofen (high dose)", category: .painkillers,
            interactionInfo: "NSAID. Combined with alcohol increases risk of gastrointestinal bleeding. Combined with blood thinners increases bleeding risk."
        ),
        MedicationEntry(
            id: "diclofenac", name: "Diclofenac", category: .painkillers,
            interactionInfo: "NSAID. Same GI bleeding risk with alcohol as ibuprofen. Cardiovascular strain combined with stimulants."
        ),
        MedicationEntry(
            id: "metamizole", name: "Metamizole (Novalgin)", category: .painkillers,
            interactionInfo: "Can lower blood pressure. Combined with depressants or alcohol may cause dangerous hypotension."
        ),
        MedicationEntry(
            id: "tramadol", name: "Tramadol", category: .painkillers,
            interactionInfo: "Opioid + serotonin reuptake inhibitor. Serotonin syndrome risk with MDMA, LSD, psilocybin. Seizure risk with stimulants. Respiratory depression with depressants."
        ),
        MedicationEntry(
            id: "tilidin", name: "Tilidin", category: .painkillers,
            interactionInfo: "Opioid analgesic with serotonergic properties. Serotonin syndrome risk with serotonergic substances. Respiratory depression with depressants and alcohol."
        ),
    ]

    // MARK: Blood Thinners

    static let bloodThinners: [MedicationEntry] = [
        MedicationEntry(
            id: "warfarin", name: "Warfarin", category: .bloodThinners,
            interactionInfo: "Anticoagulant. Nasal drug use increases nosebleed risk. Alcohol affects metabolism — unpredictable INR changes. Injury risk while intoxicated is dangerous."
        ),
        MedicationEntry(
            id: "phenprocoumon", name: "Phenprocoumon (Marcumar)", category: .bloodThinners,
            interactionInfo: "Vitamin K antagonist. Same risks as warfarin — nasal routes, alcohol, and injury risk are all more dangerous."
        ),
        MedicationEntry(
            id: "rivaroxaban", name: "Rivaroxaban (Xarelto)", category: .bloodThinners,
            interactionInfo: "Direct oral anticoagulant. Alcohol increases bleeding risk. Nasal route causes prolonged nosebleeds. Any injury while intoxicated is higher risk."
        ),
        MedicationEntry(
            id: "apixaban", name: "Apixaban (Eliquis)", category: .bloodThinners,
            interactionInfo: "Direct oral anticoagulant. Similar to rivaroxaban — alcohol and nasal routes increase bleeding risk significantly."
        ),
        MedicationEntry(
            id: "aspirin_daily", name: "ASS / Aspirin (daily)", category: .bloodThinners,
            interactionInfo: "Antiplatelet. Increased bleeding risk with alcohol and NSAIDs. Nasal drug use more likely to cause nosebleeds."
        ),
    ]

    // MARK: Antidepressants

    static let antidepressants: [MedicationEntry] = [
        MedicationEntry(
            id: "sertraline", name: "Sertraline (Zoloft)", category: .antidepressants,
            interactionInfo: "SSRI. Serotonin syndrome risk with MDMA, LSD, psilocybin. Reduced MDMA effects but NOT reduced risk."
        ),
        MedicationEntry(
            id: "fluoxetine", name: "Fluoxetine (Prozac)", category: .antidepressants,
            interactionInfo: "SSRI with very long half-life (~6 days). Serotonin syndrome risk persists for weeks after stopping. Dangerous with all serotonergic substances."
        ),
        MedicationEntry(
            id: "citalopram", name: "Citalopram (Cipramil)", category: .antidepressants,
            interactionInfo: "SSRI. QT prolongation risk — stimulants add cardiac strain. Serotonin syndrome with MDMA/psychedelics."
        ),
        MedicationEntry(
            id: "escitalopram", name: "Escitalopram (Cipralex)", category: .antidepressants,
            interactionInfo: "SSRI. Same risks as citalopram. Serotonin syndrome with serotonergic substances."
        ),
        MedicationEntry(
            id: "venlafaxine", name: "Venlafaxine (Effexor)", category: .antidepressants,
            interactionInfo: "SNRI. Higher serotonin syndrome risk than SSRIs due to dual mechanism. Very dangerous with MDMA. Withdrawal symptoms if missed doses."
        ),
        MedicationEntry(
            id: "duloxetine", name: "Duloxetine (Cymbalta)", category: .antidepressants,
            interactionInfo: "SNRI. Serotonin syndrome risk with serotonergic substances. Also inhibits CYP enzymes — can increase levels of other drugs."
        ),
        MedicationEntry(
            id: "maoi", name: "MAOIs (any)", category: .antidepressants,
            interactionInfo: "Monoamine oxidase inhibitors. EXTREMELY dangerous with nearly all recreational substances. Serotonin syndrome, hypertensive crisis, and death possible with stimulants, MDMA, and many others."
        ),
        MedicationEntry(
            id: "mirtazapine", name: "Mirtazapine (Remeron)", category: .antidepressants,
            interactionInfo: "Noradrenergic/serotonergic antidepressant. Sedating — increased sedation with depressants and alcohol. Mild serotonin risk with MDMA."
        ),
        MedicationEntry(
            id: "bupropion", name: "Bupropion (Wellbutrin)", category: .antidepressants,
            interactionInfo: "NDRI antidepressant. Lowers seizure threshold — dangerous with stimulants, alcohol withdrawal, and high-dose use. Not serotonergic."
        ),
    ]

    // MARK: - Lookup

    static let byId: [String: MedicationEntry] = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    static func medications(for category: MedicationCategory) -> [MedicationEntry] {
        all.filter { $0.category == category }
    }
}
