//
//  OnboardingView.swift
//  LevelEleven
//
//  Version: 2.0  |  2026-03-12
//
//  Redesigned first-use onboarding with polished espresso design,
//  custom 11-segment progress indicator, refined typography,
//  and consistent HomeView design language.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "waveform.path.ecg",
            iconColor: .levelCopper,
            title: "Level Eleven",
            subtitle: "Track your intoxication in real time.\nStay aware. Stay safe.",
            detail: nil
        ),
        OnboardingPage(
            icon: "chart.line.uptrend.xyaxis",
            iconColor: .levelTeal,
            title: "How It Works",
            subtitle: "Your level is calculated from active doses using pharmacokinetic models.",
            detail: "Level 0 = Sober · Level 5–6 = Strong · Level 11 = Maximum\nDoses decay automatically based on half-life."
        ),
        OnboardingPage(
            icon: "person.2.fill",
            iconColor: .levelOrange,
            title: "Profiles & Tolerance",
            subtitle: "Each profile stores weight, age, sex, ADHD status, and substance tolerances.",
            detail: "Dose recommendations are personalized per profile.\nTolerances decay automatically with abstinence."
        ),
        OnboardingPage(
            icon: "shield.fill",
            iconColor: .orange,
            title: "Important",
            subtitle: "Please read before using this app.",
            detail: """
                EN: This app is for harm reduction and educational purposes only. It does not constitute medical advice. All dosage amounts refer to pure active substance – actual substances are rarely pure. Possession and use of controlled substances may be illegal in your country. The developers accept no liability for harm resulting from use of this app.

                DE: Diese App dient ausschließlich zur Schadensminimierung und zu Bildungszwecken. Sie ersetzt keine medizinische Beratung. Alle Mengenangaben beziehen sich auf reinen Wirkstoff. Besitz und Konsum können strafbar sein. Die Entwickler übernehmen keine Haftung.
                """
        ),
        OnboardingPage(
            icon: "checkmark.shield.fill",
            iconColor: .levelGreen,
            title: "Ready to Go",
            subtitle: "Your default profiles are set up.\nEdit them anytime in the Profiles tab.",
            detail: nil
        )
    ]

    var body: some View {
        ZStack {
            Color.heroBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top branding
                HStack {
                    Text("LEVEL")
                        .font(.system(size: 11, weight: .black))
                        .tracking(3)
                        .foregroundStyle(.white.opacity(0.3))
                    Spacer()
                    Text("\(currentPage + 1) / \(pages.count)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.3))
                }
                .padding(.horizontal, DS.screenPadding)
                .padding(.top, 16)

                // 11-segment progress indicator
                segmentIndicator
                    .padding(.horizontal, DS.screenPadding)
                    .padding(.top, 14)

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { idx in
                        pageView(pages[idx]).tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Bottom controls
                VStack(spacing: 14) {
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        if currentPage < pages.count - 1 {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                currentPage += 1
                            }
                        } else {
                            finishOnboarding()
                        }
                    } label: {
                        Text(currentPage < pages.count - 1 ? "Continue" : "Get Started")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color.accent.gradient, in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.white)
                            .shadow(color: Color.accent.opacity(0.2), radius: 8, y: 3)
                    }

                    if currentPage < pages.count - 1 {
                        Button {
                            finishOnboarding()
                        } label: {
                            Text("Skip")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.35))
                        }
                    }
                }
                .padding(.horizontal, DS.screenPadding)
                .padding(.bottom, 40)
            }
        }
        .foregroundStyle(.white)
    }

    // MARK: - Segment Indicator

    private var segmentIndicator: some View {
        HStack(spacing: 5) {
            ForEach(0..<pages.count, id: \.self) { i in
                Capsule()
                    .fill(i <= currentPage
                          ? segmentColor(i)
                          : Color.white.opacity(0.08))
                    .frame(maxWidth: .infinity)
                    .frame(height: 4)
                    .animation(.easeInOut(duration: 0.25), value: currentPage)
            }
        }
    }

    private func segmentColor(_ i: Int) -> Color {
        switch i {
        case 0:      return Color.levelCopper
        case 1:      return Color.levelTeal
        case 2:      return Color.levelOrange
        case 3:      return .orange
        default:     return Color.levelGreen
        }
    }

    // MARK: - Page View

    private func pageView(_ page: OnboardingPage) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Spacer(minLength: 40)

                // Icon
                ZStack {
                    Circle()
                        .fill(page.iconColor.opacity(0.12))
                        .frame(width: 100, height: 100)
                    Image(systemName: page.icon)
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(page.iconColor)
                }
                .padding(.bottom, 32)

                // Title
                Text(page.title)
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 12)

                // Subtitle
                Text(page.subtitle)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.6))
                    .lineSpacing(4)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                // Detail
                if let detail = page.detail {
                    Text(detail)
                        .font(.caption)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.white.opacity(0.4))
                        .lineSpacing(3)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
                }

                Spacer(minLength: 120)
            }
            .padding(.horizontal, DS.screenPadding)
        }
    }

    // MARK: - Finish

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
