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
        let calm = appState.calmMode
        
        return VStack(spacing: 0) {
            if calm {
                HStack(spacing: 10) {
                    Image(systemName: "leaf.fill")
                        .foregroundStyle(Color.levelCalm)
                    Text("Calm mode — showing supportive guidance")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, DS.screenPadding)
                .padding(.vertical, 8)
            }

            if warnings.isEmpty {
                HStack(spacing: 14) {
                    Image(systemName: calm ? "leaf.fill" : "checkmark.shield.fill")
                        .foregroundStyle(calm ? Color.levelCalm : .green)
                        .frame(width: 22)
                    Text(calm ? "All clear — you're doing well" : "No warnings")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, DS.screenPadding)
                .padding(.vertical, 10)
            } else {
                ForEach(Array(warnings.enumerated()), id: \.element.id) { idx, warning in
                    if idx > 0 { Divider().padding(.leading, 54) }
                    warningRow(warning, calm: calm)
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
        warnings.append(contentsOf: WarningSystem.checkLevel(level: level, limit: profile.personalLimit, proLevel: profile.proLevel))

        return warnings.sorted { $0.severity > $1.severity }
    }
    
    private func warningRow(_ warning: Warning, calm: Bool) -> some View {
        let wColor = warning.severity.displayColor(calm: calm)
        let wIcon  = warning.severity.displayIcon(calm: calm)

        return HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 2)
                .fill(wColor)
                .frame(width: 3, height: 40)

            Image(systemName: wIcon)
                .foregroundStyle(wColor)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 4) {
                Text(warning.title)
                    .font(.subheadline.bold())

                if calm {
                    HStack(spacing: 4) {
                        Image(systemName: "hand.raised.fill")
                            .foregroundStyle(Color.levelCalm)
                            .font(.caption2)
                        Text(warning.advice)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
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
        let calm = appState.calmMode
        
        if let warning = topWarning {
            let wColor = warning.severity.displayColor(calm: calm)
            let wIcon  = warning.severity.displayIcon(calm: calm)

            HStack {
                Image(systemName: wIcon)
                    .foregroundStyle(wColor)
                
                Text(calm ? warning.advice : warning.title)
                    .font(.caption.bold())
                    .lineLimit(1)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(wColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
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
