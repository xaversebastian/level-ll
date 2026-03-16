// InfoViews.swift — LevelEleven
// v1.0 | 2026-03-16
// - Interaction Guide, Harm Reduction Basics, Drug Checking Services
//

import SwiftUI

// MARK: - Interaction Guide

struct InteractionGuideView: View {
    private func sectionHeader(_ title: String, color: Color = .secondary) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 4, height: 16)
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(color)
            Spacer()
        }
        .padding(.horizontal, DS.screenPadding)
        .padding(.top, 22)
        .padding(.bottom, 8)
    }

    private struct InteractionEntry: Identifiable {
        let id = UUID().uuidString
        let combo: String
        let severity: String // "danger", "warning", "caution"
        let description: String
    }

    private let interactions: [InteractionEntry] = [
        InteractionEntry(combo: "Alcohol + Cocaine", severity: "danger",
            description: "Produces cocaethylene in the liver — highly cardiotoxic. Masks alcohol intoxication, leading to overconsumption. Significantly increased risk of sudden cardiac death."),
        InteractionEntry(combo: "Alcohol + GHB/GBL", severity: "danger",
            description: "Both are CNS depressants. Combined they potentiate respiratory depression dramatically. This combination has caused many deaths. NEVER combine."),
        InteractionEntry(combo: "Opioids + Benzodiazepines", severity: "danger",
            description: "Both depress breathing. Combined risk of fatal respiratory arrest is extremely high. This is the #1 cause of drug overdose deaths worldwide."),
        InteractionEntry(combo: "Opioids + Alcohol", severity: "danger",
            description: "Same mechanism as opioids + benzos. Respiratory depression is dramatically increased. Even small amounts of alcohol can be fatal with opioids."),
        InteractionEntry(combo: "MDMA + SSRIs/MAOIs", severity: "danger",
            description: "SSRIs reduce MDMA effects (waste of dose + serotonin strain). MAOIs + MDMA = potentially fatal serotonin syndrome. Never combine MDMA with MAOIs."),
        InteractionEntry(combo: "Stimulants + Stimulants", severity: "warning",
            description: "Combining cocaine + amphetamine or any stimulant combo greatly increases cardiovascular strain. Heart rate and blood pressure can reach dangerous levels."),
        InteractionEntry(combo: "MDMA + Amphetamine", severity: "warning",
            description: "Both release serotonin and increase heart rate/temperature. Combined risk of overheating, serotonin toxicity, and cardiac events is significantly higher."),
        InteractionEntry(combo: "Ketamine + Alcohol", severity: "warning",
            description: "Both impair coordination and consciousness. Increased risk of vomiting while dissociated (aspiration danger). Nausea and confusion amplified."),
        InteractionEntry(combo: "Cannabis + Psychedelics", severity: "caution",
            description: "Cannabis can dramatically intensify psychedelic effects, sometimes causing anxiety/panic. Many 'bad trips' involve cannabis. Use with extreme caution."),
        InteractionEntry(combo: "Cocaine + MDMA", severity: "warning",
            description: "Cocaine blocks MDMA's effects while adding cardiac stress. You feel less MDMA but more heart strain. Increases risk of serotonin issues and hyperthermia."),
        InteractionEntry(combo: "GHB/GBL + Ketamine", severity: "danger",
            description: "Both cause unconsciousness. Combined risk of unresponsiveness is extreme. Recovery position essential. This combo has caused many hospitalizations."),
        InteractionEntry(combo: "Stimulants + Heart Medication", severity: "warning",
            description: "Beta-blockers + stimulants can cause paradoxical hypertension. Stimulants counteract blood-pressure medications, creating dangerous cardiovascular instability."),
        InteractionEntry(combo: "Tramadol + MDMA", severity: "danger",
            description: "Both are serotonergic. Combined risk of serotonin syndrome and seizures. Tramadol also lowers seizure threshold, which stimulants exacerbate."),
        InteractionEntry(combo: "Lithium + Psychedelics", severity: "danger",
            description: "Reports of seizures and psychotic episodes. If you take lithium, psychedelics are strongly contraindicated."),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Text("Common dangerous combinations and what to know about them. The app also checks these automatically when you log doses.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, DS.screenPadding)
                    .padding(.vertical, 12)

                sectionHeader("Dangerous (Avoid)", color: .red)
                ForEach(interactions.filter { $0.severity == "danger" }) { entry in
                    interactionRow(entry)
                }

                sectionHeader("High Risk", color: .orange)
                ForEach(interactions.filter { $0.severity == "warning" }) { entry in
                    interactionRow(entry)
                }

                sectionHeader("Use Caution", color: .yellow)
                ForEach(interactions.filter { $0.severity == "caution" }) { entry in
                    interactionRow(entry)
                }
            }
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
        .background(Color.appBackground)
        .navigationTitle("Interaction Guide")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func interactionRow(_ entry: InteractionEntry) -> some View {
        let color: Color = entry.severity == "danger" ? .red : entry.severity == "warning" ? .orange : .yellow
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: entry.severity == "danger" ? "xmark.octagon.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(color)
                    .frame(width: 22)
                Text(entry.combo)
                    .font(.subheadline.bold())
            }
            Text(entry.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
                .padding(.leading, 30)
        }
        .padding(.horizontal, DS.screenPadding)
        .padding(.vertical, 10)
    }
}

