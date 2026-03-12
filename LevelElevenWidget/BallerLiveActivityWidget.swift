// BallerLiveActivityWidget.swift — LevelElevenWidget
// v3.0 | 2026-03-12 17:18
// - Lock Screen + Dynamic Island live activity for Baller Mode sessions
// - Stripped legacy comments, added structured header
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
                // MARK: Expanded Leading – Session + Timer
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(context.attributes.sessionName)
                            .font(.subheadline.bold())
                            .lineLimit(1)
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(context.attributes.startDate, style: .timer)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // MARK: Expanded Trailing – Peak Level + Warning badge
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(String(format: "%.1f", context.state.highestLevel))
                            .font(.title2.bold())
                            .foregroundStyle(levelColor(context.state.highestLevel))
                        if context.state.warningCount > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption2)
                                Text("\(context.state.warningCount)")
                                    .font(.caption2.bold())
                            }
                            .foregroundStyle(.orange)
                        } else {
                            Text("\(context.state.totalDoses) doses")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // MARK: Expanded Bottom – Participant rows
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 10) {
                        ForEach(context.state.participantLevels.prefix(4), id: \.name) { p in
                            participantPill(p)
                        }
                    }
                    .padding(.top, 6)
                }

            } compactLeading: {
                // Crew count + warning dot
                HStack(spacing: 3) {
                    Image(systemName: "person.3.fill")
                        .font(.caption2)
                    Text("\(context.state.participantCount)")
                        .font(.caption.bold())
                    if context.state.warningCount > 0 {
                        Circle()
                            .fill(.orange)
                            .frame(width: 5, height: 5)
                    }
                }
                .foregroundStyle(Color.levelCopper)

            } compactTrailing: {
                // Highest level in level color
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

    // MARK: - Lock Screen View

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<BallerActivityAttributes>) -> some View {
        VStack(spacing: 10) {
            // Header
            HStack(alignment: .firstTextBaseline) {
                Text(context.attributes.sessionName)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.caption2)
                    Text(context.attributes.startDate, style: .timer)
                        .font(.caption.monospacedDigit())
                }
                .foregroundStyle(.secondary)
            }

            Divider().overlay(.white.opacity(0.15))

            // Participant rows
            VStack(spacing: 6) {
                ForEach(context.state.participantLevels.prefix(5), id: \.name) { participant in
                    participantRow(participant)
                }
            }

            Divider().overlay(.white.opacity(0.15))

            // Footer: warnings + doses
            HStack(spacing: 12) {
                if context.state.warningCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                        Text("\(context.state.warningCount) warning\(context.state.warningCount > 1 ? "s" : "")")
                            .font(.caption.bold())
                    }
                    .foregroundStyle(.orange)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                        Text("No warnings")
                            .font(.caption)
                    }
                    .foregroundStyle(Color.levelGreen)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "pills.fill")
                        .font(.caption2)
                    Text("\(context.state.totalDoses) doses")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .foregroundStyle(.white)
        .background(Color.heroBackground)
    }

    // MARK: - Participant Row (Lock Screen)

    private func participantRow(_ participant: BallerActivityAttributes.ParticipantLevel) -> some View {
        HStack(spacing: 10) {
            // Emoji
            Text(participant.emoji)
                .font(.system(size: 16))
                .frame(width: 24)

            // Level bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.white.opacity(0.15))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(levelColor(participant.level))
                        .frame(width: geo.size.width * min(participant.level / 11.0, 1.0))
                }
            }
            .frame(height: 6)

            // Level number
            Text(String(format: "%.1f", participant.level))
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(levelColor(participant.level))
                .frame(width: 28, alignment: .trailing)

            // Time to sober
            if let mins = participant.minutesToSober, mins > 0 {
                Text(formatSoberTime(mins))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, alignment: .trailing)
            } else {
                Text("sober")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.levelGreen)
                    .frame(width: 44, alignment: .trailing)
            }
        }
    }

    // MARK: - Participant Pill (Dynamic Island Bottom)

    private func participantPill(_ participant: BallerActivityAttributes.ParticipantLevel) -> some View {
        VStack(spacing: 3) {
            Text(participant.emoji)
                .font(.system(size: 13))

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(.white.opacity(0.2))
                RoundedRectangle(cornerRadius: 2)
                    .fill(levelColor(participant.level))
                    .frame(width: 32 * min(participant.level / 11.0, 1.0))
            }
            .frame(width: 32, height: 3)

            Text(String(format: "%.0f", participant.level))
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(levelColor(participant.level))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func formatSoberTime(_ minutes: Int) -> String {
        if minutes < 60 { return "~\(minutes)m" }
        let h = minutes / 60
        let m = minutes % 60
        return m > 0 ? "~\(h)h\(m)m" : "~\(h)h"
    }

    private func levelColor(_ level: Double) -> Color {
        switch Int(level.rounded()) {
        case 0:      return .secondary
        case 1...2:  return Color.levelGreen
        case 3...4:  return Color.levelAmber
        case 5...6:  return Color.levelOrange
        case 7...8:  return Color.levelWarm
        case 9...11: return Color.levelMagenta
        default:     return .secondary
        }
    }
}
#endif
