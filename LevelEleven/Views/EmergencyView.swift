//
//  EmergencyView.swift
//  LevelEleven
//
//  Version: 2.0  |  2026-03-12
//
//  Segmented Picker oben wechselt mit withAnimation zwischen den Modi.
//  "Help someone" behält GCS-Rechner und Overdose-Checkliste.
//
//  Updates v2.0:
//  - Redesigned to match HomeView design patterns
//  - Standardized padding with DS.screenPadding
//  - Added pressFeedback to interactive elements
//  - Consistent section header styling
//

import SwiftUI

private enum EmergencyMode: String, CaseIterable {
    case self_ = "I need help"
    case other = "Help someone"
}

struct EmergencyView: View {
    @State private var mode: EmergencyMode = .other
    @State private var eyeScore: Int = 4
    @State private var verbalScore: Int = 5
    @State private var motorScore: Int = 6
    @State private var showGCSInfo = false

    private var localEmergencyNumber: String {
        switch Locale.current.region?.identifier ?? "" {
        case "US", "CA", "MX": return "911"
        case "GB": return "999"
        case "AU", "NZ": return "000"
        default: return "112"
        }
    }

    private var gcsTotal: Int { eyeScore + verbalScore + motorScore }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Mode picker
                    Picker("Mode", selection: $mode.animation(.easeInOut)) {
                        ForEach(EmergencyMode.allCases, id: \.self) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, DS.screenPadding)
                    .padding(.top, 8)

