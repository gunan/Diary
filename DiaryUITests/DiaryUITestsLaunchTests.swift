//
//  DiaryUITestsLaunchTests.swift
//  DiaryUITests
//
//  Created by Günhan Gülsoy on 8/9/25.
//

import XCTest

final class DiaryUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-seed-sample-data"]
        app.launch()

        XCTAssertTrue(app.navigationBars["Trackers"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Mood Tracker"].exists)

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
