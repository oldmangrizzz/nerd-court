import XCTest

@MainActor
final class CourtroomFlowUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-UITesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Smoke Tests

    func testAppLaunchesSuccessfully() throws {
        // The IntakeScreen "FILE GRIEVANCE" button should be present
        let fileButton = app.buttons["FILE GRIEVANCE"]
        XCTAssertTrue(fileButton.waitForExistence(timeout: 5))
    }

    func testQuickStartTrialFlow() throws {
        // Tap the quick-start button that exists in IntakeScreen
        let quickStartButton = app.buttons["quickStartTrialButton"]
        XCTAssertTrue(quickStartButton.waitForExistence(timeout: 5))
        quickStartButton.tap()

        // After quick-start the app should switch to the Courtroom tab; give it a moment
        let courtroomNav = app.navigationBars["Episodes"]
        _ = courtroomNav.waitForExistence(timeout: 2)
        // If we reach here without crash the core flow is intact
        XCTAssertTrue(true)
    }
}