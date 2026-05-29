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
    }
}
