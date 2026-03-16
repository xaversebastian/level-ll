// DrugComboMatrixView.swift — LevelEleven
// v1.0 | 2026-03-16
// - Interactive TripSit-style drug combination matrix
// - Uses only integrated substances + medication flags (SSRIs, MAOIs)
//

import SwiftUI

// MARK: - Combo Safety Level

enum ComboSafety: String, CaseIterable {
    case lowRiskSynergy    = "Low Risk & Synergy"
    case lowRiskNoSynergy  = "Low Risk & No Synergy"
    case lowRiskDecrease   = "Low Risk & Decrease"
    case caution           = "Caution"
    case unsafe            = "Unsafe"
    case dangerous         = "Dangerous"
    case sameSubstance     = "Same"

    var color: Color {
        switch self {
        case .lowRiskSynergy:   return Color(hex: "26A65B")
        case .lowRiskNoSynergy: return Color(hex: "3498DB")
        case .lowRiskDecrease:  return Color(hex: "F4D03F")
        case .caution:          return Color(hex: "E67E22")
        case .unsafe:           return Color(hex: "E74C3C")
        case .dangerous:        return Color(hex: "8B0000")
        case .sameSubstance:    return Color(hex: "555555")
        }
    }

    var icon: String {
        switch self {
        case .lowRiskSynergy:   return "checkmark.circle.fill"
        case .lowRiskNoSynergy: return "checkmark.circle"
        case .lowRiskDecrease:  return "arrow.down.circle"
        case .caution:          return "exclamationmark.triangle.fill"
        case .unsafe:           return "xmark.circle.fill"
        case .dangerous:        return "xmark.octagon.fill"
        case .sameSubstance:    return "minus.circle"
        }
    }

    var shortLabel: String {
        switch self {
        case .lowRiskSynergy:   return "Synergy"
        case .lowRiskNoSynergy: return "Neutral"
        case .lowRiskDecrease:  return "Decrease"
        case .caution:          return "Caution"
        case .unsafe:           return "Unsafe"
        case .dangerous:        return "Dangerous"
        case .sameSubstance:    return "—"
        }
    }
}

// MARK: - Combo Entry

struct ComboEntry {
    let safety: ComboSafety
    let note: String
}

// MARK: - Combo Data

struct ComboData {
    // Matrix entries: labels used on axes
    static let labels: [String] = [
        "Alcohol", "Cocaine", "Amphetamine", "Meth", "MDMA", "Ecstasy",
        "Ketamine", "GHB", "GBL", "Cannabis", "3-MMC", "4-MMC",
        "LSD", "Shrooms", "Xanax", "Morphine", "SSRIs", "MAOIs"
    ]

    // Substance IDs mapping to label index
    static let ids: [String] = [
        "alcohol", "cocaine", "amphetamine", "methamphetamine", "mdma", "ecstasy",
        "ketamine", "ghb", "gbl", "cannabis", "3mmc", "4mmc",
        "lsd", "psilocybin", "alprazolam", "morphine", "ssris", "maois"
    ]

    // Key: "row-col" where row < col (upper triangle), lookup both directions
    private static let entries: [String: ComboEntry] = buildMatrix()

    static func lookup(_ a: Int, _ b: Int) -> ComboEntry {
        if a == b { return ComboEntry(safety: .sameSubstance, note: "") }
        let lo = min(a, b), hi = max(a, b)
        return entries["\(lo)-\(hi)"] ?? ComboEntry(safety: .caution, note: "Insufficient data — exercise caution.")
    }

    // MARK: - Matrix Builder

