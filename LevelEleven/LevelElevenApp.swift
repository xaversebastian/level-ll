//
//  LevelElevenApp.swift
//  LevelEleven
//
//  Version: 1.0  |  2026-03-11
//
//  App-Einstiegspunkt. Startet die App und rendert MainTabView als Root-View.
//  @main markiert diese Datei als Swift-App-Entry (kein AppDelegate nötig).
//  AppState wird in MainTabView als @State erstellt und per @Environment injiziert.
//
//  Author: Silja & Xaver
//  Created: 2026-01-04
//

import SwiftUI

@main
struct LevelElevenApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}
