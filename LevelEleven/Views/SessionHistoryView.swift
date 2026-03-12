//
//  SessionHistoryView.swift
//  LevelEleven
//
//  Version: 1.1  |  2026-03-12
//
//  Liste aller abgeschlossenen Baller-Mode-Sessions aus AppState.sessionHistory.
//  Tipp → öffnet SessionDetailView als Sheet.
//  Swipe links → Löschen (destructive).
//  Swipe rechts → Session fortsetzen (ruft AppState.resumeSession auf).
//  Leerer Zustand zeigt Placeholder-Illustration.
//
//  HINWEIS: Wird als Sheet aus BallerModeView geöffnet.
//

import SwiftUI

struct SessionHistoryView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSession: BallerSession?
    @State private var searchText = ""

    var filteredHistory: [BallerSession] {
        if searchText.isEmpty { return appState.sessionHistory }
        return appState.sessionHistory.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.dateFormatted.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if appState.sessionHistory.isEmpty {
                        emptyState
                    } else {
                        sectionHeader("Sessions", color: Color.accent)

                        ForEach(Array(filteredHistory.enumerated()), id: \.element.id) { idx, session in
                            if idx > 0 { Divider().padding(.leading, 54) }
                            sessionRow(session)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Session History")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search sessions")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $selectedSession) { session in
                SessionDetailView(session: session)
                    .environment(appState)
            }
        }
    }

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
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("No Past Sessions")
                .font(.system(size: 20, weight: .bold, design: .rounded))
            Text("When you end a Baller Mode session,\nit will appear here.")
                .multilineTextAlignment(.center)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    private func sessionRow(_ session: BallerSession) -> some View {
        Button {
            selectedSession = session
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "person.3.fill")
                    .font(.body)
                    .foregroundStyle(Color.accent)
                    .frame(width: 22)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.name)
                        .font(.subheadline.bold())
                    
                    HStack(spacing: 8) {
                        Label(session.dateFormatted, systemImage: "calendar")
                        Label(session.durationFormatted, systemImage: "clock")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text("\(session.allParticipantIds.count)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.accent)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, DS.screenPadding)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .pressFeedback()
        .contextMenu {
            Button {
                appState.resumeSession(session)
                dismiss()
            } label: {
                Label("Continue Session", systemImage: "play.fill")
            }
            Button(role: .destructive) {
                appState.deleteSession(session.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

#Preview {
    SessionHistoryView()
        .environment(AppState())
}
