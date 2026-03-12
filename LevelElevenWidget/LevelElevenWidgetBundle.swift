//
//  LevelElevenWidgetBundle.swift
//  LevelElevenWidget
//
//  Version: 1.0  |  2026-03-11
//
//  @main-Einstiegspunkt der Widget-Extension.
//  Registriert alle Widgets und Live Activities des Targets.
//  Aktuell: BallerLiveActivityWidget (Lock Screen + Dynamic Island).
//
//  HINWEIS: Neue Widgets hier in body { … } ergänzen.
//  Datei muss im Target "LevelElevenWidget" sein, nicht im Haupt-App-Target.
//

import WidgetKit
import SwiftUI

@main
struct LevelElevenWidgetBundle: WidgetBundle {
    var body: some Widget {
        BallerLiveActivityWidget()
    }
}
