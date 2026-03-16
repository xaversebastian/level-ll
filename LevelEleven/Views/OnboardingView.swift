// OnboardingView.swift — LevelEleven
// v3.0 | 2026-03-12 17:18
// - Complete rewrite: multi-phase onboarding (walkthrough → profile → assessment)
// - Detailed feature walkthrough with app capability highlights
// - Profile creation via guided questions (name, avatar, physiology)
// - Pro-level experience assessment to gauge user familiarity
// - Stripped legacy comments, added structured header
//

import SwiftUI

// MARK: - Onboarding Phase

private enum OnboardingPhase: Int, CaseIterable {
    case disclaimer = 0
    case welcome = 1
    case featureTracking = 2
    case featureGroup = 3
    case featureSafety = 4
    case featureCare = 5
    case profileBasic = 6
    case profilePhysiology = 7
    case profileHealth = 8
    case profileMedications = 9
    case toleranceAssessment = 10
    case experienceAssessment = 11
    case ready = 12

    var totalCount: Int { Self.allCases.count }

    var isWalkthrough: Bool { rawValue >= 1 && rawValue <= 5 }
    var isProfileCreation: Bool { rawValue >= 6 && rawValue <= 10 }
}

struct OnboardingView: View {
    var isReviewMode: Bool = false

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var phase: OnboardingPhase = .disclaimer

    private var skippedPhases: Set<OnboardingPhase> {
        isReviewMode
            ? [.profileBasic, .profilePhysiology, .profileHealth, .profileMedications]
            : []
    }

    private var visiblePhases: [OnboardingPhase] {
        OnboardingPhase.allCases.filter { !skippedPhases.contains($0) }
    }

    // Profile creation state
    @State private var profileName = ""
    @State private var avatarEmoji = "😎"
    @State private var age = 25
    @State private var weightKg = 70.0
    @State private var sex: BiologicalSex = .male
    @State private var isNeurodivergent = false
    @State private var takeSSRI = false
    @State private var personalLimit = 7
    @State private var selectedMedications: Set<String> = []
    @State private var toleranceLevels: [String: Int] = [:]

    // Pro-level assessment state
    @State private var yearsExperience = 0
    @State private var substancesBreadth = 0
    @State private var harmReductionKnowledge = 0
    @State private var frequencyScore = 0

    // Avatar picker
    @State private var showEmojiPicker = false

    private let avatarOptions = [
        "😎", "🥰", "😊", "🤓", "🥳", "😏",
        "🤠", "🥸", "😇", "🤩", "😌", "😈",
        "🔥", "💜", "⚡️", "🌈", "🍀", "🎯",
        "🦄", "🐺", "🦊", "👑", "🎵", "🤝"
    ]

    private var computedProLevel: Int {
        let raw = yearsExperience + substancesBreadth + harmReductionKnowledge + frequencyScore
        switch raw {
        case 0...2:  return 1
        case 3...5:  return 2
        case 6...8:  return 3
        case 9...11: return 4
        default:     return 5
        }
    }

    private var canAdvance: Bool {
        switch phase {
        case .profileBasic:
            return !profileName.trimmingCharacters(in: .whitespaces).isEmpty
        default:
            return true
        }
    }

