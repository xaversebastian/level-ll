//
//  EmergencyView.swift
//  LevelEleven
//
//  Version: 1.0  |  2026-03-11
//
//  Notfall-Tab mit vier Bereichen:
//  1. Notruf-Button (lokalisiert: 911/999/000/112 per Locale)
//  2. Glasgow Coma Scale (GCS) Rechner (Eye/Verbal/Motor, Score 3–15)
//  3. Overdose-Checkliste (Recovery Position, Notruf, etc.)
//  4. Harm-Reduction-Tipps
//  GCS-Info-Sheet erklärt die Skala und substanzspezifische Hinweise.
//
//  HINWEIS: localEmergencyNumber() nutzt Locale.current.region – funktioniert offline.
//  Der Notruf-Link öffnet die Telefon-App (tel:-URL-Schema).

import SwiftUI

struct EmergencyView: View {
    @State private var eyeScore: Int = 4
    @State private var verbalScore: Int = 5
    @State private var motorScore: Int = 6
    @State private var showGCSInfo = false

    private var localEmergencyNumber: String {
        switch Locale.current.region?.identifier ?? "" {
        case "US", "CA", "MX": return "911"
        case "GB": return "999"
        case "AU", "NZ": return "000"
        default: return "112" // EU + international fallback
        }
    }
    
