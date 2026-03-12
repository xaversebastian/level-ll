//
//  Theme.swift
//  LevelEleven
//
//  Version: 1.1  |  2026-03-12
//
//  App-weites Farbschema, abgeleitet aus dem lEVEl-Logo.
//  Definiert statische Color-Extensions: levelDarkBlue, levelOrange,
//  levelViolet, levelMagenta, levelTeal, levelGreen.
//  accent = levelViolet (primäre Akzentfarbe),
//  accentHighlight = levelOrange (sekundäre Hervorhebung).
//
//  HINWEIS: Alle Views sollen Color.accent / Color.accentHighlight statt
//  Hardcoded-Farben verwenden, damit Theme-Änderungen zentral greifen.
//
//  Author: Silja & Xaver
//  Created: 2026-01-04
//

import SwiftUI

extension Color {
    static let levelDarkBlue = Color(hex: "080C16")
    static let levelOrange = Color(hex: "C8944A")   // muted amber (was F5A623)
    static let levelViolet = Color(hex: "7B74CC")   // soft violet (was 6C63FF)
    static let levelMagenta = Color(hex: "C4405A")  // muted rose (was FF2D55)
    static let levelTeal = Color(hex: "3DA898")     // calm teal (was 00D4AA)
    static let levelGreen = Color(hex: "5CB87A")    // sage green (was 2ECC71)
    
    static let accent = Color.levelViolet
    static let accentHighlight = Color.levelOrange
}
