//
//  LevelElevenUITestsLaunchTests.swift
//  LevelElevenUITests
//
//  Version: 1.0  |  2026-03-11
//
//  Launch-Screenshot-Test für alle UI-Konfigurationen (Light/Dark/Sprachvarianten).
//  runsForEachTargetApplicationUIConfiguration = true sorgt dafür, dass
//  der Test einmal pro App-Konfiguration ausgeführt wird.
//  testLaunch() startet die App und macht einen Screenshot (keepAlways).
//
//  HINWEIS: Screenshots werden im Xcode-Test-Reporter gespeichert.
//  Nützlich für automatische Regression von Launch-Screens nach UI-Änderungen.
//
//  Author: Xaver Freytag
//  Created: 2026-01-04
//

import XCTest

final class LevelElevenUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
