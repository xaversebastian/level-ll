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

import SwiftUI
import Charts

struct SessionDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let session: BallerSession
    
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
                    headerSection
                    if !sessionDoses.isEmpty {
                        levelChartSection
                    }
                    participantsSection
                    dosesSection
                    statsSection
                }
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
            .background(Color.appBackground)
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
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color.accent)
                .padding(.top, 20)
            
            Text(session.name)
                .font(.system(size: 24, weight: .bold, design: .rounded))
            Text(session.dateFormatted)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 32) {
                statItem(value: "\(session.allParticipantIds.count)", label: "Participants")
                statItem(value: session.durationFormatted, label: "Duration")
                statItem(value: "\(sessionDoses.count)", label: "Doses")
            }
            .padding(.top, 4)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, DS.screenPadding)
    }
    
    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color.accent)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private var participantsSection: some View {
        VStack(spacing: 0) {
            sectionHeader("Participants", color: Color.accent)
            
            ForEach(Array(session.participants.enumerated()), id: \.element.id) { idx, participant in
                if let profile = appState.profiles.first(where: { $0.id == participant.profileId }) {
                    if idx > 0 { Divider().padding(.leading, 54) }
                    participantRow(profile, participant: participant)
                }
            }
        }
    }
    
    private func participantRow(_ profile: Profile, participant: SessionParticipant) -> some View {
        let profileDoses = sessionDoses.filter { $0.profileId == profile.id }
        let peakLevel = calculatePeakLevel(for: profile)
        let totalAmount = calculateTotalAmount(for: profile)
        
        return VStack(spacing: 6) {
            HStack(spacing: 14) {
                Text(profile.avatarEmoji)
                    .font(.title3)
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
                
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(String(format: "%.1f", peakLevel))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(appState.levelColor(for: peakLevel))
                    Text("peak")
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
        .padding(.horizontal, DS.screenPadding)
        .padding(.vertical, 10)
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
        VStack(spacing: 0) {
            sectionHeader("Timeline", color: .secondary)
            
            if sessionDoses.isEmpty {
                HStack(spacing: 14) {
                    Image(systemName: "tray")
                        .foregroundStyle(.secondary)
                        .frame(width: 22)
                    Text("No doses in this session")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, DS.screenPadding)
                .padding(.vertical, 10)
            } else {
                ForEach(Array(sessionDoses.sorted(by: { $0.timestamp < $1.timestamp }).enumerated()), id: \.element.id) { idx, dose in
                    if idx > 0 { Divider().padding(.leading, 54) }
                    doseRow(dose)
                }
            }
        }
    }
    
    private func doseRow(_ dose: Dose) -> some View {
        let profile = appState.profiles.first(where: { $0.id == dose.profileId })
        let substance = Substances.byId[dose.substanceId]
        
        return HStack(spacing: 14) {
            Circle()
                .fill(Color(hex: substance?.category.color ?? "888888"))
                .frame(width: 8, height: 8)
                .frame(width: 22)
            
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
        .padding(.horizontal, DS.screenPadding)
        .padding(.vertical, 8)
    }
    
    private var statsSection: some View {
        VStack(spacing: 0) {
            sectionHeader("Statistics", color: Color.accent)
            
            overviewStatsGrid
                .padding(.horizontal, DS.screenPadding)
                .padding(.bottom, 16)
            
            substanceStatsSection
            
            if !sessionDoses.isEmpty {
                hourlyFrequencySection
            }
        }
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
        VStack(spacing: 0) {
            let substanceAmounts = totalSubstanceAmounts
            
            ForEach(Array(substanceAmounts.sorted(by: { $0.value > $1.value }).enumerated()), id: \.element.key) { idx, item in
                let substanceId = item.key
                let amount = item.value
                if let substance = Substances.byId[substanceId] {
                    if idx > 0 { Divider().padding(.leading, 54) }
                    HStack(spacing: 14) {
                        Circle()
                            .fill(Color(hex: substance.category.color))
                            .frame(width: 10, height: 10)
                            .frame(width: 22)
                        Text(substance.name)
                            .font(.subheadline)
                        Spacer()
                        Text("\(substanceBreakdown[substanceId] ?? 0)x")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.0f%@", amount, substance.unit.symbol))
                            .font(.subheadline.bold())
                    }
                    .padding(.horizontal, DS.screenPadding)
                    .padding(.vertical, 8)
                }
            }
            
            if substanceAmounts.isEmpty {
                HStack(spacing: 14) {
                    Image(systemName: "pills")
                        .foregroundStyle(.secondary)
                        .frame(width: 22)
                    Text("No substances")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, DS.screenPadding)
                .padding(.vertical, 8)
            }
        }
    }
    
    private var hourlyFrequencySection: some View {
        VStack(alignment: .leading, spacing: 8) {
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
        .padding(.horizontal, DS.screenPadding)
        .padding(.vertical, 12)
    }
    
    private var levelChartSection: some View {
        VStack(spacing: 0) {
            sectionHeader("Level History", color: Color.accent)

            VStack(alignment: .leading, spacing: 12) {
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
            .padding(.horizontal, DS.screenPadding)
        }
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
