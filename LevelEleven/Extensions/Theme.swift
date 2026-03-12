//
//  Theme.swift
//  LevelEleven
//
//  Version: 2.1  |  2026-03-12
//
//  Komplett neues Design System — warm, geerdet, elegant.
//  Inspiration: warme Creme-Töne, Kupfer-Akzent, dunkles Espresso-Hero.
//
//  App-Hintergrund: warmes Creme-Weiß (#FAF8F4)
//  Hero-Sektion:    tiefes warmes Espresso (#1C1208)
//  Primary Accent:  Kupfer (#C4622A) – ersetzt kaltes Indigo
//  Cards:           reines Weiß auf warmem Grund
//
//  Updates v2.1:
//  - Increased shadow opacity from 5% to 10% for better depth
//  - Added pressFeedback view modifier for tactile button response
//  - Shadow radius increased from 10 to 12 for softer shadows
//
import SwiftUI

// MARK: - Color Tokens

extension Color {
    // MARK: Backgrounds
    /// Warmes Creme-Weiß – Haupt-App-Hintergrund
    static let appBackground  = Color(hex: "FAF8F4")
    /// Tiefes warmes Espresso – Hero-Sektion und Onboarding
    static let heroBackground = Color(hex: "1C1208")

    // MARK: Brand / Accent
    /// Warmes Kupfer – Primary Accent (ersetzt kaltes Indigo/Violett)
    static let levelCopper    = Color(hex: "C4622A")
    /// Weiches Bernstein – Secondary Accent
    static let levelAmber     = Color(hex: "D49060")
    /// Warmes Taupe – Grounding / Calm-Kontext (ersetzt kaltes Blaugrau)
    static let levelCalm      = Color(hex: "9E8B7C")

    // MARK: Substance Level Colors (pharmakologisch bedeutsam, erhalten)
    /// Sage-Grün – Sober / Safe
    static let levelGreen     = Color(hex: "4CAF72")
    /// Dunkles Petrol – Stimulantien / Teal
    static let levelTeal      = Color(hex: "2E9186")
    /// Warmes Bernstein – Mittlere Dosen (Level 5–6)
    static let levelOrange    = Color(hex: "C4863C")
    /// Dunkles Rosé – Opioid / Sedativa-Bereich
    static let levelMagenta   = Color(hex: "A83B56")
    /// Terrakotta – Hohe Dosen (Level 7–8)
    static let levelWarm      = Color(hex: "C47A5A")
    /// Mauve/Pflaume – Sehr hohe Dosen (Level 9–11)
    static let levelMauve     = Color(hex: "8B4268")

    // MARK: Semantic Aliases
    /// Primärer Akzent der App = Kupfer
    static let accent          = Color.levelCopper
    /// Sekundärer Akzent = weiches Bernstein
    static let accentHighlight = Color.levelAmber
}

// MARK: - Design System Tokens

/// Zentrale Design-Konstanten für Abstände, Eckenradien und Schatten.
/// Nutzung: DS.cardRadius, DS.shadow, etc.
enum DS {
    // Corner Radii
    static let cardRadius:  CGFloat = 16
    static let heroRadius:  CGFloat = 32
    static let chipRadius:  CGFloat = 10
    static let badgeRadius: CGFloat = 8

    // Padding
    static let cardPadding:  CGFloat = 16
    static let screenPadding: CGFloat = 16

    // Shadows
    static let shadowColor  = Color.black.opacity(0.10)
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