    private static func buildMatrix() -> [String: ComboEntry] {
        var m: [String: ComboEntry] = [:]

        func set(_ a: String, _ b: String, _ safety: ComboSafety, _ note: String) {
            guard let ai = ids.firstIndex(of: a), let bi = ids.firstIndex(of: b) else { return }
            let lo = min(ai, bi), hi = max(ai, bi)
            m["\(lo)-\(hi)"] = ComboEntry(safety: safety, note: note)
        }

        // ── ALCOHOL combinations ──
        set("alcohol", "cocaine", .unsafe,
            "Produces cocaethylene in the liver — highly cardiotoxic. Masks alcohol intoxication, leading to overconsumption.")
        set("alcohol", "amphetamine", .unsafe,
            "Stimulants mask alcohol's sedation, leading to overconsumption. Increased cardiac strain and dehydration.")
        set("alcohol", "methamphetamine", .unsafe,
            "Same risks as alcohol + amphetamine but more extreme. Severe cardiovascular stress.")
        set("alcohol", "mdma", .unsafe,
            "Increases neurotoxicity, dehydration, and hyperthermia. Alcohol reduces MDMA's positive effects.")
        set("alcohol", "ecstasy", .unsafe,
            "Same as alcohol + MDMA. Increased neurotoxicity and dehydration risk.")
        set("alcohol", "ketamine", .unsafe,
            "Both impair coordination. Increased nausea and aspiration risk. Dangerous loss of consciousness.")
        set("alcohol", "ghb", .dangerous,
            "NEVER combine. Both are CNS depressants. Combined respiratory depression is frequently fatal.")
        set("alcohol", "gbl", .dangerous,
            "NEVER combine. GBL converts to GHB — same extreme respiratory depression risk as alcohol + GHB.")
        set("alcohol", "cannabis", .caution,
            "Cannabis intensifies alcohol effects. Increased nausea ('the spins'), impaired judgment. Cross-fading can be unpredictable.")
        set("alcohol", "3mmc", .unsafe,
            "Stimulant masks alcohol sedation. Increased cardiac strain and dehydration.")
        set("alcohol", "4mmc", .unsafe,
            "Same risks as alcohol + 3-MMC. Cardiac strain, dehydration, overconsumption risk.")
        set("alcohol", "lsd", .lowRiskDecrease,
            "Alcohol dulls psychedelic effects. Can increase confusion and nausea. Generally not dangerous but diminishes the experience.")
        set("alcohol", "psilocybin", .lowRiskDecrease,
            "Similar to alcohol + LSD. Reduces psychedelic clarity. Increased nausea likely.")
        set("alcohol", "alprazolam", .dangerous,
            "Both are CNS depressants. Combined respiratory depression risk is very high. Many overdose deaths involve this combination.")
        set("alcohol", "morphine", .dangerous,
            "Extremely dangerous. Combined respiratory depression. This combination is frequently fatal even at moderate doses.")
        set("alcohol", "ssris", .caution,
            "Alcohol can worsen depression and reduce SSRI effectiveness. Increased sedation and impaired judgment.")
        set("alcohol", "maois", .unsafe,
            "Tyramine in some alcoholic drinks can cause hypertensive crisis with MAOIs. Beer and wine are particularly risky.")

        // ── COCAINE combinations ──
        set("cocaine", "amphetamine", .caution,
            "Both stimulants. Combined cardiovascular strain is significant. Increased risk of heart attack and stroke.")
        set("cocaine", "methamphetamine", .unsafe,
            "Extreme cardiovascular stress. Both are powerful stimulants — combined risk of cardiac arrest is very high.")
        set("cocaine", "mdma", .unsafe,
            "Cocaine blocks MDMA's effects while adding cardiac stress. Increases serotonin toxicity and hyperthermia risk.")
        set("cocaine", "ecstasy", .unsafe,
            "Same as cocaine + MDMA. Cardiac stress plus reduced MDMA effects.")
        set("cocaine", "ketamine", .caution,
            "Popular combination but risky. Cocaine's stimulation can mask ketamine's warnings. Increased heart strain.")
        set("cocaine", "ghb", .unsafe,
            "Stimulant masks GHB's sedation — when cocaine wears off, GHB effects hit hard. Risk of sudden unconsciousness.")
        set("cocaine", "gbl", .unsafe,
            "Same as cocaine + GHB. When stimulant wears off, CNS depression can be overwhelming.")
        set("cocaine", "cannabis", .lowRiskNoSynergy,
            "Cannabis may increase anxiety from cocaine. Otherwise relatively low additional risk.")
        set("cocaine", "3mmc", .unsafe,
            "Both are stimulants. Combined cardiovascular strain. Risk of serotonin issues from 3-MMC + cardiac stress from cocaine.")
        set("cocaine", "4mmc", .unsafe,
            "Both stimulants with serotonergic activity. High cardiac risk and potential serotonin toxicity.")
        set("cocaine", "lsd", .caution,
            "Cocaine can increase anxiety during a trip. Cardiovascular strain. Can trigger thought loops.")
        set("cocaine", "psilocybin", .caution,
            "Similar to cocaine + LSD. May increase anxiety. Cardiovascular concern.")
        set("cocaine", "alprazolam", .caution,
            "Benzos used to 'come down' from cocaine. Risk of dependence on both. Cocaine masks benzo sedation.")
        set("cocaine", "morphine", .unsafe,
            "Speedball combination. Extremely dangerous. Cocaine masks opioid respiratory depression; when cocaine wears off, overdose risk spikes.")
        set("cocaine", "ssris", .caution,
            "SSRIs may reduce cocaine's euphoria. Mild serotonin concerns. Cardiovascular effects unchanged.")
        set("cocaine", "maois", .dangerous,
            "MAOIs potentiate cocaine dramatically. Risk of hypertensive crisis, serotonin syndrome, and cardiac arrest.")

        // ── AMPHETAMINE combinations ──
        set("amphetamine", "methamphetamine", .caution,
            "Redundant — both are amphetamines. Extremely high cardiovascular strain if combined.")
        set("amphetamine", "mdma", .unsafe,
            "Both release serotonin and increase heart rate/temperature. Serotonin toxicity and cardiac risk significantly increased.")
        set("amphetamine", "ecstasy", .unsafe,
            "Same as amphetamine + MDMA.")
        set("amphetamine", "ketamine", .lowRiskNoSynergy,
            "Amphetamine can overpower ketamine. No major interaction but increased heart strain.")
        set("amphetamine", "ghb", .caution,
            "Stimulant masks GHB sedation. When amphetamine wears off, GHB depression hits. Timing risk.")
        set("amphetamine", "gbl", .caution,
            "Same timing risk as amphetamine + GHB.")
        set("amphetamine", "cannabis", .lowRiskNoSynergy,
            "Cannabis may increase anxiety from stimulants. Otherwise low risk.")
        set("amphetamine", "3mmc", .unsafe,
            "Both stimulants with serotonergic activity. High cardiac strain and serotonin risk.")
        set("amphetamine", "4mmc", .unsafe,
            "Same as amphetamine + 3-MMC.")
        set("amphetamine", "lsd", .lowRiskNoSynergy,
            "Amphetamine can increase anxiety during psychedelic experience. Increased heart rate.")
        set("amphetamine", "psilocybin", .lowRiskNoSynergy,
            "Similar to amphetamine + LSD.")
        set("amphetamine", "alprazolam", .lowRiskDecrease,
            "Benzos used to counteract stimulant effects. Risk of dependence on both.")
        set("amphetamine", "morphine", .caution,
            "Stimulant masks opioid depression. When stimulant fades, overdose risk increases.")
        set("amphetamine", "ssris", .caution,
            "Mild serotonin concerns. SSRIs may alter amphetamine effects. Monitor for serotonin symptoms.")
        set("amphetamine", "maois", .dangerous,
            "MAOIs + amphetamines = hypertensive crisis risk. Potentially fatal. Absolutely avoid.")

        // ── METHAMPHETAMINE combinations ──
        set("methamphetamine", "mdma", .dangerous,
            "Extreme serotonin release + neurotoxicity + hyperthermia. One of the most dangerous combinations.")
        set("methamphetamine", "ecstasy", .dangerous,
            "Same as methamphetamine + MDMA.")
        set("methamphetamine", "ketamine", .caution,
            "Meth overpowers ketamine. High cardiac strain. Risk of psychosis.")
        set("methamphetamine", "ghb", .unsafe,
            "Stimulant masks GHB depression. Severe rebound risk.")
        set("methamphetamine", "gbl", .unsafe,
            "Same as methamphetamine + GHB.")
        set("methamphetamine", "cannabis", .caution,
            "Can increase paranoia and psychosis risk, especially with prolonged meth use.")
        set("methamphetamine", "3mmc", .dangerous,
            "Extreme stimulant load + serotonin risk.")
        set("methamphetamine", "4mmc", .dangerous,
            "Same as methamphetamine + 3-MMC.")
        set("methamphetamine", "lsd", .caution,
            "High risk of anxiety, psychosis, and cardiac events during psychedelic experience.")
        set("methamphetamine", "psilocybin", .caution,
            "Same as methamphetamine + LSD.")
        set("methamphetamine", "alprazolam", .caution,
            "Benzos for comedown — risk of polydrug dependence. Meth masks benzo sedation.")
        set("methamphetamine", "morphine", .unsafe,
            "Speedball variant. Stimulant masks opioid depression. Extreme overdose risk when meth wears off.")
        set("methamphetamine", "ssris", .caution,
            "Serotonin concerns. SSRIs may alter meth effects.")
        set("methamphetamine", "maois", .dangerous,
            "MAOIs + methamphetamine = hypertensive crisis. Potentially fatal.")

        // ── MDMA combinations ──
        set("mdma", "ecstasy", .caution,
            "Both contain MDMA. Easy to overdose on serotonin. Do not combine — choose one.")
        set("mdma", "ketamine", .lowRiskSynergy,
            "Popular combination. Ketamine can extend MDMA experience. Watch for overheating and stay hydrated.")
        set("mdma", "ghb", .unsafe,
            "Both increase body temperature and strain the heart. GHB's sedation masked by MDMA's stimulation. Dangerous.")
        set("mdma", "gbl", .unsafe,
            "Same risks as MDMA + GHB.")
        set("mdma", "cannabis", .lowRiskSynergy,
            "Cannabis can intensify MDMA experience. May increase anxiety in some people. Generally well-tolerated.")
        set("mdma", "3mmc", .unsafe,
            "Both are serotonergic. Combined serotonin release is dangerous. Risk of serotonin syndrome.")
        set("mdma", "4mmc", .unsafe,
            "Same as MDMA + 3-MMC.")
        set("mdma", "lsd", .lowRiskSynergy,
            "'Candy flip' — synergistic combination. Start LSD first, MDMA later. Intense experience. Increased neurotoxicity risk.")
        set("mdma", "psilocybin", .lowRiskSynergy,
            "'Hippy flip' — synergistic. Similar to candy flip but shorter. Start shrooms first.")
        set("mdma", "alprazolam", .lowRiskDecrease,
            "Benzos reduce MDMA effects significantly. Used as a 'landing gear' but diminishes the experience.")
        set("mdma", "morphine", .unsafe,
            "Serotonin concerns + respiratory depression when MDMA wears off. Dangerous.")
        set("mdma", "ssris", .unsafe,
            "SSRIs block MDMA's effects (waste of dose) AND risk serotonin syndrome. Do not combine. Minimum 2-week SSRI washout.")
        set("mdma", "maois", .dangerous,
            "Potentially fatal serotonin syndrome. ABSOLUTELY NEVER combine MDMA with MAOIs.")

        // ── ECSTASY ──
        set("ecstasy", "ketamine", .lowRiskSynergy,
            "Same as MDMA + ketamine (ecstasy contains MDMA).")
        set("ecstasy", "ghb", .unsafe, "Same as MDMA + GHB.")
        set("ecstasy", "gbl", .unsafe, "Same as MDMA + GBL.")
        set("ecstasy", "cannabis", .lowRiskSynergy, "Same as MDMA + cannabis.")
        set("ecstasy", "3mmc", .unsafe, "Same as MDMA + 3-MMC.")
        set("ecstasy", "4mmc", .unsafe, "Same as MDMA + 4-MMC.")
        set("ecstasy", "lsd", .lowRiskSynergy, "Candy flip — same as MDMA + LSD.")
        set("ecstasy", "psilocybin", .lowRiskSynergy, "Hippy flip — same as MDMA + shrooms.")
        set("ecstasy", "alprazolam", .lowRiskDecrease, "Same as MDMA + alprazolam.")
        set("ecstasy", "morphine", .unsafe, "Same as MDMA + morphine.")
        set("ecstasy", "ssris", .unsafe, "Same as MDMA + SSRIs.")
        set("ecstasy", "maois", .dangerous, "Same as MDMA + MAOIs. Potentially fatal.")

        // ── KETAMINE combinations ──
        set("ketamine", "ghb", .dangerous,
            "Both cause unconsciousness. Combined risk of unresponsiveness and aspiration is extreme.")
        set("ketamine", "gbl", .dangerous,
            "Same as ketamine + GHB.")
        set("ketamine", "cannabis", .lowRiskSynergy,
            "Cannabis deepens dissociation. Can be pleasant but also disorienting. Low dose recommended.")
        set("ketamine", "3mmc", .caution,
            "Stimulant can overpower dissociation. Increased heart rate. Watch for overheating.")
        set("ketamine", "4mmc", .caution,
            "Same as ketamine + 3-MMC.")
        set("ketamine", "lsd", .lowRiskSynergy,
            "Ketamine deepens psychedelic experience significantly. Very intense — experienced users only.")
        set("ketamine", "psilocybin", .lowRiskSynergy,
            "Similar to ketamine + LSD. Very immersive. Low dose recommended.")
        set("ketamine", "alprazolam", .caution,
            "Both are sedating. Increased risk of unconsciousness and respiratory depression.")
        set("ketamine", "morphine", .dangerous,
            "Both depress breathing and consciousness. Combined respiratory failure risk is very high.")
        set("ketamine", "ssris", .lowRiskNoSynergy,
            "No major known interaction. Ketamine has its own antidepressant properties.")
        set("ketamine", "maois", .caution,
            "Limited data. MAOIs may potentiate ketamine. Exercise caution.")

        // ── GHB combinations ──
        set("ghb", "gbl", .dangerous,
            "GBL converts to GHB — this is doubling the dose. Extreme overdose risk.")
        set("ghb", "cannabis", .caution,
            "Cannabis may increase nausea and sedation. Lower both doses.")
        set("ghb", "3mmc", .unsafe,
            "Stimulant masks GHB sedation. Rebound risk when stimulant fades.")
        set("ghb", "4mmc", .unsafe, "Same as GHB + 3-MMC.")
        set("ghb", "lsd", .caution,
            "GHB can cause sudden unconsciousness during a trip. Risky and unpredictable.")
        set("ghb", "psilocybin", .caution, "Same concerns as GHB + LSD.")
        set("ghb", "alprazolam", .dangerous,
            "Both are CNS depressants. Combined respiratory depression is frequently fatal.")
        set("ghb", "morphine", .dangerous,
            "Three-way CNS depression. Extremely high risk of fatal respiratory arrest.")
        set("ghb", "ssris", .lowRiskNoSynergy,
            "No major interaction known, but GHB affects GABA not serotonin.")
        set("ghb", "maois", .caution,
            "Limited data. Exercise caution.")

        // ── GBL (same as GHB for most combos) ──
        set("gbl", "cannabis", .caution, "Same as GHB + cannabis.")
        set("gbl", "3mmc", .unsafe, "Same as GHB + 3-MMC.")
        set("gbl", "4mmc", .unsafe, "Same as GHB + 4-MMC.")
        set("gbl", "lsd", .caution, "Same as GHB + LSD.")
        set("gbl", "psilocybin", .caution, "Same as GHB + shrooms.")
        set("gbl", "alprazolam", .dangerous, "Same as GHB + alprazolam.")
        set("gbl", "morphine", .dangerous, "Same as GHB + morphine.")
        set("gbl", "ssris", .lowRiskNoSynergy, "Same as GHB + SSRIs.")
        set("gbl", "maois", .caution, "Same as GHB + MAOIs.")

        // ── CANNABIS combinations ──
        set("cannabis", "3mmc", .lowRiskNoSynergy,
            "Cannabis may increase anxiety from stimulants. Otherwise low additional risk.")
        set("cannabis", "4mmc", .lowRiskNoSynergy, "Same as cannabis + 3-MMC.")
        set("cannabis", "lsd", .caution,
            "Cannabis can dramatically intensify psychedelic effects. Many 'bad trips' involve cannabis. Extreme caution.")
        set("cannabis", "psilocybin", .caution,
            "Same as cannabis + LSD. Can intensify trip significantly and unpredictably.")
        set("cannabis", "alprazolam", .lowRiskSynergy,
            "Both are relaxing. Cannabis may increase sedation. Generally well-tolerated.")
        set("cannabis", "morphine", .lowRiskSynergy,
            "Cannabis may enhance pain relief. Both are sedating. Risk of excessive sedation.")
        set("cannabis", "ssris", .lowRiskNoSynergy,
            "No major interaction. Cannabis may affect mood in either direction.")
        set("cannabis", "maois", .lowRiskNoSynergy,
            "No major interaction known.")

        // ── 3-MMC combinations ──
        set("3mmc", "4mmc", .caution,
            "Both cathinones with similar mechanisms. Redundant and increased serotonin + cardiac risk.")
        set("3mmc", "lsd", .lowRiskNoSynergy,
            "3-MMC can increase anxiety during trip. Increased heart rate.")
        set("3mmc", "psilocybin", .lowRiskNoSynergy, "Same as 3-MMC + LSD.")
        set("3mmc", "alprazolam", .lowRiskDecrease,
            "Benzos reduce stimulant effects. Risk of polydrug dependence.")
        set("3mmc", "morphine", .unsafe,
            "Stimulant masks opioid depression. Overdose risk when stimulant wears off.")
        set("3mmc", "ssris", .unsafe,
            "3-MMC is serotonergic. Combined serotonin risk with SSRIs. Avoid.")
        set("3mmc", "maois", .dangerous,
            "MAOIs + serotonergic stimulants = serotonin syndrome risk. Potentially fatal.")

        // ── 4-MMC combinations ──
        set("4mmc", "lsd", .lowRiskNoSynergy, "Same as 3-MMC + LSD.")
        set("4mmc", "psilocybin", .lowRiskNoSynergy, "Same as 3-MMC + shrooms.")
        set("4mmc", "alprazolam", .lowRiskDecrease, "Same as 3-MMC + alprazolam.")
        set("4mmc", "morphine", .unsafe, "Same as 3-MMC + morphine.")
        set("4mmc", "ssris", .unsafe, "Same as 3-MMC + SSRIs.")
        set("4mmc", "maois", .dangerous, "Same as 3-MMC + MAOIs.")

        // ── LSD combinations ──
        set("lsd", "psilocybin", .lowRiskSynergy,
            "Both are psychedelics. Effects stack — very intense. Reduce doses of both significantly.")
        set("lsd", "alprazolam", .lowRiskDecrease,
            "'Trip killer' — benzos significantly reduce psychedelic effects. Used as emergency abort.")
        set("lsd", "morphine", .lowRiskNoSynergy,
            "No major pharmacological interaction. Opioids may dull the psychedelic experience slightly.")
        set("lsd", "ssris", .lowRiskDecrease,
            "SSRIs significantly reduce LSD effects. Most people report little to no trip on SSRIs.")
        set("lsd", "maois", .caution,
            "MAOIs can significantly potentiate LSD. Reduce dose drastically if combining.")

        // ── PSILOCYBIN combinations ──
        set("psilocybin", "alprazolam", .lowRiskDecrease,
            "'Trip killer' — same as LSD + benzos. Reduces psychedelic effects.")
        set("psilocybin", "morphine", .lowRiskNoSynergy,
            "No major interaction. Opioids may slightly dull the experience.")
        set("psilocybin", "ssris", .lowRiskDecrease,
            "SSRIs reduce psilocybin effects significantly. Similar to LSD + SSRIs.")
        set("psilocybin", "maois", .caution,
            "MAOIs potentiate psilocybin. 'Psilohuasca' — much more intense and longer. Reduce dose significantly.")

        // ── ALPRAZOLAM combinations ──
        set("alprazolam", "morphine", .dangerous,
            "Both are CNS depressants. #1 cause of overdose deaths worldwide. NEVER combine opioids and benzodiazepines.")
        set("alprazolam", "ssris", .lowRiskNoSynergy,
            "Commonly prescribed together. Benzos for acute anxiety, SSRIs for long-term. Monitor sedation.")
        set("alprazolam", "maois", .caution,
            "Generally avoided in clinical practice. Increased sedation risk.")

        // ── MORPHINE combinations ──
        set("morphine", "ssris", .lowRiskNoSynergy,
            "Some opioids (tramadol) have serotonin risk with SSRIs. Morphine has minimal serotonin activity — relatively safer.")
        set("morphine", "maois", .dangerous,
            "MAOIs + opioids = risk of serotonin syndrome and potentiated respiratory depression. Potentially fatal.")

        // ── SSRIs + MAOIs ──
        set("ssris", "maois", .dangerous,
            "NEVER combine. Serotonin syndrome risk is extreme and potentially fatal. Minimum 2-week washout between switching.")

        return m
    }
}

