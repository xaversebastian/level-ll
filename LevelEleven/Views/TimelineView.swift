//
//  TimelineView.swift
//  LevelEleven
//
//  Version: 1.0  |  2026-03-11
//
//  Level-über-Zeit-Chart für das aktive Profil (Swift Charts).
//  Zeigt Vergangenheit + Zukunft (Prognose) in den Zeitfenstern 3h/6h/12h/24h.
//  AreaMark + LineMark kombiniert für Flächen-Look mit Linie.
//  Zeigt aktive Substanzen-Liste und Nüchternheits-Schätzung darunter.
//  TimeRange-Enum konfiguriert Past- und Future-Minuten pro Fenster.
//
//  HINWEIS: generateTimelineData() sampelt alle 5 Minuten – bei breiterem Fenster
//  ggf. Schritt erhöhen. Wird aus HomeView-Sheet und MoreView-NavigationLink aufgerufen.
//

import SwiftUI
import Charts

struct TimelinePoint: Identifiable {
    let id = UUID()
    let minutesFromNow: Double
    let level: Double
    let substanceId: String?
}

struct TimelineView: View {
    @Environment(AppState.self) private var appState
    @State private var timeRange: TimeRange = .hours6
    
    enum TimeRange: String, CaseIterable {
        case hours3 = "3h"
        case hours6 = "6h"
        case hours12 = "12h"
        case hours24 = "24h"
        
        var pastMinutes: Double {
            switch self {
            case .hours3: return 120
            case .hours6: return 240
            case .hours12: return 480
            case .hours24: return 960
            }
        }
        
        var futureMinutes: Double {
            switch self {
            case .hours3: return 60
            case .hours6: return 120
            case .hours12: return 240
            case .hours24: return 480
            }
        }
    }
    
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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Time range picker
                    Picker("Time Range", selection: $timeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, DS.screenPadding)
                    .padding(.top, 12)

                    // Chart
                    sectionHeader("Level Over Time", color: Color.accent)
                    levelChart

                    if let profile = appState.activeProfile {
                        activeSubstancesSection(profile)
                        sobrietyEstimate(profile)
                    }
                }
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Timeline")
        }
    }
    
    private var levelChart: some View {
        let data = generateTimelineData()
        
        return VStack(alignment: .leading, spacing: 12) {
            Chart(data) { point in
                AreaMark(
                    x: .value("Time", point.minutesFromNow),
                    y: .value("Level", point.level)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.accent.opacity(0.6), Color.accent.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                LineMark(
                    x: .value("Time", point.minutesFromNow),
                    y: .value("Level", point.level)
                )
                .foregroundStyle(Color.accent)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }
            .chartXScale(domain: -timeRange.pastMinutes...timeRange.futureMinutes)
            .chartYScale(domain: 0...11)
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let mins = value.as(Double.self) {
                            Text(formatAxisTime(mins))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(values: [0, 3, 6, 9, 11])
            }
            .frame(height: 200)
            
            HStack {
                Circle()
                    .fill(Color.accent)
                    .frame(width: 8, height: 8)
                Text("Now")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Future →")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, DS.screenPadding)
    }
    
    private func activeSubstancesSection(_ profile: Profile) -> some View {
        let active = appState.activeDoses(for: profile.id)
        let substanceIds = Set(active.map { $0.substanceId })
        
        return VStack(spacing: 0) {
            sectionHeader("Active Substances", color: Color.accent)
            
            if substanceIds.isEmpty {
                HStack(spacing: 14) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .frame(width: 22)
                    Text("No active substances")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, DS.screenPadding)
                .padding(.vertical, 10)
            } else {
                ForEach(Array(substanceIds.enumerated()), id: \.element) { idx, id in
                    if let substance = Substances.byId[id] {
                        if idx > 0 { Divider().padding(.leading, 54) }
                        HStack(spacing: 14) {
                            Image(systemName: substance.category.icon)
                                .foregroundStyle(Color(hex: substance.category.color))
                                .frame(width: 22)
                            
                            Text(substance.name)
                                .font(.subheadline)
                            
                            Spacer()
                            
                            let doses = active.filter { $0.substanceId == id }
                            Text("\(doses.count) dose\(doses.count > 1 ? "s" : "")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, DS.screenPadding)
                        .padding(.vertical, 10)
                    }
                }
            }
        }
    }
    
    private func sobrietyEstimate(_ profile: Profile) -> some View {
        let active = appState.activeDoses(for: profile.id)
        
        var maxEndTime: Double = 0
        for dose in active {
            if let substance = Substances.byId[dose.substanceId] {
                let minutesSinceDose = dose.minutesAgo()
                let remaining = substance.durationMinutes - minutesSinceDose
                if remaining > maxEndTime {
                    maxEndTime = remaining
                }
            }
        }
        
        return VStack(spacing: 0) {
            sectionHeader("Sobriety Estimate", color: .secondary)
            
            HStack(spacing: 14) {
                if maxEndTime <= 0 {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .frame(width: 22)
                    Text("You should be sober now")
                        .font(.subheadline)
                } else {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(.orange)
                        .frame(width: 22)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        let hours = Int(maxEndTime) / 60
                        let mins = Int(maxEndTime) % 60
                        
                        if hours > 0 {
                            Text("~\(hours)h \(mins)m until baseline")
                                .font(.subheadline.bold())
                        } else {
                            Text("~\(mins) minutes until baseline")
                                .font(.subheadline.bold())
                        }
                        
                        Text("This is an estimate. Individual responses vary.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, DS.screenPadding)
            .padding(.vertical, 10)
        }
    }
    
    private func generateTimelineData() -> [TimelinePoint] {
        guard let profile = appState.activeProfile else {
            return [TimelinePoint(minutesFromNow: 0, level: 0, substanceId: nil)]
        }
        
        var points: [TimelinePoint] = []
        let step: Double = 5
        
        // Past to future (extended future to show peak prediction)
        var t = -timeRange.pastMinutes
        while t <= timeRange.futureMinutes {
            let date = Date().addingTimeInterval(t * 60)
            let level = appState.currentLevel(for: profile, at: date)
            points.append(TimelinePoint(minutesFromNow: t, level: level, substanceId: nil))
            t += step
        }
        
        return points
    }
    
    private func formatAxisTime(_ minutes: Double) -> String {
        if minutes == 0 { return "Now" }
        let absMinutes = abs(Int(minutes))
        if absMinutes >= 60 {
            let h = absMinutes / 60
            return minutes < 0 ? "-\(h)h" : "+\(h)h"
        }
        return minutes < 0 ? "-\(absMinutes)m" : "+\(absMinutes)m"
    }
}

#Preview {
    TimelineView()
        .environment(AppState())
}
