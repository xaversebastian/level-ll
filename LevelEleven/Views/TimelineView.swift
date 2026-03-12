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
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    timeRangePicker
                    levelChart
                    if let profile = appState.activeProfile {
                        activeSubstancesSection(profile)
                        sobrietyEstimate(profile)
                    }
                }
                .padding()
            }
            .navigationTitle("Timeline")
        }
    }
    
    private var timeRangePicker: some View {
        Picker("Time Range", selection: $timeRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
    }
    
    private var levelChart: some View {
        let data = generateTimelineData()
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Level Over Time")
                .font(.headline)
            
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
            
            // Current time indicator
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
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func activeSubstancesSection(_ profile: Profile) -> some View {
        let active = appState.activeDoses(for: profile.id)
        let substanceIds = Set(active.map { $0.substanceId })
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Active Substances")
                .font(.headline)
            
            if substanceIds.isEmpty {
                Text("No active substances")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(substanceIds), id: \.self) { id in
                    if let substance = Substances.byId[id] {
                        HStack {
                            Image(systemName: substance.category.icon)
                                .foregroundStyle(Color(hex: substance.category.color))
                            
                            Text(substance.name)
                                .font(.subheadline)
                            
                            Spacer()
                            
                            let doses = active.filter { $0.substanceId == id }
                            Text("\(doses.count) dose\(doses.count > 1 ? "s" : "")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
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
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Sobriety Estimate")
                .font(.headline)
            
            if maxEndTime <= 0 {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("You should be sober now")
                }
            } else {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(.orange)
                    
                    let hours = Int(maxEndTime) / 60
                    let mins = Int(maxEndTime) % 60
                    
                    if hours > 0 {
                        Text("Approximately \(hours)h \(mins)m until baseline")
                    } else {
                        Text("Approximately \(mins) minutes until baseline")
                    }
                }
                
                Text("This is an estimate. Individual responses vary.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
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
