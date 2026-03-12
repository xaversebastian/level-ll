//
//  LevelElevenApp.swift
//  LevelEleven
//
//  Version: 1.0  |  2026-03-11
//
//  App-Einstiegspunkt. Startet die App und rendert MainTabView als Root-View.
//  @main markiert diese Datei als Swift-App-Entry (kein AppDelegate nötig).
//  AppState wird in MainTabView als @State erstellt und per @Environment injiziert.

import SwiftUI

@main
struct LevelElevenApp: App {
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .fullScreenCover(isPresented: $showOnboarding) {
                    OnboardingView()
                }
        }
    }
}
