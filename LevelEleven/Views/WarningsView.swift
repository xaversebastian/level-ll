// WarningsView.swift — LevelEleven
// v2.0 | 2026-03-12 17:18
// - Interaction and level warnings with severity colors, plus compact banner variant
// - Stripped legacy comments, added structured header
//

import SwiftUI

struct WarningsView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        let warnings = currentWarnings
        
        return VStack(spacing: 0) {
            if warnings.isEmpty {
                HStack(spacing: 14) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(.green)
                        .frame(width: 22)
                    Text("No warnings")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, DS.screenPadding)
                .padding(.vertical, 10)
            } else {
                ForEach(Array(warnings.enumerated()), id: \.element.id) { idx, warning in
                    if idx > 0 { Divider().padding(.leading, 54) }
                    warningRow(warning)
                }
            }
        }
    }
    
    private var currentWarnings: [Warning] {
        guard let profile = appState.activeProfile else { return [] }

        let active = appState.activeDoses(for: profile.id)
        let allDoses = appState.recentDoses(for: profile.id, hours: 8)

        var warnings = WarningSystem.checkInteractions(activeDoses: active, allDoses: allDoses, profile: profile)

        let level = appState.currentLevel(for: profile)
        warnings.append(contentsOf: WarningSystem.checkLevel(level: level, limit: profile.personalLimit))

        return warnings.sorted { $0.severity > $1.severity }
    }
    
    private func warningRow(_ warning: Warning) -> some View {
        HStack(spacing: 14) {
            // Severity accent line
            RoundedRectangle(cornerRadius: 2)
                .fill(warning.severity.color)
                .frame(width: 3, height: 40)

            Image(systemName: warning.severity.icon)
                .foregroundStyle(warning.severity.color)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 4) {
                Text(warning.title)
                    .font(.subheadline.bold())

                Text(warning.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption2)
                    Text(warning.advice)
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
        let allDoses = appState.recentDoses(for: profile.id, hours: 8)
        return WarningSystem.checkInteractions(activeDoses: active, allDoses: allDoses, profile: profile).first
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
