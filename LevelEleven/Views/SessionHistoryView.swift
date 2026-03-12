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
            Group {
                if appState.sessionHistory.isEmpty {
                    emptyState
                } else {
                    sessionList
                }
            }
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
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No Past Sessions")
                .font(.headline)
            Text("When you end a Baller Mode session,\nit will appear here.")
                .multilineTextAlignment(.center)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(40)
    }
    
    private var sessionList: some View {
        List {
            ForEach(filteredHistory) { session in
                Button {
                    selectedSession = session
                } label: {
                    sessionRow(session)
                }
                .foregroundStyle(.primary)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        appState.deleteSession(session.id)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        appState.resumeSession(session)
                        dismiss()
                    } label: {
                        Label("Continue", systemImage: "play.fill")
                    }
                    .tint(Color.accent)
                }
            }
        }
    }
    
    private func sessionRow(_ session: BallerSession) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color.accent.opacity(0.3), .pink.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 44, height: 44)
                Image(systemName: "person.3.fill")
                    .font(.body)
                    .foregroundStyle(Color.accent)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(session.name)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    Label(session.dateFormatted, systemImage: "calendar")
                    Label(session.durationFormatted, systemImage: "clock")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(session.allParticipantIds.count)")
                    .font(.title3.bold())
                    .foregroundStyle(Color.accent)
                Text("Participants")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SessionHistoryView()
        .environment(AppState())
}
