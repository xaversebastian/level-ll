//
//  Theme.swift
//  LevelEleven
//
//  Version: 1.2  |  2026-03-12
//
//  App-weites Farbschema, abgeleitet aus dem lEVEl-Logo.
//  Gedeckte, erdige Palette – ruhig im aktiven Zustand, klar im Nüchternzustand.
//  Hero-Sektion: dunkles Navy (#0E1220)
//  App-Hintergrund: helles Lavendel-Weiß (#F2F1F8)
//  Cards: reines Weiß (stechen heraus vom Hintergrund)

import SwiftUI

extension Color {
    // MARK: - App Backgrounds
    static let appBackground  = Color(hex: "F2F1F8")   // helles Lavendel-Weiß
    static let heroBackground = Color(hex: "0E1220")   // tiefes Navy für Hero

    // MARK: - Brand Colors
    static let levelDarkBlue  = Color(hex: "0E1220")   // tiefes Navy
    static let levelViolet    = Color(hex: "7268C4")   // gedämpftes Indigo (Primary Accent)
    static let levelOrange    = Color(hex: "C4863C")   // warmes Bernstein
    static let levelMagenta   = Color(hex: "A83B56")   // dunkles Rosé
    static let levelTeal      = Color(hex: "2E9186")   // dunkles Petrol
    static let levelGreen     = Color(hex: "4CAF72")   // Sage-Grün
    static let levelWarm      = Color(hex: "C47A5A")   // Terrakotta (Level 7–8)
    static let levelMauve     = Color(hex: "8B4268")   // Mauve/Pflaume (Level 9–11)

    // MARK: - Semantic Aliases
    static let accent          = Color.levelViolet
    static let accentHighlight = Color.levelOrange
}