                    if mode == .self_ {
                        selfHelpContent
                    } else {
                        helpOtherContent
                    }
                }
                .padding(.vertical, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Emergency")
            .sheet(isPresented: $showGCSInfo) { gcsInfoSheet }
        }
    }

    // MARK: - "I need help" (Calm / Grounding)

    private var selfHelpContent: some View {
        VStack(spacing: 16) {
            // Reassurance header
            VStack(spacing: 10) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Color.levelCalm)

                Text("You are safe.")
                    .font(.title.bold())
                    .foregroundStyle(Color.levelCalm)

                Text("What you're feeling is temporary.\nThe substance will pass through.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.levelCalm.opacity(0.08), in: RoundedRectangle(cornerRadius: DS.cardRadius))
            .padding(.horizontal, DS.screenPadding)

            // Breathing exercise
            breathingSection
                .padding(.horizontal, DS.screenPadding)

            // Grounding exercises
            groundingSection
                .padding(.horizontal, DS.screenPadding)

            // Soft contact / emergency (less prominent)
            softEmergencySection
                .padding(.horizontal, DS.screenPadding)
        }
    }

    private var breathingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Breathing Exercise", color: Color.levelCopper)

            VStack(spacing: 10) {
                breathingStep(number: "4", label: "Breathe in slowly", color: Color.levelCalm)
                breathingStep(number: "7", label: "Hold your breath", color: Color.levelCopper)
                breathingStep(number: "8", label: "Breathe out completely", color: Color.levelTeal)
            }

            Text("Repeat 3–4 times. This activates your parasympathetic nervous system.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.appBackground, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .shadow(color: DS.shadowColor, radius: DS.shadowRadius, y: DS.shadowY)
    }

    private func breathingStep(number: String, label: String, color: Color) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 42, height: 42)
                Text(number)
                    .font(.title3.bold())
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline.bold())
                Text("seconds")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var groundingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Grounding – 5-4-3-2-1", color: Color.levelCopper)

            groundingItem(count: "5", sense: "things you can see")
            groundingItem(count: "4", sense: "things you can touch")
            groundingItem(count: "3", sense: "things you can hear")
            groundingItem(count: "2", sense: "things you can smell")
            groundingItem(count: "1", sense: "thing you can taste")

            Text("Put your feet flat on the floor. Feel the ground beneath you.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
        .padding()
        .background(Color.appBackground, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .shadow(color: DS.shadowColor, radius: DS.shadowRadius, y: DS.shadowY)
    }

    private func groundingItem(count: String, sense: String) -> some View {
        HStack(spacing: 10) {
            Text(count)
                .font(.headline.bold())
                .foregroundStyle(Color.levelCopper)
                .frame(width: 24)
            Text(sense)
                .font(.subheadline)
            Spacer()
        }
    }

    private var softEmergencySection: some View {
        VStack(spacing: 12) {
            sectionHeader("Support Options", color: .secondary)

            // Call a friend
            Button {
                // Opens contacts
                if let url = URL(string: "tel:") { UIApplication.shared.open(url) }
            } label: {
                Label("Call someone you trust", systemImage: "phone.circle.fill")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.levelCalm.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(Color.levelCalm)
            }
            .buttonStyle(.plain)
            .pressFeedback()

            // Emergency (less prominent in self mode)
            Link(destination: URL(string: "tel:\(localEmergencyNumber)")!) {
                Label("Call Emergency (\(localEmergencyNumber))", systemImage: "cross.case.fill")
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.secondary)
            }
            .pressFeedback()
        }
        .padding()
        .background(Color.appBackground, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .shadow(color: DS.shadowColor, radius: DS.shadowRadius, y: DS.shadowY)
    }

    // MARK: - "Help someone" (Clinical / Direct)

    private var helpOtherContent: some View {
        VStack(spacing: 16) {
            emergencyCallSection
                .padding(.horizontal, DS.screenPadding)
            gcsSection
                .padding(.horizontal, DS.screenPadding)
            checklistSection
                .padding(.horizontal, DS.screenPadding)
            tipsSection
                .padding(.horizontal, DS.screenPadding)
        }
    }

    private var emergencyCallSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "cross.fill")
                .font(.system(size: 48))
                .foregroundStyle(.red)

            Text("In an emergency: Call \(localEmergencyNumber)")
                .font(.title2.bold())

            Link(destination: URL(string: "tel:\(localEmergencyNumber)")!) {
                HStack {
                    Image(systemName: "phone.fill")
                    Text("Call Emergency")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.red, in: RoundedRectangle(cornerRadius: 12))
            }
            .pressFeedback()
        }
        .padding()
        .background(Color.appBackground, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .shadow(color: DS.shadowColor, radius: DS.shadowRadius, y: DS.shadowY)
    }

    private var gcsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundStyle(Color.accent)
                Text("Glasgow Coma Scale")
                    .font(.headline)
                Spacer()
                Button { showGCSInfo = true } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                }
                .pressFeedback()
            }

            gcsComponent(title: "Eye Opening", score: $eyeScore,
                         options: [(4,"Spontaneous"),(3,"To Voice"),(2,"To Pain"),(1,"None")])
            gcsComponent(title: "Verbal Response", score: $verbalScore,
                         options: [(5,"Oriented"),(4,"Confused"),(3,"Words"),(2,"Sounds"),(1,"None")])
            gcsComponent(title: "Motor Response", score: $motorScore,
                         options: [(6,"Obeys"),(5,"Localizes"),(4,"Withdraws"),(3,"Flexion"),(2,"Extension"),(1,"None")])

            Divider()

            VStack(spacing: 8) {
                HStack {
                    Text("Total Score").font(.headline)
                    Spacer()
                    Text("\(gcsTotal)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(gcsColor)
                    Text("/ 15").font(.headline).foregroundStyle(.secondary)
                }
                HStack {
                    Text(gcsSeverity).font(.subheadline.bold()).foregroundStyle(gcsColor)
                    Spacer()
                }
                gcsRecommendation
            }
        }
        .padding()
        .background(Color.appBackground, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .shadow(color: DS.shadowColor, radius: DS.shadowRadius, y: DS.shadowY)
    }

    private func gcsComponent(title: String, score: Binding<Int>, options: [(Int, String)]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.subheadline.bold()).foregroundStyle(.secondary)
                Spacer()
                Text("\(score.wrappedValue)").font(.title3.bold()).foregroundStyle(Color.accent)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(options, id: \.0) { option in
                        Button { score.wrappedValue = option.0 } label: {
                            VStack(spacing: 4) {
                                Text("\(option.0)").font(.caption.bold())
                                Text(option.1).font(.caption2).lineLimit(2).multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 10).padding(.vertical, 8)
                            .frame(minWidth: 70)
                            .background(score.wrappedValue == option.0 ? Color.accent : .secondary.opacity(0.1),
                                        in: RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(score.wrappedValue == option.0 ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                        .pressFeedback()
                    }
                }
            }
        }
    }

    private var gcsColor: Color {
        switch gcsTotal {
        case 13...15: return .green
        case 9...12: return .orange
        default: return .red
        }
    }

    private var gcsSeverity: String {
        switch gcsTotal {
        case 13...15: return "Mild Impairment"
        case 9...12: return "Moderate Impairment"
        default: return "Severe Impairment"
        }
    }

    private var gcsRecommendation: some View {
        VStack(alignment: .leading, spacing: 8) {
            if gcsTotal <= 8 {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red)
                    Text("Call emergency services NOW!").font(.subheadline.bold()).foregroundStyle(.red)
                }
                Text("GCS ≤ 8: Unconsciousness – recovery position, monitor breathing.")
                    .font(.caption).foregroundStyle(.secondary)
            } else if gcsTotal <= 12 {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.orange)
                    Text("Close Monitoring Required").font(.subheadline.bold()).foregroundStyle(.orange)
                }
                Text("GCS 9-12: Call emergency if worsening. Don't leave them alone.")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Text("Normal Response").font(.subheadline.bold()).foregroundStyle(.green)
                }
                Text("GCS 13-15: Person is responsive. Continue monitoring.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(gcsColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
    }

    private var gcsInfoSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("The Glasgow Coma Scale (GCS) is a standard method for assessing consciousness used by emergency services worldwide.")
                        .font(.subheadline)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Score Meaning").font(.headline)
                        scoreExplanation(range: "15", description: "Full Orientation", color: .green)
                        scoreExplanation(range: "13-14", description: "Mild Consciousness Disorder", color: .green)
                        scoreExplanation(range: "9-12", description: "Moderate Consciousness Disorder", color: .orange)
                        scoreExplanation(range: "6-8", description: "Severe Consciousness Disorder", color: .red)
                        scoreExplanation(range: "3-5", description: "Deep Unconsciousness/Coma", color: .red)
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Important Notes").font(.headline)
                        Text("• GCS ≤ 8 means coma – call \(localEmergencyNumber) immediately").font(.subheadline)
                        Text("• Substance intoxication can cause GCS to drop rapidly").font(.subheadline)
                        Text("• Opioid overdose: Naloxone can help").font(.subheadline)
                        Text("• GHB/Alcohol: Recovery position, monitor breathing").font(.subheadline)
                        Text("• Stimulants: Watch for seizures").font(.subheadline)
                    }
                }
                .padding()
            }
            .navigationTitle("GCS Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showGCSInfo = false }
                }
            }
        }
    }

    // MARK: - Section Header

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
        .padding(.bottom, 8)
    }

    private func scoreExplanation(range: String, description: String, color: Color) -> some View {
        HStack {
            Text(range).font(.subheadline.bold()).foregroundStyle(color).frame(width: 50, alignment: .leading)
            Text(description).font(.subheadline)
            Spacer()
        }
    }

    private var checklistSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Overdose Checklist", color: .orange)
            checklistItem("Check responsiveness", icon: "hand.raised.fill")
            checklistItem("Call \(localEmergencyNumber) emergency", icon: "phone.fill")
            checklistItem("Recovery position (on their side)", icon: "person.fill")
            checklistItem("Stay with the person", icon: "person.2.fill")
            checklistItem("Do not leave them alone", icon: "exclamationmark.triangle.fill")
            checklistItem("Inform emergency services what was taken", icon: "info.circle.fill")
        }
        .padding()
        .background(Color.appBackground, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .shadow(color: DS.shadowColor, radius: DS.shadowRadius, y: DS.shadowY)
    }

    private func checklistItem(_ text: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(.orange).frame(width: 30)
            Text(text)
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Harm Reduction Tips", color: Color.levelCalm)
            tipItem("Stay hydrated, but don't overdrink")
            tipItem("Don't mix depressants (alcohol, opioids, GHB)")
            tipItem("Start low with new substances")
            tipItem("Test substances when possible")
            tipItem("Take breaks in cool areas")
            tipItem("Never use alone")
        }
        .padding()
        .background(Color.appBackground, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .shadow(color: DS.shadowColor, radius: DS.shadowRadius, y: DS.shadowY)
    }

    private func tipItem(_ text: String) -> some View {
        HStack(alignment: .top) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            Text(text)
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    EmergencyView()
}