    private var gcsTotal: Int {
        eyeScore + verbalScore + motorScore
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    emergencyCallSection
                    gcsSection
                    checklistSection
                    tipsSection
                }
                .padding()
            }
            .navigationTitle("Emergency")
            .sheet(isPresented: $showGCSInfo) {
                gcsInfoSheet
            }
        }
    }
    
    // MARK: - Emergency Call Section
    
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
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Glasgow Coma Scale Section
    
    private var gcsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundStyle(Color.accent)
                Text("Glasgow Coma Scale")
                    .font(.headline)
                Spacer()
                Button {
                    showGCSInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                }
            }
            
            // Eye Response
            gcsComponent(
                title: "Eye Opening",
                score: $eyeScore,
                options: [
                    (4, "Spontaneous"),
                    (3, "To Voice"),
                    (2, "To Pain"),
                    (1, "None")
                ]
            )
            
            // Verbal Response
            gcsComponent(
                title: "Verbal Response",
                score: $verbalScore,
                options: [
                    (5, "Oriented"),
                    (4, "Confused"),
                    (3, "Words"),
                    (2, "Sounds"),
                    (1, "None")
                ]
            )
            
            // Motor Response
            gcsComponent(
                title: "Motor Response",
                score: $motorScore,
                options: [
                    (6, "Obeys Commands"),
                    (5, "Localizes Pain"),
                    (4, "Withdraws"),
                    (3, "Flexion"),
                    (2, "Extension"),
                    (1, "None")
                ]
            )
            
            Divider()
            
            // Total Score
            VStack(spacing: 8) {
                HStack {
                    Text("Total Score")
                        .font(.headline)
                    Spacer()
                    Text("\(gcsTotal)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(gcsColor)
                    Text("/ 15")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text(gcsSeverity)
                        .font(.subheadline.bold())
                        .foregroundStyle(gcsColor)
                    Spacer()
                }
                
                // Recommendation
                gcsRecommendation
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func gcsComponent(title: String, score: Binding<Int>, options: [(Int, String)]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(score.wrappedValue)")
                    .font(.title3.bold())
                    .foregroundStyle(Color.accent)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(options, id: \.0) { option in
                        Button {
                            score.wrappedValue = option.0
                        } label: {
                            VStack(spacing: 4) {
                                Text("\(option.0)")
                                    .font(.caption.bold())
                                Text(option.1)
                                    .font(.caption2)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .frame(minWidth: 70)
                            .background(score.wrappedValue == option.0 ? Color.accent : .secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(score.wrappedValue == option.0 ? .white : .primary)
                        }
                    }
                }
            }
        }
    }
    
    private var gcsColor: Color {
        switch gcsTotal {
        case 13...15: return .green
        case 9...12: return .orange
        case 3...8: return .red
        default: return .gray
        }
    }
    
    private var gcsSeverity: String {
        switch gcsTotal {
        case 13...15: return "Mild Impairment"
        case 9...12: return "Moderate Impairment"
        case 3...8: return "Severe Impairment"
        default: return "Unknown"
        }
    }
    
    private var gcsRecommendation: some View {
        VStack(alignment: .leading, spacing: 8) {
            if gcsTotal <= 8 {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text("Call emergency services NOW!")
                        .font(.subheadline.bold())
                        .foregroundStyle(.red)
                }
                Text("GCS ≤ 8: Unconsciousness, airway management required. Recovery position, monitor breathing.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if gcsTotal <= 12 {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.orange)
                    Text("Close Monitoring Required")
                        .font(.subheadline.bold())
                        .foregroundStyle(.orange)
                }
                Text("GCS 9-12: Call emergency if worsening. Do not leave the person alone, check on them regularly.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Normal Response")
                        .font(.subheadline.bold())
                        .foregroundStyle(.green)
                }
                Text("GCS 13-15: Person is responsive and oriented. Continue monitoring, no acute danger.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
                    Text("The Glasgow Coma Scale (GCS) is a standard method for assessing consciousness. It is used worldwide by emergency services and in hospitals.")
                        .font(.subheadline)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Score Meaning")
                            .font(.headline)
                        
                        scoreExplanation(range: "15", description: "Full Orientation", color: .green)
                        scoreExplanation(range: "13-14", description: "Mild Consciousness Disorder", color: .green)
                        scoreExplanation(range: "9-12", description: "Moderate Consciousness Disorder", color: .orange)
                        scoreExplanation(range: "6-8", description: "Severe Consciousness Disorder", color: .red)
                        scoreExplanation(range: "3-5", description: "Deep Unconsciousness/Coma", color: .red)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Important Notes")
                            .font(.headline)
                        
                        Text("• GCS ≤ 8 means coma - call \(localEmergencyNumber) immediately")
                        Text("• Substance intoxication can cause GCS to drop rapidly")
                        Text("• Opioid overdose: Naloxone can help")
                        Text("• GHB/Alcohol: Recovery position, monitor breathing")
                        Text("• Stimulants: Watch for seizures")
                    }
                    .font(.subheadline)
                }
                .padding()
            }
            .navigationTitle("GCS Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showGCSInfo = false
                    }
                }
            }
        }
    }
    
    private func scoreExplanation(range: String, description: String, color: Color) -> some View {
        HStack {
            Text(range)
                .font(.subheadline.bold())
                .foregroundStyle(color)
                .frame(width: 50, alignment: .leading)
            Text(description)
                .font(.subheadline)
            Spacer()
        }
    }
    
    // MARK: - Checklist Section
    
    private var checklistSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overdose Checklist")
                .font(.headline)
            
            checklistItem("Check responsiveness", icon: "hand.raised.fill")
            checklistItem("Call \(localEmergencyNumber) emergency", icon: "phone.fill")
            checklistItem("Recovery position", icon: "person.fill")
            checklistItem("Stay with the person", icon: "person.2.fill")
            checklistItem("Do not leave them alone", icon: "exclamationmark.triangle.fill")
            checklistItem("Inform emergency services", icon: "info.circle.fill")
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func checklistItem(_ text: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.orange)
                .frame(width: 30)
            Text(text)
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Tips Section
    
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Harm Reduction Tips")
                .font(.headline)
            
            tipItem("Stay hydrated, but don't overdrink")
            tipItem("Don't mix depressants (alcohol, opioids, GHB)")
            tipItem("Start low with new substances")
            tipItem("Test substances when possible")
            tipItem("Take breaks in cool areas")
            tipItem("Never use alone")
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func tipItem(_ text: String) -> some View {
        HStack(alignment: .top) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text(text)
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    EmergencyView()
}
