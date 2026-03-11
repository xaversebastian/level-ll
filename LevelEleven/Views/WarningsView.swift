//
//  WarningsView.swift
//  LevelEleven
//
//  Version: 1.0  |  2026-03-11
//
//  Warnungs-Anzeige für das aktive Profil.
//  WarningsView zeigt alle aktiven Interaktions- und Level-Warnungen als Cards,
//  farbcodiert nach WarningSeverity (info/caution/warning/danger).
//  WarningsBannerView ist eine kompakte 1-Zeilen-Variante für eingebettete Nutzung.
//
//  HINWEIS: Beide Views erfordern AppState über @Environment.
//  Wird in HomeView als Sheet und als eingebettete Card genutzt.
//
//  Author: Silja & Xaver
//  Created: 2026-01-04
//

import SwiftUI

struct WarningsView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        let warnings = currentWarnings
        
        return VStack(alignment: .leading, spacing: 12) {
            if warnings.isEmpty {
                HStack {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(.green)
                    Text("No warnings")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(warnings) { warning in
                    warningCard(warning)
                }
            }
        }
    }
    
    private var currentWarnings: [Warning] {
        guard let profile = appState.activeProfile else { return [] }
        
        let active = appState.activeDoses(for: profile.id)
        let substances = active.map { $0.substanceId }
        
        var warnings = WarningSystem.checkInteractions(substances: substances)
        
        let level = appState.currentLevel(for: profile)
        warnings.append(contentsOf: WarningSystem.checkLevel(level: level, limit: profile.personalLimit))
        
        return warnings.sorted { $0.severity > $1.severity }
    }
    
    private func warningCard(_ warning: Warning) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: warning.severity.icon)
                    .foregroundStyle(warning.severity.color)
                
                Text(warning.title)
                    .font(.subheadline.bold())
                
                Spacer()
            }
            
            Text(warning.message)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                    .font(.caption)
                Text(warning.advice)
                    .font(.caption)
            }
            .padding(8)
            .background(.yellow.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
        }
        .padding()
        .background(warning.severity.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct WarningsBannerView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        let topWarning = getTopWarning()
        
        if let warning = topWarning {
            HStack {
                Image(systemName: warning.severity.icon)
                    .foregroundStyle(warning.severity.color)
                
                Text(warning.title)
                    .font(.caption.bold())
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(warning.severity.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
        }
    }
    
    private func getTopWarning() -> Warning? {
        guard let profile = appState.activeProfile else { return nil }
        
        let active = appState.activeDoses(for: profile.id)
        let substances = active.map { $0.substanceId }
        
        let warnings = WarningSystem.checkInteractions(substances: substances)
        return warnings.first
    }
}

#Preview {
    VStack {
        WarningsView()
        WarningsBannerView()
    }
    .padding()
    .environment(AppState())
}
