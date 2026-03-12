//
//  Theme.swift
//  LevelEleven
//
//  Version: 1.0  |  2026-03-11
//
//  App-weites Farbschema, abgeleitet aus dem lEVEl-Logo.
//  Definiert statische Color-Extensions: levelDarkBlue, levelOrange,
//  levelViolet, levelMagenta, levelTeal, levelGreen.
//  accent = levelViolet (primäre Akzentfarbe),
//  accentHighlight = levelOrange (sekundäre Hervorhebung).
//
//  HINWEIS: Alle Views sollen Color.accent / Color.accentHighlight statt
//  Hardcoded-Farben verwenden, damit Theme-Änderungen zentral greifen.

import SwiftUI

extension Color {
    static let levelDarkBlue = Color(hex: "080C16")
    static let levelOrange = Color(hex: "F5A623")
    static let levelViolet = Color(hex: "6C63FF")
    static let levelMagenta = Color(hex: "FF2D55")
    static let levelTeal = Color(hex: "00D4AA")
    static let levelGreen = Color(hex: "2ECC71")
    
    static let accent = Color.levelViolet
    static let accentHighlight = Color.levelOrange
}
