// Theme.swift — LevelEleven
// v4.0 | 2026-03-12 23:54
// - Adaptive light/dark mode using brand palette
// - Light: cream background (#FAF8F4), dark hero (#1C1208)
// - Dark: espresso background (#1C1208), elevated surfaces (#2A1F14)
//
import SwiftUI

// MARK: - Color Tokens

extension Color {
    // MARK: Backgrounds
    /// Main app background — cream in light, deep espresso in dark
    static let appBackground  = Color.adaptive(light: "FAF8F4", dark: "1C1208")
    /// Hero / elevated section — deep espresso in light, slightly lighter in dark
    static let heroBackground = Color.adaptive(light: "1C1208", dark: "0E0904")
    /// Card / surface background — white in light, warm dark brown in dark
    static let cardBackground = Color.adaptive(light: "FFFFFF", dark: "2A1F14")
    /// Subtle surface for grouped elements
    static let surfaceSecondary = Color.adaptive(light: "F2EDE6", dark: "221811")

    // MARK: Brand / Accent
    /// Warm copper — primary accent
    static let levelCopper    = Color(hex: "C4622A")
    /// Soft amber — secondary accent
    static let levelAmber     = Color(hex: "D49060")
    /// Warm taupe — grounding / calm context
    static let levelCalm      = Color.adaptive(light: "9E8B7C", dark: "B8A99A")

    // MARK: Substance Level Colors
    /// Sage green — sober / safe
    static let levelGreen     = Color(hex: "4CAF72")
    /// Dark teal — stimulants
    static let levelTeal      = Color(hex: "2E9186")
    /// Warm amber — medium doses (level 5–6)
    static let levelOrange    = Color(hex: "C4863C")
    /// Dark rosé — opioid / sedative range
    static let levelMagenta   = Color(hex: "A83B56")
    /// Terracotta — high doses (level 7–8)
    static let levelWarm      = Color(hex: "C47A5A")
    /// Mauve/plum — very high doses (level 9–11)
    static let levelMauve     = Color(hex: "8B4268")

    // MARK: Semantic Aliases
    /// Primary app accent = copper
    static let accent          = Color.levelCopper
    /// Secondary accent = soft amber
    static let accentHighlight = Color.levelAmber
}

// MARK: - Design System Tokens

enum DS {
    // Corner Radii
    static let cardRadius:  CGFloat = 16
    static let heroRadius:  CGFloat = 32
    static let chipRadius:  CGFloat = 10
    static let badgeRadius: CGFloat = 8

    // Padding
    static let cardPadding:  CGFloat = 16
    static let screenPadding: CGFloat = 16

    // Shadows — adaptive: subtle in light, near-invisible in dark
    static let shadowColor  = Color.adaptive(light: "000000", dark: "000000").opacity(0.10)
    static let shadowRadius: CGFloat = 12
    static let shadowY:      CGFloat = 4

    // Subtle border
    static let borderOpacity: Double = 0.1
}

// MARK: - View Modifiers

extension View {
    /// Adds subtle press feedback animation for interactive elements
    func pressFeedback() -> some View {
        self.buttonStyle(PressFeedbackButtonStyle())
    }
}

struct PressFeedbackButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
