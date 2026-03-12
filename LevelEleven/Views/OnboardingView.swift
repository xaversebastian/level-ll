//
//  OnboardingView.swift
//  LevelEleven
//
//  Version: 1.1  |  2026-03-12
//
//  Erster-Start-Onboarding: 4 Screens in einem PageTabView.
//  1. Welcome – App-Slogan
//  2. Wie es funktioniert – Level-Skala, aktive Dose-Konzept
//  3. Dein Profil – kurze Intro zum Profil-Konzept
//  4. Los geht's – setzt hasCompletedOnboarding = true
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "waveform.path.ecg",
            iconColor: .levelViolet,
            title: "Welcome to Level Eleven",
            subtitle: "Track your intoxication in real time.\nStay aware. Stay safe.",
            detail: nil
        ),
        OnboardingPage(
            icon: "chart.line.uptrend.xyaxis",
            iconColor: .levelTeal,
            title: "How It Works",
            subtitle: "Your current level is calculated from active doses using pharmacokinetic models.",
            detail: "Level 0 = Sober · Level 5–6 = Strong · Level 11 = Maximum\nActive doses decay automatically over time based on half-life."
        ),
        OnboardingPage(
            icon: "person.2.fill",
            iconColor: .levelOrange,
            title: "Profiles & Tolerance",
            subtitle: "Each profile stores weight, age, sex, ADHD status, and substance tolerances.",
            detail: "Dose recommendations are personalized per profile. Tolerances decay automatically with abstinence."
        ),
        OnboardingPage(
            icon: "shield.fill",
            iconColor: .orange,
            title: "Important Information",
            subtitle: "Please read before using this app.",
            detail: """
                EN: This app is for harm reduction and educational purposes only. It does not constitute medical advice. All dosage amounts refer to pure active substance – actual substances are rarely pure. Possession and use of controlled substances may be illegal in your country. The developers accept no liability for harm resulting from use of this app.

                DE: Diese App dient ausschließlich zur Schadensminimierung und zu Bildungszwecken. Sie ersetzt keine medizinische Beratung. Alle Mengenangaben beziehen sich auf reinen Wirkstoff. Besitz und Konsum können strafbar sein. Die Entwickler übernehmen keine Haftung.
                """
        ),
        OnboardingPage(
            icon: "checkmark.shield.fill",
            iconColor: .green,
            title: "Ready to Go",
            subtitle: "Your default profiles are set up.\nYou can edit them anytime in the Profiles tab.",
            detail: nil
        )
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { idx in
                    pageView(pages[idx]).tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .ignoresSafeArea()

            // Bottom Controls
            VStack(spacing: 16) {
                if currentPage < pages.count - 1 {
                    Button {
                        withAnimation { currentPage += 1 }
                    } label: {
                        Text("Next")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.accent, in: RoundedRectangle(cornerRadius: 16))
                            .foregroundStyle(.white)
                    }

                    Button("Skip") { finishOnboarding() }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Button {
                        finishOnboarding()
                    } label: {
                        Text("Get Started")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.accent, in: RoundedRectangle(cornerRadius: 16))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .background(Color(hex: "080C16").ignoresSafeArea())
        .foregroundStyle(.white)
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(page.iconColor.opacity(0.15))
                    .frame(width: 120, height: 120)
                Image(systemName: page.icon)
                    .font(.system(size: 52, weight: .light))
                    .foregroundStyle(page.iconColor)
            }

            VStack(spacing: 16) {
                Text(page.title)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)

                if let detail = page.detail {
                    Text(detail)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color(white: 0.5))
                        .padding(.horizontal, 8)
                        .padding(12)
                        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 24)

            Spacer()
            Spacer() // Extra space for bottom controls
        }
    }

    private func finishOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        dismiss()
    }
}

private struct OnboardingPage {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let detail: String?
}

#Preview {
    OnboardingView()
}
