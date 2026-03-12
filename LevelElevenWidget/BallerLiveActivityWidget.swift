//
//  BallerLiveActivityWidget.swift
//  LevelElevenWidget
//
//  Version: 1.0  |  2026-03-11
//
//  Lock-Screen- und Dynamic-Island-Widget für aktive Baller-Mode-Sessions.
//  Lock Screen: Session-Name, Timer, Teilnehmeranzahl, Peak-Level, Doses.
//             Darunter: Mini-Level-Bars für bis zu 5 Teilnehmer.
//  Dynamic Island expanded: Leading = Name/Timer, Trailing = Peak/Doses,
//             Bottom = Teilnehmer-Emojis mit Level-Bars.
//  Compact/Minimal: Teilnehmeranzahl + höchstes Level.
//
//  SETUP: Diese Datei ins Widget-Extension-Target:
//  1. Xcode: File → New → Target → Widget Extension → "LevelElevenWidget"
//  2. "Include Live Activity" ankreuzen
//  3. Diese Datei, BallerActivityAttributes.swift und Color+Hex.swift zum Widget-Target hinzufügen
//  4. NSSupportsLiveActivities = YES in der App-Info.plist
//  5. BallerActivityAttributes.swift BEIDEN Targets (App + Widget) zuordnen
//

#if canImport(ActivityKit) && canImport(WidgetKit)
import ActivityKit
import WidgetKit
import SwiftUI

struct BallerLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BallerActivityAttributes.self) { context in
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.attributes.sessionName)
                            .font(.headline)
                            .lineLimit(1)
                        Text(context.attributes.startDate, style: .timer)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(String(format: "%.1f", context.state.highestLevel))
                            .font(.title2.bold())
                            .foregroundStyle(levelColor(context.state.highestLevel))
                        Text("\(context.state.totalDoses) doses")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 8) {
                        ForEach(context.state.participantLevels.prefix(4), id: \.name) { participant in
                            VStack(spacing: 2) {
                                Text(participant.emoji)
                                    .font(.caption)
                                miniLevelBar(level: participant.level)
                                Text(String(format: "%.0f", participant.level))
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundStyle(levelColor(participant.level))
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                HStack(spacing: 2) {
                    Image(systemName: "person.3.fill")
                        .font(.caption2)
                    Text("\(context.state.participantCount)")
                        .font(.caption.bold())
                }
                .foregroundStyle(Color.levelViolet)
            } compactTrailing: {
                Text(String(format: "%.0f", context.state.highestLevel))
                    .font(.caption.bold())
                    .foregroundStyle(levelColor(context.state.highestLevel))
            } minimal: {
                Text(String(format: "%.0f", context.state.highestLevel))
                    .font(.caption2.bold())
                    .foregroundStyle(levelColor(context.state.highestLevel))
            }
        }
    }
    
    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<BallerActivityAttributes>) -> some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.sessionName)
                        .font(.headline)
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                        Text(context.attributes.startDate, style: .timer)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 16) {
                    VStack(spacing: 0) {
                        Text("\(context.state.participantCount)")
                            .font(.title3.bold())
                        Text("crew")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                    
                    VStack(spacing: 0) {
                        Text(String(format: "%.1f", context.state.highestLevel))
                            .font(.title3.bold())
                            .foregroundStyle(levelColor(context.state.highestLevel))
                        Text("peak")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                    
                    VStack(spacing: 0) {
                        Text("\(context.state.totalDoses)")
                            .font(.title3.bold())
                        Text("doses")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            HStack(spacing: 6) {
                ForEach(context.state.participantLevels.prefix(5), id: \.name) { participant in
                    VStack(spacing: 3) {
                        Text(participant.emoji)
                            .font(.system(size: 14))
                        miniLevelBar(level: participant.level)
                        Text(String(format: "%.0f", participant.level))
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(levelColor(participant.level))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .background(Color.levelDarkBlue.opacity(0.9))
    }
    
    private func miniLevelBar(level: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(.gray.opacity(0.3))
                RoundedRectangle(cornerRadius: 2)
                    .fill(levelColor(level))
                    .frame(width: geo.size.width * min(level / 11.0, 1.0))
            }
        }
        .frame(height: 4)
    }
    
    private func levelColor(_ level: Double) -> Color {
        switch Int(level.rounded()) {
        case 0: return .gray
        case 1...2: return .green
        case 3...4: return .yellow
        case 5...6: return .orange
        case 7...8: return .red
        case 9...11: return Color.levelMagenta
        default: return .gray
        }
    }
}
#endif
