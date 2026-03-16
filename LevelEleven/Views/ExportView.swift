// ExportView.swift — LevelEleven
// v1.0 | 2026-03-16
// - Smart dose export: choose scope (all, profile, session) and format (text/PDF)
//

import SwiftUI

struct ExportView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    enum ExportScope: String, CaseIterable {
        case allDoses = "All Doses"
        case activeProfile = "Active Profile"
        case specificSession = "Specific Session"
    }

    enum ExportFormat: String, CaseIterable {
        case text = "Text (WhatsApp)"
        case csv = "CSV Spreadsheet"
    }

    @State private var scope: ExportScope = .allDoses
    @State private var format: ExportFormat = .text
    @State private var selectedSessionId: String?
    @State private var exportContent: String?
    @State private var showShareSheet = false

    private var doses: [Dose] {
        switch scope {
        case .allDoses:
            return appState.doses.sorted { $0.timestamp > $1.timestamp }
        case .activeProfile:
            guard let profile = appState.activeProfile else { return [] }
            return appState.doses.filter { $0.profileId == profile.id }.sorted { $0.timestamp > $1.timestamp }
        case .specificSession:
            guard let sessionId = selectedSessionId,
                  let session = appState.sessionHistory.first(where: { $0.id == sessionId }) else { return [] }
            let sessionDoses = session.participantIds.flatMap { pid in
                appState.doses.filter { $0.profileId == pid && $0.timestamp >= session.startedAt && $0.timestamp <= (session.endedAt ?? Date()) }
            }
            return sessionDoses.sorted { $0.timestamp > $1.timestamp }
        }
    }

    private var recentSessions: [BallerSession] {
        Array(appState.sessionHistory.prefix(10))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Scope
                    VStack(alignment: .leading, spacing: 8) {
                        Text("WHAT TO EXPORT")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(2)
                            .foregroundStyle(.secondary)

                        Picker("Scope", selection: $scope) {
                            ForEach(ExportScope.allCases, id: \.self) { s in
                                Text(s.rawValue).tag(s)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal, DS.screenPadding)

                    // Session picker (if specific session)
                    if scope == .specificSession {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SELECT SESSION")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(2)
                                .foregroundStyle(.secondary)

                            if recentSessions.isEmpty {
                                Text("No sessions found.")
                                    .font(.subheadline)
                                    .foregroundStyle(.tertiary)
                            } else {
                                ForEach(recentSessions, id: \.id) { session in
                                    Button {
                                        selectedSessionId = session.id
                                    } label: {
                                        HStack(spacing: 12) {
                                            Image(systemName: selectedSessionId == session.id ? "checkmark.circle.fill" : "circle")
                                                .foregroundStyle(selectedSessionId == session.id ? Color.accent : .secondary)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(session.name)
                                                    .font(.subheadline.bold())
                                                    .foregroundStyle(.primary)
                                                Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                        }
                                        .padding(.vertical, 6)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, DS.screenPadding)
                    }

                    // Format
                    VStack(alignment: .leading, spacing: 8) {
                        Text("FORMAT")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(2)
                            .foregroundStyle(.secondary)

                        Picker("Format", selection: $format) {
                            ForEach(ExportFormat.allCases, id: \.self) { f in
                                Text(f.rawValue).tag(f)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal, DS.screenPadding)

                    // Preview
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PREVIEW (\(doses.count) doses)")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(2)
                            .foregroundStyle(.secondary)

                        if doses.isEmpty {
                            Text("No doses match this selection.")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                                .padding(.vertical, 20)
                        } else {
                            Text(buildPreview())
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .lineSpacing(3)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.surfaceSecondary, in: RoundedRectangle(cornerRadius: 10))
                                .frame(maxHeight: 200)
                        }
                    }
                    .padding(.horizontal, DS.screenPadding)

                    // Export button
                    if !doses.isEmpty {
                        if let url = buildExportFile() {
                            ShareLink(item: url) {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Export \(doses.count) Doses")
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(Color.accent.gradient, in: RoundedRectangle(cornerRadius: 14))
                                .foregroundStyle(.white)
                            }
                            .padding(.horizontal, DS.screenPadding)
                        }
                    }
                }
                .padding(.vertical, 16)
            }
            .scrollIndicators(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Export Doses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Build Export

    private func buildPreview() -> String {
        let preview = doses.prefix(5)
        let lines = preview.map { formatDoseLine($0) }
        var result = lines.joined(separator: "\n")
        if doses.count > 5 {
            result += "\n... +\(doses.count - 5) more"
        }
        return result
    }

    private func formatDoseLine(_ dose: Dose) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM HH:mm"
        let date = formatter.string(from: dose.timestamp)
        let substance = Substances.byId[dose.substanceId]?.shortName ?? dose.substanceId
        let unit = Substances.byId[dose.substanceId]?.unit.symbol ?? ""
        let amount = dose.amount == floor(dose.amount) ? String(format: "%.0f", dose.amount) : String(format: "%.1f", dose.amount)
        return "\(date)  \(substance) \(amount)\(unit) (\(dose.route.displayName))"
    }

    private func buildExportFile() -> URL? {
        let profileMap = Dictionary(uniqueKeysWithValues: appState.profiles.map { ($0.id, $0.name) })

        switch format {
        case .text:
            return buildTextExport(profileMap: profileMap)
        case .csv:
            return buildCSVExport(profileMap: profileMap)
        }
    }

    private func buildTextExport(profileMap: [String: String]) -> URL? {
        var lines: [String] = []
        lines.append("Level Eleven — Dose Export")
        lines.append("Generated: \(Date().formatted(date: .abbreviated, time: .shortened))")
        lines.append("")

        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"

        for dose in doses {
            let date = formatter.string(from: dose.timestamp)
            let profile = profileMap[dose.profileId] ?? "Unknown"
            let substance = Substances.byId[dose.substanceId]?.shortName ?? dose.substanceId
            let unit = Substances.byId[dose.substanceId]?.unit.symbol ?? ""
            let amount = dose.amount == floor(dose.amount) ? String(format: "%.0f", dose.amount) : String(format: "%.1f", dose.amount)
            let route = dose.route.displayName
            var line = "\(date) | \(profile) | \(substance) \(amount)\(unit) (\(route))"
            if let note = dose.note, !note.isEmpty {
                line += " — \(note)"
            }
            lines.append(line)
        }

        lines.append("")
        lines.append("\(doses.count) doses total")

        let text = lines.joined(separator: "\n")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("level-ll-export.txt")
        try? text.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func buildCSVExport(profileMap: [String: String]) -> URL? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        var csv = "Date,Profile,Substance,Route,Amount,Unit,Note\n"
        for dose in doses {
            let date = formatter.string(from: dose.timestamp)
            let profile = profileMap[dose.profileId] ?? dose.profileId
            let substance = Substances.byId[dose.substanceId]?.name ?? dose.substanceId
            let route = dose.route.displayName
            let amount = dose.amount
            let unit = Substances.byId[dose.substanceId]?.unit.symbol ?? ""
            let note = dose.note?.replacingOccurrences(of: ",", with: ";") ?? ""
            csv += "\(date),\(profile),\(substance),\(route),\(amount),\(unit),\(note)\n"
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("level-ll-export.csv")
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
