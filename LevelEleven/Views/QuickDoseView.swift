//
//  QuickDoseView.swift
//  LevelEleven
//
//  Version: 1.0  |  2026-03-11
//
//  Schneller Dose-Logger für das aktive Profil.
//  Phase 1: Substanzliste mit Suchfeld und Favoriten-Sektion.
//  Phase 2: Dosis-Formular mit Route-Picker (Segmented), Menge-Slider,
//           Light/Common/Strong-Schnellwahl und personalisierten Infos.
//  logDose() ruft AppState.logDose() auf und schließt den Sheet.
//
//  HINWEIS: Wird über MoreView → "Quick Dose" aufgerufen.
//  Für Gruppen-Dosing: GroupDoseView in BallerModeView.swift.
//
//  Author: Silja & Xaver
//  Created: 2026-01-04
//

import SwiftUI

struct QuickDoseView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedSubstance: Substance?
    @State private var selectedRoute: DoseRoute = .oral
    @State private var amount: Double = 0
    @State private var searchText = ""
    
    var filteredSubstances: [Substance] {
        if searchText.isEmpty {
            return Substances.all
        }
        return Substances.all.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.shortName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if let substance = selectedSubstance {
                    doseForm(substance)
                } else {
                    substanceList
                }
            }
            .navigationTitle(selectedSubstance == nil ? "Quick Dose" : "Log Dose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if selectedSubstance != nil {
                            selectedSubstance = nil
                        } else {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
    
    private var substanceList: some View {
        List {
            if let profile = appState.activeProfile, !profile.favorites.isEmpty {
                Section("Favorites") {
                    ForEach(profile.favorites, id: \.self) { id in
                        if let substance = Substances.byId[id] {
                            substanceRow(substance)
                        }
                    }
                }
            }
            
            Section("All Substances") {
                ForEach(filteredSubstances) { substance in
                    substanceRow(substance)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search substances")
    }
    
    private func substanceRow(_ substance: Substance) -> some View {
        Button {
            selectedSubstance = substance
            selectedRoute = substance.primaryRoute
            amount = substance.commonDose
        } label: {
            HStack {
                Image(systemName: substance.category.icon)
                    .foregroundStyle(Color(hex: substance.category.color))
                    .frame(width: 30)
                
                VStack(alignment: .leading) {
                    Text(substance.name)
                        .font(.body)
                    Text(substance.category.rawValue.capitalized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text("\(String(format: "%.0f", substance.commonDose)) \(substance.unit.symbol)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(.primary)
    }
    
    private func doseForm(_ substance: Substance) -> some View {
        Form {
            Section {
                HStack {
                    Image(systemName: substance.category.icon)
                        .font(.title)
                        .foregroundStyle(Color(hex: substance.category.color))
                    
                    VStack(alignment: .leading) {
                        Text(substance.name)
                            .font(.title2.bold())
                        Text(substance.category.rawValue.capitalized)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section("Route") {
                Picker("Route", selection: $selectedRoute) {
                    ForEach(substance.routes, id: \.self) { route in
                        Text(route.displayName).tag(route)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Section("Amount") {
                VStack(spacing: 16) {
                    HStack {
                        Text(String(format: "%.1f", amount))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                        Text(substance.unit.symbol)
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    
                    Slider(value: $amount, in: 0...substance.strongDose * 2, step: doseStep(for: substance))
                    
                    HStack {
                        doseButton("Light", dose: substance.lightDose)
                        doseButton("Common", dose: substance.commonDose)
                        doseButton("Strong", dose: substance.strongDose)
                    }
                }
                .padding(.vertical, 8)
            }
            
            if let profile = appState.activeProfile {
                Section("Personalized Info") {
                    let tolerance = profile.tolerance(for: substance.id)
                    HStack {
                        Text("Tolerance")
                        Spacer()
                        Text("Level \(tolerance)")
                            .foregroundStyle(.secondary)
                    }
                    
                    let recommended = substance.commonDose * profile.toleranceFactor(for: substance.id)
                    HStack {
                        Text("Recommended")
                        Spacer()
                        Text("\(String(format: "%.0f", recommended)) \(substance.unit.symbol)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section {
                Button {
                    logDose(substance)
                } label: {
                    HStack {
                        Spacer()
                        Text("Log Dose")
                            .font(.headline)
                        Spacer()
                    }
                }
                .disabled(amount <= 0)
            }
        }
    }
    
    private func doseButton(_ label: String, dose: Double) -> some View {
        Button {
            amount = dose
        } label: {
            VStack {
                Text(String(format: "%.0f", dose))
                    .font(.headline)
                Text(label)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(amount == dose ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
    
    private func doseStep(for substance: Substance) -> Double {
        switch substance.unit {
        case .mg: return substance.commonDose < 10 ? 0.5 : 5
        case .ml: return 0.1
        case .drinks: return 0.5
        case .ug: return 5
        case .puffs: return 1
        case .g: return 0.5
        }
    }
    
    private func logDose(_ substance: Substance) {
        appState.logDose(substanceId: substance.id, route: selectedRoute, amount: amount)
        dismiss()
    }
}

#Preview {
    QuickDoseView()
        .environment(AppState())
}