// MARK: - Harm Reduction Guide

struct HarmReductionGuideView: View {
    private func sectionHeader(_ title: String, color: Color = .secondary) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 4, height: 16)
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(color)
            Spacer()
        }
        .padding(.horizontal, DS.screenPadding)
        .padding(.top, 22)
        .padding(.bottom, 8)
    }

    private struct GuideSection {
        let title: String
        let color: Color
        let tips: [(icon: String, text: String)]
    }

    private let sections: [GuideSection] = [
        GuideSection(title: "Before Use", color: .blue, tips: [
            ("magnifyingglass", "Test your substances — reagent kits or drug checking services save lives"),
            ("scalemass.fill", "Always weigh your doses with a milligram scale. Never eyeball."),
            ("person.2.fill", "Never use alone. Have a sober sitter or tell someone what you're taking."),
            ("doc.text.fill", "Research the substance beforehand — onset, duration, dosage ranges, risks."),
            ("heart.text.clipboard.fill", "Check your medications for interactions. SSRIs, MAOIs, heart meds can be dangerous."),
            ("fork.knife", "Eat a light meal 2-3 hours before. Don't use on an empty stomach."),
        ]),
        GuideSection(title: "During Use", color: .green, tips: [
            ("drop.fill", "Stay hydrated but don't overdo it — max 250ml/hour for stimulants."),
            ("thermometer.medium", "Watch your temperature. Take breaks from dancing. Cool down regularly."),
            ("clock.fill", "Space your doses. Wait for the full onset before redosing. Redosing is the #1 cause of overdose."),
            ("arrow.down.circle.fill", "Start low. You can always take more, never less. First time? Take half."),
            ("nose.fill", "Nasal use: alternate nostrils, rinse with saline after. Use your own straw/tube."),
            ("eye.fill", "Monitor yourself and your friends. Check in with each other regularly."),
        ]),
        GuideSection(title: "After Use", color: .orange, tips: [
            ("moon.zzz.fill", "Sleep is the best medicine. Rest as much as your body needs."),
            ("fork.knife", "Eat nutritious food — fruits, vegetables, complex carbs. Your body needs fuel to recover."),
            ("figure.walk", "Light exercise after 1-2 days helps. Don't push yourself."),
            ("brain.head.profile.fill", "Mood dips are normal. Be kind to yourself. Talk to someone if it persists."),
            ("calendar", "Wait at least 3 months between MDMA uses. Tolerance rules exist for every substance."),
            ("phone.fill", "Seek medical help if: chest pain, extreme confusion, seizures, difficulty breathing, or unresponsiveness."),
        ]),
        GuideSection(title: "General Principles", color: Color.accent, tips: [
            ("shield.checkered", "Set & setting matter. Your mental state and environment affect your experience."),
            ("exclamationmark.triangle.fill", "Less is more. Lower doses = less risk. Heroic doses are not impressive, they're dangerous."),
            ("arrow.triangle.2.circlepath", "Build tolerance knowledge over time. Your response to substances changes."),
            ("hand.raised.fill", "Consent matters — for yourself and others. Never dose someone without their knowledge."),
            ("cross.fill", "Know the emergency number. In EU: 112. Have naloxone if using opioids."),
        ]),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                    sectionHeader(section.title, color: section.color)
                    ForEach(Array(section.tips.enumerated()), id: \.offset) { idx, tip in
                        if idx > 0 { Divider().padding(.leading, 54) }
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: tip.icon)
                                .foregroundStyle(section.color)
                                .font(.caption)
                                .frame(width: 22)
                                .padding(.top, 2)
                            Text(tip.text)
                                .font(.subheadline)
                                .lineSpacing(3)
                            Spacer()
                        }
                        .padding(.horizontal, DS.screenPadding)
                        .padding(.vertical, 8)
                    }
                }
            }
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
        .background(Color.appBackground)
        .navigationTitle("Harm Reduction")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Drug Checking Services