// MARK: - Matrix View

struct DrugComboMatrixView: View {
    @State private var selectedCombo: (Int, Int)?
    @State private var showDetail = false

    private let cellSize: CGFloat = 36
    private let labelWidth: CGFloat = 70

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Legend
                legendView
                    .padding(.horizontal, DS.screenPadding)

                // Matrix
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header row
                        HStack(spacing: 0) {
                            Color.clear.frame(width: labelWidth, height: cellSize)
                            ForEach(0..<ComboData.labels.count, id: \.self) { col in
                                Text(ComboData.labels[col])
                                    .font(.system(size: 7, weight: .medium))
                                    .lineLimit(1)
                                    .frame(width: cellSize, height: cellSize)
                                    .rotationEffect(.degrees(-60), anchor: .bottomLeading)
                                    .offset(x: 10, y: -4)
                            }
                        }
                        .frame(height: 60)

                        // Matrix rows
                        ForEach(0..<ComboData.labels.count, id: \.self) { row in
                            HStack(spacing: 0) {
                                Text(ComboData.labels[row])
                                    .font(.system(size: 8, weight: .semibold))
                                    .lineLimit(1)
                                    .frame(width: labelWidth, alignment: .trailing)
                                    .padding(.trailing, 4)

                                ForEach(0..<ComboData.labels.count, id: \.self) { col in
                                    let entry = ComboData.lookup(row, col)
                                    Button {
                                        if row != col {
                                            selectedCombo = (row, col)
                                            showDetail = true
                                        }
                                    } label: {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(entry.safety.color)
                                            .frame(width: cellSize - 2, height: cellSize - 2)
                                            .overlay {
                                                if entry.safety == .dangerous || entry.safety == .unsafe {
                                                    Image(systemName: entry.safety == .dangerous ? "xmark" : "exclamationmark")
                                                        .font(.system(size: 8, weight: .black))
                                                        .foregroundStyle(.white.opacity(0.6))
                                                }
                                            }
                                    }
                                    .buttonStyle(.plain)
                                    .frame(width: cellSize, height: cellSize)
                                }
                            }
                        }
                    }
                    .padding(.leading, DS.screenPadding)
                    .padding(.trailing, 20)
                }
            }
            .padding(.vertical, 16)
        }
        .scrollIndicators(.hidden)
        .background(Color.appBackground)
        .navigationTitle("Drug Combinations")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showDetail) {
            if let (row, col) = selectedCombo {
                comboDetailSheet(row: row, col: col)
            }
        }
    }

    // MARK: - Legend

    private var legendView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Tap any cell for details. Data based on TripSit combination chart.")
                .font(.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                ForEach(ComboSafety.allCases.filter { $0 != .sameSubstance }, id: \.rawValue) { level in
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(level.color)
                            .frame(width: 14, height: 14)
                        Text(level.rawValue)
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - Detail Sheet

    private func comboDetailSheet(row: Int, col: Int) -> some View {
        let entry = ComboData.lookup(row, col)
        let nameA = ComboData.labels[row]
        let nameB = ComboData.labels[col]

        return NavigationStack {
            VStack(spacing: 20) {
                // Header
                HStack(spacing: 12) {
                    Image(systemName: entry.safety.icon)
                        .font(.title)
                        .foregroundStyle(entry.safety.color)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(nameA) + \(nameB)")
                            .font(.headline)
                        Text(entry.safety.rawValue)
                            .font(.subheadline.bold())
                            .foregroundStyle(entry.safety.color)
                    }
                    Spacer()
                }

                // Safety bar
                RoundedRectangle(cornerRadius: 4)
                    .fill(entry.safety.color.gradient)
                    .frame(height: 6)

                // Note
                if !entry.note.isEmpty {
                    Text(entry.note)
                        .font(.subheadline)
                        .lineSpacing(4)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer()
            }
            .padding(DS.screenPadding)
            .background(Color.appBackground)
            .navigationTitle("Combination Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showDetail = false }
                }
            }
            .presentationDetents([.medium])
        }
    }
}