    var body: some View {
        ZStack {
            Color.heroBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                progressBar
                    .padding(.horizontal, DS.screenPadding)
                    .padding(.top, 14)

                ScrollView(showsIndicators: false) {
                    phaseContent
                        .padding(.horizontal, DS.screenPadding)
                }

                bottomControls
            }
        }
        .foregroundStyle(.white)
        .sheet(isPresented: $showEmojiPicker) { emojiPickerSheet }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Text("level ll")
                .font(.system(size: 11, weight: .black))
                .tracking(3)
                .foregroundStyle(.white.opacity(0.3))
            Spacer()
            if phase.isWalkthrough {
                Text("WALKTHROUGH")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.2))
            } else if phase.isProfileCreation {
                Text("PROFILE SETUP")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.2))
            } else if phase == .experienceAssessment {
                Text("ASSESSMENT")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.2))
            } else if phase == .featureCare {
                Text("CARE & RECOVERY")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.2))
            }
            Spacer()
            let currentIdx = (visiblePhases.firstIndex(of: phase) ?? 0) + 1
            Text("\(currentIdx) / \(visiblePhases.count)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(.horizontal, DS.screenPadding)
        .padding(.top, 16)
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        HStack(spacing: 4) {
            ForEach(Array(visiblePhases.enumerated()), id: \.element) { idx, p in
                Capsule()
                    .fill(p.rawValue <= phase.rawValue ? barColor(p.rawValue) : Color.white.opacity(0.08))
                    .frame(maxWidth: .infinity)
                    .frame(height: 4)
                    .animation(.easeInOut(duration: 0.25), value: phase)
            }
        }
    }

    private func barColor(_ i: Int) -> Color {
        switch i {
        case 0: return .levelCopper
        case 1: return .levelTeal
        case 2: return .levelOrange
        case 3: return .red.opacity(0.8)
        case 4: return .orange
        case 5...7: return .levelCopper
        case 8: return .levelAmber       // medications
        case 9: return .levelOrange       // tolerance
        case 10: return .levelTeal        // assessment
        case 11: return .levelGreen       // care
        default: return .levelGreen
        }
    }

    // MARK: - Phase Content

    @ViewBuilder
    private var phaseContent: some View {
        switch phase {
        case .welcome:              welcomePage
        case .featureTracking:      featureTrackingPage
        case .featureGroup:         featureGroupPage
        case .featureSafety:        featureSafetyPage
        case .disclaimer:           disclaimerPage
        case .profileBasic:         profileBasicPage
        case .profilePhysiology:    profilePhysiologyPage
        case .profileHealth:        profileHealthPage
        case .profileMedications:   profileMedicationsPage
        case .toleranceAssessment:  toleranceAssessmentPage
        case .experienceAssessment: assessmentPage
        case .featureCare:          featureCarePage
        case .ready:                readyPage
        }
    }

    // MARK: - Walkthrough Pages

    private var welcomePage: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 50)
            iconCircle("waveform.path.ecg", color: .levelCopper)
            Text("level ll")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .padding(.bottom, 12)
            Text("Real-time intoxication tracking.\nHarm reduction, not judgement.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.6))
                .lineSpacing(4)
            featurePill("Pharmacokinetic dose modeling", icon: "function")
            featurePill("Personalized recommendations", icon: "person.badge.shield.checkmark")
            featurePill("Group session tracking", icon: "person.3.fill")
            featurePill("Emergency tools & GCS", icon: "cross.fill")
            Spacer(minLength: 120)
        }
    }

    private var featureTrackingPage: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 40)
            iconCircle("chart.line.uptrend.xyaxis", color: .levelTeal)
            Text("Real-Time Tracking")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .padding(.bottom, 12)
            Text("Your level is calculated from active doses using pharmacokinetic models.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.6))
                .lineSpacing(4)
                .padding(.bottom, 20)
            detailCard([
                ("gauge.with.needle.fill", "Level 0–11 scale from sober to maximum"),
                ("clock.arrow.circlepath", "Doses decay based on substance half-life"),
                ("chart.xyaxis.line", "Timeline shows past + predicted future levels"),
                ("bell.badge.fill", "Warnings when approaching personal limit")
            ])
            Spacer(minLength: 120)
        }
    }

    private var featureGroupPage: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 40)
            iconCircle("person.3.fill", color: .levelOrange)
            Text("Group Sessions")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .padding(.bottom, 12)
            Text("Track everyone in your group.\nLog doses per person, see real-time levels.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.6))
                .lineSpacing(4)
                .padding(.bottom, 20)
            detailCard([
                ("person.badge.plus", "Add/remove participants on the fly"),
                ("chart.bar.fill", "Session statistics & level history"),
                ("clock.badge.checkmark", "Session history with full dose timeline"),
                ("iphone.badge.play", "Lock Screen & Dynamic Island live activity")
            ])
            Spacer(minLength: 120)
        }
    }

    private var featureSafetyPage: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 40)
            iconCircle("cross.fill", color: .red.opacity(0.8))
            Text("Safety & Emergency")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .padding(.bottom, 12)
            Text("Built-in tools for when things go wrong.\nGrounding, GCS scoring, overdose protocols.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.6))
                .lineSpacing(4)
                .padding(.bottom, 20)
            detailCard([
                ("heart.circle.fill", "Calming breathing exercises & grounding"),
                ("brain.head.profile", "Glasgow Coma Scale consciousness check"),
                ("exclamationmark.triangle.fill", "Interaction warnings between substances"),
                ("pills.fill", "Nasal dosing guide with visual line sizing")
            ])
            Spacer(minLength: 120)
        }
    }

    private var disclaimerPage: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 40)
            iconCircle("shield.fill", color: .orange)
            Text("Important")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .padding(.bottom, 12)
            Text("Please read before using this app.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.6))
                .padding(.bottom, 20)

            VStack(alignment: .leading, spacing: 12) {
                Text("EN: This app is for harm reduction and educational purposes only. It does not constitute medical advice. All dosage amounts refer to pure active substance — actual substances are rarely pure. Possession and use of controlled substances may be illegal in your country. The developers accept no liability for harm resulting from use of this app.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.45))
                    .lineSpacing(3)

                Divider().background(.white.opacity(0.1))

                Text("DE: Diese App dient ausschließlich zur Schadensminimierung und zu Bildungszwecken. Sie ersetzt keine medizinische Beratung. Alle Mengenangaben beziehen sich auf reinen Wirkstoff. Besitz und Konsum können strafbar sein. Die Entwickler übernehmen keine Haftung.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.45))
                    .lineSpacing(3)
            }
            .padding(16)
            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
            Spacer(minLength: 120)
        }
    }

    // MARK: - Profile Creation Pages

    private var profileBasicPage: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 30)
            Text("Create Your Profile")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .padding(.bottom, 6)
            Text("This personalizes dose recommendations.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
                .padding(.bottom, 28)

            // Avatar
            Button { showEmojiPicker = true } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 90, height: 90)
                    Text(avatarEmoji)
                        .font(.system(size: 48))
                    Circle()
                        .stroke(Color.accent, lineWidth: 2)
                        .frame(width: 90, height: 90)
                    Image(systemName: "pencil.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.accent)
                        .background(Circle().fill(Color.heroBackground))
                        .offset(x: 32, y: 32)
                }
            }
            .padding(.bottom, 24)

            // Name
            VStack(alignment: .leading, spacing: 8) {
                Text("NAME")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.4))
                TextField("Your name", text: $profileName)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .padding(14)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                    .tint(Color.accent)
            }

            Spacer(minLength: 120)
        }
    }

    private var profilePhysiologyPage: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 30)
            Text("Physiology")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .padding(.bottom, 6)
            Text("Used for metabolism and dose calculations.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
                .padding(.bottom, 28)

            VStack(spacing: 20) {
                // Age
                onboardingSlider(title: "AGE", value: "\(age) years",
                                 binding: Binding(get: { Double(age) }, set: { age = Int($0) }),
                                 range: 16...80)
                // Weight
                onboardingSlider(title: "WEIGHT", value: "\(Int(weightKg)) kg",
                                 binding: $weightKg,
                                 range: 40...150)
                // Sex
                VStack(alignment: .leading, spacing: 8) {
                    Text("BIOLOGICAL SEX")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.4))
                    Picker("Sex", selection: $sex) {
                        ForEach(BiologicalSex.allCases, id: \.self) { s in
                            Text(s.displayName).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }

            Spacer(minLength: 120)
        }
    }

    private var profileHealthPage: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 30)
            Text("Health Info")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .padding(.bottom, 6)
            Text("Adjusts recommendations for your needs.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
                .padding(.bottom, 28)

            VStack(spacing: 16) {
                onboardingToggle(
                    "Neurodivergent",
                    subtitle: "ADHD, ASD, etc. — affects stimulant response",
                    icon: "brain",
                    isOn: $isNeurodivergent
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("PERSONAL LIMIT")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.4))
                    HStack {
                        Text("Level \(personalLimit)")
                            .font(.title3.bold())
                            .foregroundStyle(Color.accent)
                        Spacer()
                    }
                    Slider(value: Binding(get: { Double(personalLimit) }, set: { personalLimit = Int($0) }),
                           in: 3...11, step: 1)
                    .tint(Color.accent)
                    Text("You'll be warned when approaching this level.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.35))
                }
                .padding(14)
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
            }

            Spacer(minLength: 120)
        }
    }

    // MARK: - Medications Page

    private var profileMedicationsPage: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 20)
            Text("Medications")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .padding(.bottom, 6)
            Text("Select medications you take regularly.\nThis enables critical interaction warnings.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.5))
                .padding(.bottom, 20)

            VStack(spacing: 12) {
                ForEach(MedicationCategory.allCases, id: \.self) { category in
                    let meds = MedicationData.medications(for: category)
                    if !meds.isEmpty {
                        medicationCategorySection(category: category, medications: meds)
                    }
                }
            }

            if selectedMedications.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green.opacity(0.6))
                    Text("No medications — skip to continue")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.top, 16)
            }

            Spacer(minLength: 120)
        }
    }

    @State private var expandedMedCategory: MedicationCategory?

    private func medicationCategorySection(category: MedicationCategory, medications: [MedicationEntry]) -> some View {
        let selectedInCategory = medications.filter { selectedMedications.contains($0.id) }.count
        let isExpanded = expandedMedCategory == category

        return VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedMedCategory = isExpanded ? nil : category
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: category.icon)
                        .font(.subheadline)
                        .foregroundStyle(Color.accent)
                        .frame(width: 24)
                    Text(category.displayName)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                    Spacer()
                    if selectedInCategory > 0 {
                        Text("\(selectedInCategory)")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.accent, in: Capsule())
                    }
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.3))
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(medications, id: \.id) { med in
                        Divider().background(Color.white.opacity(0.06)).padding(.leading, 50)
                        Button {
                            if selectedMedications.contains(med.id) {
                                selectedMedications.remove(med.id)
                            } else {
                                selectedMedications.insert(med.id)
                                // Auto-set takeSSRI flag for backward compat
                                if MedicationData.serotonergicMedIds.contains(med.id) {
                                    takeSSRI = true
                                }
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: selectedMedications.contains(med.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedMedications.contains(med.id) ? Color.accent : .white.opacity(0.2))
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(med.name)
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                    if let info = med.interactionInfo {
                                        Text(info)
                                            .font(.caption2)
                                            .foregroundStyle(.white.opacity(0.35))
                                            .lineLimit(2)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Tolerance Assessment Page

    private var toleranceAssessmentPage: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 20)
            Text("Your Tolerance")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .padding(.bottom, 6)
            Text("Estimate your current tolerance.\n3 = neutral (no tolerance). Adjust only substances you use.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.5))
                .padding(.bottom, 20)

            VStack(spacing: 0) {
                ForEach(Array(Substances.all.enumerated()), id: \.element.id) { idx, substance in
                    if idx > 0 { Divider().background(Color.white.opacity(0.06)).padding(.leading, 50) }

                    let level = toleranceLevels[substance.id] ?? 3

                    HStack(spacing: 10) {
                        Image(systemName: substance.category.icon)
                            .foregroundStyle(Color(hex: substance.category.color))
                            .frame(width: 22)

                        Text(substance.shortName)
                            .font(.subheadline)
                            .frame(minWidth: 60, alignment: .leading)

                        Spacer()

                        Text(toleranceLabel(level))
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.4))
                            .frame(width: 52, alignment: .trailing)

                        Stepper(
                            "\(level)",
                            value: Binding(
                                get: { toleranceLevels[substance.id] ?? 3 },
                                set: { toleranceLevels[substance.id] = $0 }
                            ),
                            in: 0...11
                        )
                        .fixedSize()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                }
            }
            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.3))
                Text("The app also tracks a computed tolerance from your usage. The final value blends both.")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(.top, 12)

            Spacer(minLength: 120)
        }
    }

    private func toleranceLabel(_ level: Int) -> String {
        switch level {
        case 0:    return "None"
        case 1...2: return "Low"
        case 3:    return "Neutral"
        case 4...5: return "Medium"
        case 6...7: return "High"
        case 8...9: return "Very High"
        case 10...11: return "Max"
        default:   return ""
        }
    }

    // MARK: - Care & Recovery Explanation

    private var featureCarePage: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 40)
            iconCircle("heart.text.clipboard.fill", color: .levelGreen)
            Text("Care & Recovery")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .padding(.bottom, 12)
            Text("Your companion before, during, and after a session.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.6))
                .lineSpacing(4)
                .padding(.bottom, 20)

            detailCard([
                ("leaf.fill", "Normalization tips if effects get too strong"),
                ("clock.badge.checkmark.fill", "Timed aftercare hints for recovery"),
                ("chart.bar.doc.horizontal.fill", "Wellbeing tracking scores your experience"),
                ("exclamationmark.triangle.fill", "Combination warnings for mixed substances"),
                ("bell.badge.fill", "Check-in reminders to monitor your state")
            ])

            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.orange.opacity(0.5))
                Text("Premium tips include substance-specific normalization techniques.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.top, 16)

            Spacer(minLength: 120)
        }
    }

    // MARK: - Experience Assessment

    private var assessmentPage: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 30)
            Text("Experience Level")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .padding(.bottom, 6)
            Text("Helps us tailor safety prompts and defaults.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
                .padding(.bottom, 24)

            VStack(spacing: 16) {
                assessmentQuestion(
                    "How long have you used substances?",
                    options: ["Never", "< 1 year", "1–3 years", "3+ years"],
                    selection: $yearsExperience
                )
                assessmentQuestion(
                    "How many different substances have you tried?",
                    options: ["None", "1–2", "3–5", "6+"],
                    selection: $substancesBreadth
                )
                assessmentQuestion(
                    "Harm reduction knowledge?",
                    options: ["None", "Basic", "Good", "Expert"],
                    selection: $harmReductionKnowledge
                )
                assessmentQuestion(
                    "How often do you use?",
                    options: ["Never", "A few times/year", "Monthly", "Weekly+"],
                    selection: $frequencyScore
                )
            }

            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.3))
                Text("This stays on your device and is never shared.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(.top, 16)

            Spacer(minLength: 120)
        }
    }

    // MARK: - Ready Page

    private var readyPage: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 50)
            iconCircle("checkmark.shield.fill", color: .levelGreen)
            Text("You're All Set")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .padding(.bottom, 12)

            if !isReviewMode {
                Text("Welcome, \(profileName.trimmingCharacters(in: .whitespaces).isEmpty ? "User" : profileName)")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.bottom, 8)
            }

            Text(isReviewMode ? "Updated: \(proLevelLabel)" : "Experience: \(proLevelLabel)")
                .font(.subheadline.bold())
                .foregroundStyle(Color.accent)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.accent.opacity(0.15), in: Capsule())
                .padding(.bottom, 24)

            VStack(alignment: .leading, spacing: 10) {
                readyItem("Your profile is saved — edit anytime in Profiles", icon: "person.crop.circle.badge.checkmark")
                readyItem("Tolerances adjust automatically with use", icon: "arrow.triangle.2.circlepath")
                readyItem("Check the SOS tab if you ever need help", icon: "cross.fill")
            }

            Spacer(minLength: 120)
        }
    }

    private var proLevelLabel: String {
        switch computedProLevel {
        case 1: return "Beginner"
        case 2: return "Casual"
        case 3: return "Intermediate"
        case 4: return "Experienced"
        case 5: return "Very Experienced"
        default: return "Unknown"
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 14) {
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                if phase == .ready {
                    finishOnboarding()
                } else {
                    advance()
                }
            } label: {
                Text(buttonLabel)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        canAdvance ? Color.accent.gradient : Color.secondary.opacity(0.3).gradient,
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                    .foregroundStyle(.white)
                    .shadow(color: canAdvance ? Color.accent.opacity(0.2) : .clear, radius: 8, y: 3)
            }
            .disabled(!canAdvance)

            if phase.isWalkthrough && phase != .disclaimer {
                Button { skipToProfile() } label: {
                    Text("Skip to Profile Setup")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
        }
        .padding(.horizontal, DS.screenPadding)
        .padding(.bottom, 40)
    }

    private var buttonLabel: String {
        switch phase {
        case .ready: return isReviewMode ? "Done" : "Get Started"
        case .featureCare: return "Almost Done"
        case .profileBasic, .profilePhysiology, .profileHealth,
             .profileMedications, .toleranceAssessment, .experienceAssessment: return "Next"
        default: return "Continue"
        }
    }

    // MARK: - Navigation

    private func advance() {
        var nextRaw = phase.rawValue + 1
        while let candidate = OnboardingPhase(rawValue: nextRaw), skippedPhases.contains(candidate) {
            nextRaw += 1
        }
        guard let next = OnboardingPhase(rawValue: nextRaw) else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            phase = next
        }
    }

    private func skipToProfile() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            phase = .profileBasic
        }
    }

    private func finishOnboarding() {
        if isReviewMode {
            // In review mode, only update tolerances and pro level on existing profile
            if var profile = appState.activeProfile,
               let idx = appState.profiles.firstIndex(where: { $0.id == profile.id }) {
                // Update tolerances from review
                for (substanceId, level) in toleranceLevels {
                    if let tIdx = profile.tolerances.firstIndex(where: { $0.substanceId == substanceId }) {
                        profile.tolerances[tIdx] = Tolerance(substanceId: substanceId, level: level)
                    } else {
                        profile.tolerances.append(Tolerance(substanceId: substanceId, level: level))
                    }
                }
                profile.proLevel = computedProLevel
                appState.profiles[idx] = profile
            }
            dismiss()
            return
        }

        // Build medications from selection
        let medications = selectedMedications.compactMap { MedicationData.byId[$0] }

        // Build tolerances from assessment (subjective = user input, computed starts at same value)
        let tolerances = toleranceLevels.map { substanceId, level in
            Tolerance(substanceId: substanceId, level: level)
        }

        let newProfile = Profile(
            name: profileName.trimmingCharacters(in: .whitespaces),
            isActive: true,
            isPrimaryUser: true,
            avatarEmoji: avatarEmoji,
            age: age,
            weightKg: weightKg,
            sex: sex,
            isNeurodivergent: isNeurodivergent,
            takeSSRI: takeSSRI,
            medications: medications,
            proLevel: computedProLevel,
            tolerances: tolerances,
            personalLimit: personalLimit
        )

        // Replace default profiles with the user-created one
        if appState.profiles.isEmpty || appState.profiles.allSatisfy({ $0.name == "Xaver" || $0.name == "Silja" }) {
            appState.profiles = [newProfile]
            appState.activeProfileId = newProfile.id
        } else {
            appState.addProfile(newProfile)
            appState.setActiveProfile(newProfile)
        }

        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        dismiss()
    }

    // MARK: - Reusable Components

    private func iconCircle(_ systemName: String, color: Color) -> some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.12))
                .frame(width: 100, height: 100)
            Image(systemName: systemName)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(color)
        }
        .padding(.bottom, 32)
    }

    private func featurePill(_ text: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.accent)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
        .padding(.top, 8)
    }

    private func detailCard(_ items: [(icon: String, text: String)]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                if idx > 0 {
                    Divider().background(Color.white.opacity(0.06)).padding(.leading, 36)
                }
                HStack(spacing: 12) {
                    Image(systemName: item.icon)
                        .font(.caption)
                        .foregroundStyle(Color.accent)
                        .frame(width: 20)
                    Text(item.text)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                    Spacer()
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
            }
        }
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
    }

    private func onboardingSlider(title: String, value: String, binding: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.4))
                Spacer()
                Text(value)
                    .font(.title3.bold())
                    .foregroundStyle(Color.accent)
            }
            Slider(value: binding, in: range, step: 1)
                .tint(Color.accent)
        }
        .padding(14)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }

    private func onboardingToggle(_ title: String, subtitle: String, icon: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accent)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }
            Spacer()
            Toggle("", isOn: isOn)
                .tint(Color.accent)
                .labelsHidden()
        }
        .padding(14)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }

    private func assessmentQuestion(_ question: String, options: [String], selection: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(question)
                .font(.subheadline.bold())
                .foregroundStyle(.white.opacity(0.8))

            HStack(spacing: 6) {
                ForEach(0..<options.count, id: \.self) { i in
                    Button {
                        selection.wrappedValue = i
                    } label: {
                        Text(options[i])
                            .font(.caption.bold())
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(
                                selection.wrappedValue == i
                                    ? Color.accent
                                    : Color.white.opacity(0.08),
                                in: RoundedRectangle(cornerRadius: 8)
                            )
                            .foregroundStyle(selection.wrappedValue == i ? .white : .white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
    }

    private func readyItem(_ text: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(Color.levelGreen)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Emoji Picker

    private var emojiPickerSheet: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 12) {
                    ForEach(avatarOptions, id: \.self) { emoji in
                        Button {
                            avatarEmoji = emoji
                            showEmojiPicker = false
                        } label: {
                            Text(emoji)
                                .font(.system(size: 32))
                                .frame(width: 48, height: 48)
                                .background(
                                    avatarEmoji == emoji
                                        ? Color.accent.opacity(0.15)
                                        : Color.clear,
                                    in: RoundedRectangle(cornerRadius: 10)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .background(Color.appBackground)
            .navigationTitle("Choose Avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showEmojiPicker = false }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    OnboardingView()
        .environment(AppState())
}