struct DrugCheckingView: View {
    private struct CheckingService: Identifiable {
        let id = UUID().uuidString
        let name: String
        let description: String
        let url: String
        let region: String
    }

    private let services: [CheckingService] = [
        CheckingService(name: "DrugsData.org", description: "International pill testing database. Submit or look up test results from Ecstasy, LSD, and other substances.", url: "https://drugsdata.org", region: "International"),
        CheckingService(name: "Saferparty.ch", description: "Swiss drug checking program. Free testing in Zurich and other Swiss cities. Publishes current warnings.", url: "https://saferparty.ch", region: "Switzerland"),
        CheckingService(name: "DIMS (Trimbos)", description: "Dutch drug information and monitoring system. Free testing at over 30 locations in the Netherlands.", url: "https://www.trimbos.nl/kennis/drugs/", region: "Netherlands"),
        CheckingService(name: "The Loop", description: "UK-based drug checking at festivals and events. Multi Substance Testing (MST) service.", url: "https://wearetheloop.org", region: "United Kingdom"),
        CheckingService(name: "Energy Control", description: "Spanish harm reduction organization offering anonymous drug checking by mail.", url: "https://energycontrol.org", region: "Spain / International"),
        CheckingService(name: "Miraculix Reagent Tests", description: "Reagent test kits you can use at home. Quick color-change tests for substance identification.", url: "https://miraculix-lab.de", region: "DIY / International"),
        CheckingService(name: "DanceSafe", description: "US-based harm reduction organization. Sells reagent test kits and provides drug checking at events.", url: "https://dancesafe.org", region: "United States"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Text("Testing your substances is one of the most important harm reduction steps. Never trust what you're told — verify.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, DS.screenPadding)
                    .padding(.vertical, 12)

                ForEach(services) { service in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 10) {
                            Image(systemName: "flask.fill")
                                .foregroundStyle(.purple)
                                .frame(width: 22)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(service.name)
                                    .font(.subheadline.bold())
                                Text(service.region)
                                    .font(.caption2)
                                    .foregroundStyle(Color.accent)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 1)
                                    .background(Color.accent.opacity(0.1), in: Capsule())
                            }
                            Spacer()
                        }
                        Text(service.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineSpacing(3)
                            .padding(.leading, 32)

                        Link(destination: URL(string: service.url)!) {
                            HStack(spacing: 4) {
                                Text("Open")
                                    .font(.caption.bold())
                                Image(systemName: "arrow.up.right")
                                    .font(.caption2)
                            }
                            .foregroundStyle(.purple)
                            .padding(.leading, 32)
                        }
                    }
                    .padding(.horizontal, DS.screenPadding)
                    .padding(.vertical, 10)

                    Divider().padding(.leading, 54)
                }
            }
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
        .background(Color.appBackground)
        .navigationTitle("Drug Checking")
        .navigationBarTitleDisplayMode(.inline)
    }
}
