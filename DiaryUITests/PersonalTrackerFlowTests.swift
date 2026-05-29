import XCTest

final class PersonalTrackerFlowTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testSeededTrackerAppearsOnLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-reset-store", "-seed-sample-data"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Mood Tracker"].waitForExistence(timeout: 5))
        app.staticTexts["Mood Tracker"].tap()

        XCTAssertTrue(app.navigationBars["Mood Tracker"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["New Entry"].exists)
        XCTAssertTrue(app.buttons["Insights"].exists)
        XCTAssertTrue(app.buttons["edit-tracker-button"].exists)
    }

    @MainActor
    func testShowsNumericChartControls() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-seed-sample-data"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Mood Tracker"].waitForExistence(timeout: 5))
        app.staticTexts["Mood Tracker"].tap()

        app.buttons["Insights"].tap()

        XCTAssertTrue(app.switches["chart-field-rating"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Summary"].exists)
    }

    @MainActor
    func testCreatesTrackerWithNumberField() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        app.buttons["new-tracker-button"].tap()

        let trackerNameField = app.textFields["tracker-name-field"]
        XCTAssertTrue(trackerNameField.waitForExistence(timeout: 5))
        trackerNameField.tap()
        trackerNameField.typeText("Workout")

        app.buttons["add-field-button"].tap()

        let fieldNameField = app.textFields["field-name-field"]
        XCTAssertTrue(fieldNameField.waitForExistence(timeout: 5))
        fieldNameField.tap()
        fieldNameField.typeText("Distance")

        app.buttons["field-type-number"].tap()
        app.buttons["save-field-button"].tap()
        app.buttons["save-tracker-button"].tap()

        XCTAssertTrue(app.staticTexts["Workout"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testEditsTrackerNameFromDetail() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-seed-sample-data"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Mood Tracker"].waitForExistence(timeout: 5))
        app.staticTexts["Mood Tracker"].tap()
        app.buttons["edit-tracker-button"].tap()

        let trackerNameField = app.textFields["tracker-name-field"]
        XCTAssertTrue(trackerNameField.waitForExistence(timeout: 5))
        trackerNameField.tap()
        trackerNameField.typeText(" Updated")

        app.buttons["save-tracker-button"].tap()

        XCTAssertTrue(app.navigationBars["Mood Tracker Updated"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testCreatesEntryAndShowsDetail() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-seed-sample-data"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Mood Tracker"].waitForExistence(timeout: 5))
        app.staticTexts["Mood Tracker"].tap()

        app.buttons["New Entry"].tap()

        let ratingField = app.textFields["entry-number-rating"]
        XCTAssertTrue(ratingField.waitForExistence(timeout: 5))
        ratingField.tap()
        ratingField.typeText("9")

        app.buttons["save-entry-button"].tap()

        XCTAssertTrue(app.staticTexts["9.0"].waitForExistence(timeout: 5))
    }
}
