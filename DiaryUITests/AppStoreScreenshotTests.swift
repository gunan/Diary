import XCTest

final class AppStoreScreenshotTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCaptureAppStoreScreenshots() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-reset-store", "-seed-sample-data"]
        app.launch()

        XCTAssertTrue(app.navigationBars["Trackers"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Mood Tracker"].waitForExistence(timeout: 8))
        try capture("01-trackers", label: "Tracker list")

        app.staticTexts["Mood Tracker"].tap()
        XCTAssertTrue(app.navigationBars["Mood Tracker"].waitForExistence(timeout: 8))
        try capture("02-tracker-detail", label: "Tracker detail")

        app.buttons["New Entry"].tap()
        XCTAssertTrue(app.navigationBars["New Entry"].waitForExistence(timeout: 8))
        try capture("03-new-entry", label: "New entry form")

        let ratingField = app.textFields["entry-number-rating"]
        XCTAssertTrue(ratingField.waitForExistence(timeout: 8))
        ratingField.tap()
        ratingField.typeText("9")
        app.buttons["save-entry-button"].tap()
        XCTAssertTrue(app.navigationBars["Mood Tracker"].waitForExistence(timeout: 8))
        let latestEntryRow = app.buttons["entry-row"].firstMatch
        XCTAssertTrue(latestEntryRow.waitForExistence(timeout: 8))
        XCTAssertTrue(latestEntryRow.label.contains("rating: 9.0"))
        try capture("04-entries", label: "Entries")

        latestEntryRow.tap()
        XCTAssertTrue(app.navigationBars["Entry"].waitForExistence(timeout: 8))
        try capture("05-entry-detail", label: "Entry detail")

        tapBack(in: app)
        XCTAssertTrue(app.navigationBars["Mood Tracker"].waitForExistence(timeout: 8))
        app.buttons["Insights"].tap()
        XCTAssertTrue(app.navigationBars["Insights"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.switches["chart-field-rating"].waitForExistence(timeout: 8))
        try capture("06-insights", label: "Insights")

        tapBack(in: app)
        XCTAssertTrue(app.navigationBars["Mood Tracker"].waitForExistence(timeout: 8))
        app.buttons["edit-tracker-button"].tap()
        XCTAssertTrue(app.navigationBars["Edit Tracker"].waitForExistence(timeout: 8))
        try capture("07-customize-tracker", label: "Customize tracker")
    }

    private func capture(_ filename: String, label: String) throws {
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.7))
        let screenshot = XCUIScreen.main.screenshot()

        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "\(filename)-\(label)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func tapBack(in app: XCUIApplication) {
        let navigationBar = app.navigationBars.element(boundBy: 0)
        if navigationBar.buttons["Back"].exists {
            navigationBar.buttons["Back"].tap()
        } else {
            navigationBar.buttons.element(boundBy: 0).tap()
        }
    }
}
