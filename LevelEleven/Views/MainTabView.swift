//
//  MainTabView.swift
//  LevelEleven
//
//  Main tab navigation: Home, Profiles, Baller(+), Emergency, More
//

import SwiftUI

struct MainTabView: View {
    @State private var appState = AppState()
    @State private var selectedTab = 0
    @State private var showBallerMode = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(0)
                    .tabItem {
                        Label("Home", systemImage: "gauge.with.needle.fill")
                    }
                
                ProfileView()
                    .tag(1)
                    .tabItem {
                        Label("Profiles", systemImage: "person.2.fill")
                    }
                
                Color.clear
                    .tag(2)
                    .tabItem { Label("", systemImage: "") }
                
                EmergencyView()
                    .tag(3)
                    .tabItem {
                        Label("Emergency", systemImage: "cross.fill")
                    }
                
                MoreView()
                    .tag(4)
                    .tabItem {
                        Label("More", systemImage: "ellipsis")
                    }
            }
            .tint(Color.accent)
            
            // Center FAB for Baller Mode
            ballerModeButton
        }
        .environment(appState)
        .sheet(isPresented: $showBallerMode) {
            BallerModeView()
                .environment(appState)
        }
    }
    
    private var ballerModeButton: some View {
        Button {
            showBallerMode = true
        } label: {
            ZStack {
                Circle()
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: .primary.opacity(0.12), radius: 6, y: 3)
                
                Image("ll-logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
            }
            .frame(width: 60, height: 60)
        }
        .offset(y: -28)
    }
}

struct MoreView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        NavigationStack {
            List {
                // Quick Actions
                Section {
                    NavigationLink {
                        QuickDoseView()
                    } label: {
                        Label("Quick Dose", systemImage: "bolt.fill")
                    }
                    
                    NavigationLink {
                        SubstanceInfoView()
                    } label: {
                        Label("Substance Info", systemImage: "book.fill")
                    }
                    
                    NavigationLink {
                        TimelineView()
                    } label: {
                        Label("Timeline", systemImage: "chart.xyaxis.line")
                    }
                }
                
                // Current Profile
                if let profile = appState.activeProfile {
                    Section("Current Session") {
                        HStack {
                            Text(profile.avatarEmoji)
                                .font(.title2)
                            VStack(alignment: .leading) {
                                Text(profile.name)
                                    .font(.headline)
                                let level = appState.currentLevel(for: profile)
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(appState.levelColor(for: level))
                                        .frame(width: 8, height: 8)
                                    Text("Level \(String(format: "%.1f", level))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        
                        Button(role: .destructive) {
                            appState.clearDoses(for: profile.id)
                        } label: {
                            Label("Clear All Doses", systemImage: "trash")
                        }
                    }
                }
                
                Section("Settings") {
                    HStack {
                        Label("Lock Screen Activity", systemImage: "lock.display")
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { appState.liveActivityEnabled },
                            set: { appState.setLiveActivityEnabled($0) }
                        ))
                        .labelsHidden()
                    }
                    
                    Text("Show session info on the Lock Screen and Dynamic Island during active Baller Mode sessions.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section("About") {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("2.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Label("Privacy", systemImage: "lock.shield")
                        Spacer()
                        Text("Local only")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("More")
        }
    }
}

struct SubstanceInfoView: View {
    var body: some View {
        List {
            ForEach(SubstanceCategory.allCases, id: \.self) { category in
                let substances = Substances.all.filter { $0.category == category }
                if !substances.isEmpty {
                    Section(category.rawValue.capitalized) {
                        ForEach(substances) { substance in
                            NavigationLink {
                                SubstanceDetailView(substance: substance)
                            } label: {
                                HStack {
                                    Image(systemName: category.icon)
                                        .foregroundStyle(Color(hex: category.color))
                                        .frame(width: 28)
                                    
                                    VStack(alignment: .leading) {
                                        Text(substance.name)
                                            .font(.body)
                                        Text(substance.shortName)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Substances")
    }
}

struct SubstanceDetailView: View {
    let substance: Substance
    
    var body: some View {
        List {
            Section("Overview") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: substance.category.icon)
                            .font(.largeTitle)
                            .foregroundStyle(Color(hex: substance.category.color))
                        
                        VStack(alignment: .leading) {
                            Text(substance.name)
                                .font(.title2.bold())
                            Text(substance.category.rawValue.capitalized)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Text(substance.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
            
            Section("Dosage") {
                HStack {
                    Circle().fill(.green).frame(width: 8, height: 8)
                    Text("Light")
                    Spacer()
                    Text(formatDose(substance.lightDose))
                        .foregroundStyle(.green)
                }
                HStack {
                    Circle().fill(.orange).frame(width: 8, height: 8)
                    Text("Common")
                    Spacer()
                    Text(formatDose(substance.commonDose))
                        .foregroundStyle(.orange)
                }
                HStack {
                    Circle().fill(.red).frame(width: 8, height: 8)
                    Text("Strong")
                    Spacer()
                    Text(formatDose(substance.strongDose))
                        .foregroundStyle(.red)
                }
            }
            
            Section("Timing (\(substance.primaryRoute.displayName))") {
                timingRow(label: "Onset", minutes: substance.onsetMinutes)
                timingRow(label: "Peak", minutes: substance.peakMinutes)
                timingRow(label: "Duration", minutes: substance.durationMinutes)
                timingRow(label: "Half-life", minutes: substance.halfLifeMinutes)
            }
            
            Section("Routes") {
                ForEach(substance.routes, id: \.self) { route in
                    HStack {
                        Text(route.displayName)
                        Spacer()
                        Text("\(Int(route.bioavailability * 100))% Bioavailability")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if route == substance.primaryRoute {
                            Text("Primary")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.blue.opacity(0.2), in: Capsule())
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
            
            Section {
                ForEach(substance.risks, id: \.self) { risk in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                        Text(risk)
                            .font(.subheadline)
                    }
                }
            } header: {
                Label("Risks", systemImage: "exclamationmark.triangle")
            }
            
            Section {
                ForEach(substance.saferUse, id: \.self) { tip in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                        Text(tip)
                            .font(.subheadline)
                    }
                }
            } header: {
                Label("Safer Use", systemImage: "heart.text.square")
            }
        }
        .navigationTitle(substance.shortName)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formatDose(_ dose: Double) -> String {
        if dose < 1 {
            return String(format: "%.2f %@", dose, substance.unit.symbol)
        } else if dose == floor(dose) {
            return String(format: "%.0f %@", dose, substance.unit.symbol)
        } else {
            return String(format: "%.1f %@", dose, substance.unit.symbol)
        }
    }
    
    private func timingRow(label: String, minutes: Double) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(formatTime(minutes))
                .foregroundStyle(.secondary)
        }
    }
    
    private func formatTime(_ minutes: Double) -> String {
        if minutes >= 60 {
            let h = Int(minutes) / 60
            let m = Int(minutes) % 60
            return m > 0 ? "\(h)h \(m)min" : "\(h)h"
        }
        return "\(Int(minutes)) min"
    }
}

#Preview {
    MainTabView()
}
