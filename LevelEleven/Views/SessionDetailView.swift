//
//  SessionDetailView.swift
//  LevelEleven
//
//  Version: 1.0  |  2026-03-11
//
//  Detailansicht einer archivierten Baller-Mode-Session.
//  Zeigt Header-Card (Dauer, Teilnehmer, Doses), Level-History-Chart (Swift Charts),
//  Teilnehmer-Liste mit Peak-Level und Substanz-Mengen, chronologische Dose-Timeline,
//  sowie Statistik-Karten (Doses/h, Ø Abstand, Max Gruppen-Level, Substanzanzahl).
//  "Resume"-Button in der Toolbar setzt die Session als aktive Session fort.
//
//  HINWEIS: calculatePeakLevel() und calculateLevelTimeline() iterieren in 5-/10-Minuten-
//  Schritten über die Session-Dauer – bei sehr langen Sessions kann das CPU-intensiv sein.
//
//  Author: Silja & Xaver
//  Created: 2026-01-04
//

import SwiftUI
import Charts

struct SessionDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let session: BallerSession
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerCard
                    if !sessionDoses.isEmpty {
                        levelChartCard
                    }
                    participantsSection
                    dosesSection
                    statsSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(session.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        appState.resumeSession(session)
                        dismiss()
                    } label: {
                        Label("Resume", systemImage: "play.fill")
                    }
                }
            }
        }
    }
    
    private var headerCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color.accent.opacity(0.3), .pink.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 80, height: 80)
                Image(systemName: "person.3.fill")
                    .font(.title)
                    .foregroundStyle(Color.accent)
            }
            
            VStack(spacing: 4) {
                Text(session.name)
                    .font(.title2.bold())
                Text(session.dateFormatted)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 32) {
                statItem(value: "\(session.allParticipantIds.count)", label: "Participants")
                statItem(value: session.durationFormatted, label: "Duration")
                statItem(value: "\(sessionDoses.count)", label: "Doses")
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
    }
    
    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(Color.accent)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Participants")
                .font(.headline)
            
            ForEach(session.participants) { participant in
                if let profile = appState.profiles.first(where: { $0.id == participant.profileId }) {
                    participantRow(profile, participant: participant)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func participantRow(_ profile: Profile, participant: SessionParticipant) -> some View {
        let profileDoses = sessionDoses.filter { $0.profileId == profile.id }
        let peakLevel = calculatePeakLevel(for: profile)
        let totalAmount = calculateTotalAmount(for: profile)
        
        return VStack(spacing: 8) {
            HStack(spacing: 12) {
                Text(profile.avatarEmoji)
                    .font(.title2)
                    .opacity(participant.isActive ? 1.0 : 0.5)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(profile.name)
                            .font(.subheadline.bold())
                        if !participant.isActive {
                            Text("(left)")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                    }
                    Text("\(profileDoses.count) doses")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.1f", peakLevel))
                        .font(.title3.bold())
                        .foregroundStyle(appState.levelColor(for: peakLevel))
                    Text("Peak")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            if !profileDoses.isEmpty {
                HStack(spacing: 16) {
                    ForEach(totalAmount.sorted(by: { $0.key < $1.key }), id: \.key) { substanceId, amount in
                        if let substance = Substances.byId[substanceId] {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color(hex: substance.category.color))
                                    .frame(width: 6, height: 6)
                                Text("\(String(format: "%.0f", amount))\(substance.unit.symbol)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    Spacer()
                }
            }
        }
        .padding(.vertical, 4)
        .opacity(participant.isActive ? 1.0 : 0.7)
    }
    
    private func calculateTotalAmount(for profile: Profile) -> [String: Double] {
        var totals: [String: Double] = [:]
        for dose in sessionDoses where dose.profileId == profile.id {
            totals[dose.substanceId, default: 0] += dose.amount
        }
        return totals
    }
    
    private var dosesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timeline")
                .font(.headline)
            
            if sessionDoses.isEmpty {
                HStack {
                    Image(systemName: "tray")
                        .foregroundStyle(.secondary)
                    Text("No doses in this session")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            } else {
                ForEach(sessionDoses.sorted(by: { $0.timestamp < $1.timestamp })) { dose in
                    doseRow(dose)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func doseRow(_ dose: Dose) -> some View {
        let profile = appState.profiles.first(where: { $0.id == dose.profileId })
        let substance = Substances.byId[dose.substanceId]
        
        return HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: substance?.category.color ?? "888888"))
                .frame(width: 8, height: 8)
            
            Text(profile?.avatarEmoji ?? "👤")
                .font(.body)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(substance?.name ?? dose.substanceId)
                    .font(.subheadline)
                Text("\(Int(dose.amount))\(substance?.unit.rawValue ?? "mg") \(dose.route.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let note = dose.note {
                    Text("💬 \(note)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .italic()
                }
            }
            
            Spacer()
            
            Text(timeFormatted(dose.timestamp))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Statistics")
                .font(.headline)
            
            overviewStatsGrid
            
            Divider()
            
            substanceStatsSection
            
            if !sessionDoses.isEmpty {
                Divider()
                hourlyFrequencySection
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var overviewStatsGrid: some View {
        let avgTimeBetweenDoses = calculateAvgTimeBetweenDoses()
        let dosesPerHour = session.durationMinutes > 0 ? Double(sessionDoses.count) / (session.durationMinutes / 60.0) : 0
        let maxGroupLevel = calculateMaxGroupLevel()
        
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            miniStatCard(value: String(format: "%.1f", dosesPerHour), label: "Doses/Hour", icon: "chart.bar.fill", color: .blue)
            miniStatCard(value: avgTimeBetweenDoses > 0 ? "\(Int(avgTimeBetweenDoses))m" : "-", label: "Avg. Time Between Doses", icon: "clock.fill", color: .orange)
            miniStatCard(value: String(format: "%.1f", maxGroupLevel), label: "Max Group Level", icon: "gauge.with.needle.fill", color: Color.accent)
            miniStatCard(value: "\(uniqueSubstanceCount)", label: "Substances", icon: "pills.fill", color: .green)
        }
    }
    
    private func miniStatCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(value)
                    .font(.title3.bold())
                    .foregroundStyle(color)
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
    }
    
    private var substanceStatsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Substances")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
            
            let substanceAmounts = totalSubstanceAmounts
            
            ForEach(substanceAmounts.sorted(by: { $0.value > $1.value }), id: \.key) { substanceId, amount in
                if let substance = Substances.byId[substanceId] {
                    HStack {
                        Circle()
                            .fill(Color(hex: substance.category.color))
                            .frame(width: 10, height: 10)
                        Text(substance.name)
                            .font(.subheadline)
                        Spacer()
                        Text("\(substanceBreakdown[substanceId] ?? 0)x")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.0f%@", amount, substance.unit.symbol))
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                    }
                }
            }
            
            if substanceAmounts.isEmpty {
                Text("No substances")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var hourlyFrequencySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Doses per Hour")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
            
            let hourlyData = calculateHourlyFrequency()
            
            Chart(hourlyData, id: \.hour) { item in
                BarMark(
                    x: .value("Hour", item.hour),
                    y: .value("Doses", item.count)
                )
                .foregroundStyle(Color.accent.gradient)
                .cornerRadius(4)
            }
            .frame(height: 120)
            .chartXAxisLabel("Session Hour")
            .chartYAxisLabel("Doses")
        }
    }
    
    private var levelChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Level History")
                .font(.headline)
            
            let levelData = calculateLevelTimeline()
            
            Chart {
                ForEach(levelData, id: \.profileId) { profileData in
                    ForEach(profileData.points) { point in
                        LineMark(
                            x: .value("Time", point.time),
                            y: .value("Level", point.level)
                        )
                        .foregroundStyle(by: .value("Profile", profileData.name))
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)
                    }
                }
                
                ForEach(sessionDoses) { dose in
                    if let profile = appState.profiles.first(where: { $0.id == dose.profileId }) {
                        PointMark(
                            x: .value("Time", dose.timestamp),
                            y: .value("Level", appState.currentLevel(for: profile, at: dose.timestamp))
                        )
                        .foregroundStyle(by: .value("Profile", profile.name))
                        .symbolSize(30)
                    }
                }
            }
            .frame(height: 200)
            .chartYScale(domain: 0...11)
            .chartLegend(position: .bottom)
            
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Circle()
                        .stroke(lineWidth: 2)
                        .frame(width: 8, height: 8)
                    Text("Line = Level")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 4) {
                    Circle()
                        .fill()
                        .frame(width: 6, height: 6)
                    Text("Dot = Dose")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Helpers
    
    private var sessionDoses: [Dose] {
        appState.sessionDoses(for: session)
    }
    
    private var substanceBreakdown: [String: Int] {
        var counts: [String: Int] = [:]
        for dose in sessionDoses {
            counts[dose.substanceId, default: 0] += 1
        }
        return counts
    }
    
    private var totalSubstanceAmounts: [String: Double] {
        var amounts: [String: Double] = [:]
        for dose in sessionDoses {
            amounts[dose.substanceId, default: 0] += dose.amount
        }
        return amounts
    }
    
    private var uniqueSubstanceCount: Int {
        Set(sessionDoses.map { $0.substanceId }).count
    }
    
    private func calculatePeakLevel(for profile: Profile) -> Double {
        let endTime = session.endedAt ?? Date()
        return LevelTimelineService.peakLevel(for: profile, from: session.startedAt, to: endTime, appState: appState)
    }
    
    private func calculateMaxGroupLevel() -> Double {
        let endTime = session.endedAt ?? Date()
        var maxLevel: Double = 0
        let interval: TimeInterval = 5 * 60
        var time = session.startedAt
        
        while time <= endTime {
            var groupSum: Double = 0
            for participant in session.participants {
                if let profile = appState.profiles.first(where: { $0.id == participant.profileId }) {
                    groupSum += appState.currentLevel(for: profile, at: time)
                }
            }
            let avgLevel = session.participants.isEmpty ? 0 : groupSum / Double(session.participants.count)
            if avgLevel > maxLevel { maxLevel = avgLevel }
            time = time.addingTimeInterval(interval)
        }
        return maxLevel
    }
    
    private func calculateAvgTimeBetweenDoses() -> Double {
        let sorted = sessionDoses.sorted { $0.timestamp < $1.timestamp }
        guard sorted.count > 1 else { return 0 }
        
        var totalInterval: TimeInterval = 0
        for i in 1..<sorted.count {
            totalInterval += sorted[i].timestamp.timeIntervalSince(sorted[i-1].timestamp)
        }
        return (totalInterval / 60.0) / Double(sorted.count - 1)
    }
    
    private func calculateHourlyFrequency() -> [(hour: Int, count: Int)] {
        guard !sessionDoses.isEmpty else { return [] }
        
        let sessionHours = max(1, Int(ceil(session.durationMinutes / 60.0)))
        var hourlyCount: [Int: Int] = [:]
        
        for dose in sessionDoses {
            let minutesFromStart = dose.timestamp.timeIntervalSince(session.startedAt) / 60.0
            let hour = max(0, min(sessionHours - 1, Int(minutesFromStart / 60.0)))
            hourlyCount[hour, default: 0] += 1
        }
        
        return (0..<sessionHours).map { hour in
            (hour: hour + 1, count: hourlyCount[hour] ?? 0)
        }
    }
    
    private func calculateLevelTimeline() -> [ProfileLevelTimeline] {
        let endTime = session.endedAt ?? Date()
        return session.participants.compactMap { participant -> ProfileLevelTimeline? in
            guard let profile = appState.profiles.first(where: { $0.id == participant.profileId }) else { return nil }
            return LevelTimelineService.buildTimeline(for: profile, from: session.startedAt, to: endTime, appState: appState)
        }
    }
    
    private func timeFormatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    let session = BallerSession(name: "Test Session", participantIds: ["xaver", "silja"])
    return SessionDetailView(session: session)
        .environment(AppState())
}
