// LevelElevenWidgetBundle.swift — LevelElevenWidget
// v2.0 | 2026-03-12 17:18
// - Widget extension entry point registering all widgets and live activities
// - Stripped legacy comments, added structured header
//

import WidgetKit
import SwiftUI

@main
struct LevelElevenWidgetBundle: WidgetBundle {
    var body: some Widget {
        BallerLiveActivityWidget()
    }
}
