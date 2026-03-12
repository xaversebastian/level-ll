// LevelElevenApp.swift — LevelEleven
// v2.0 | 2026-03-12 17:18
// - Lifted AppState to app level (shared between MainTabView + OnboardingView)
// - Onboarding now receives AppState for profile creation
// - Stripped legacy comments, added structured header
//

import SwiftUI

@main
struct LevelElevenApp: App {
    @State private var appState = AppState()
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                MainTabView()
                    .environment(appState)
                    .fullScreenCover(isPresented: $showOnboarding) {
                        OnboardingView()
                            .environment(appState)
                    }

                if showSplash {
                    SplashView {
                        showSplash = false
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
        }
    }
}
