//
//  DiaryUITests.swift
//  DiaryUITests
//
//  Created by Günhan Gülsoy on 8/9/25.
//

import XCTest

final class DiaryUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchesTrackerListWithSeededData() throws {
        let app = seededApp()
        app.launch()

        XCTAssertTrue(app.navigationBars["Trackers"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Mood Tracker"].exists)
        XCTAssertTrue(app.buttons["new-tracker-button"].exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                seededApp().launch()
            }
        }
    }

    private func seededApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-seed-sample-data"]
        return app
    }
}
