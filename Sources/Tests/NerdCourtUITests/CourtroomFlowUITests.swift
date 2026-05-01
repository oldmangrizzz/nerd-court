import XCTest

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

    // MARK: - Grievance Submission Flow

    func testSubmitGrievanceAndWatchTrial() throws {
        // Navigate to submit grievance screen
        let submitButton = app.buttons["submitGrievanceButton"]
        XCTAssertTrue(submitButton.waitForExistence(timeout: 5))
        submitButton.tap()

        // Fill in grievance details
        let plaintiffField = app.textFields["plaintiffTextField"]
        XCTAssertTrue(plaintiffField.waitForExistence(timeout: 2))
        plaintiffField.tap()
        plaintiffField.typeText("Batman")

        let defendantField = app.textFields["defendantTextField"]
        defendantField.tap()
        defendantField.typeText("Superman")

        let grievanceTextView = app.textViews["grievanceTextView"]
        grievanceTextView.tap()
        grievanceTextView.typeText("Batman stole my cape design.")

        // Select franchise
        let franchisePicker = app.pickers["franchisePicker"]
        franchisePicker.pickerWheels.element.adjust(toPickerWheelValue: "DC")

        // Submit
        let submitGrievanceButton = app.buttons["submitGrievanceActionButton"]
        submitGrievanceButton.tap()

        // Wait for trial to start (status changes to inTrial)
        let trialStatusLabel = app.staticTexts["trialStatusLabel"]
        let inTrialPredicate = NSPredicate(format: "label CONTAINS[c] %@", "in trial")
        expectation(for: inTrialPredicate, evaluatedWith: trialStatusLabel, handler: nil)
        waitForExpectations(timeout: 30, handler: nil)

        // Verify courtroom scene appears
        let courtroomScene = app.otherElements["courtroomScene"]
        XCTAssertTrue(courtroomScene.waitForExistence(timeout: 10))

        // Wait for first speech turn to appear
        let firstSpeechBubble = app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH 'speechTurn-'")).firstMatch
        XCTAssertTrue(firstSpeechBubble.waitForExistence(timeout: 60))

        // Let the trial play out (wait for verdict)
        let verdictLabel = app.staticTexts["verdictLabel"]
        XCTAssertTrue(verdictLabel.waitForExistence(timeout: 120))

        // Verify finisher animation plays
        let finisherView = app.otherElements["finisherAnimationView"]
        XCTAssertTrue(finisherView.waitForExistence(timeout: 10))
    }

    func testDeadpoolInterjectionDuringTrial() throws {
        // Start a trial quickly (use a pre-seeded grievance or fast-track)
        app.buttons["quickStartTrialButton"].tap()

        // Wait for Deadpool's speech turn (identified by speaker label)
        let deadpoolTurn = app.staticTexts.matching(NSPredicate(format: "identifier CONTAINS 'speaker-deadpool'")).firstMatch
        XCTAssertTrue(deadpoolTurn.waitForExistence(timeout: 60))

        // Verify glitch effect is present (accessibility identifier for glitch overlay)
        let glitchOverlay = app.otherElements["glitchOverlay"]
        XCTAssertTrue(glitchOverlay.exists)
    }

    func testVerdictAndFinisherAnimation() throws {
        // Navigate to a completed episode (assume there's a library)
        app.tabBars.buttons["Library"].tap()
        let firstEpisodeCell = app.cells.element(boundBy: 0)
        XCTAssertTrue(firstEpisodeCell.waitForExistence(timeout: 5))
        firstEpisodeCell.tap()

        // Verify verdict is displayed
        let verdictText = app.staticTexts["verdictLabel"]
        XCTAssertTrue(verdictText.exists)

        // Tap replay finisher button
        app.buttons["replayFinisherButton"].tap()

        // Wait for finisher animation to complete (or at least start)
        let finisherView = app.otherElements["finisherAnimationView"]
        XCTAssertTrue(finisherView.waitForExistence(timeout: 5))

        // Verify finisher type label matches expected
        let finisherTypeLabel = app.staticTexts["finisherTypeLabel"]
        XCTAssertTrue(finisherTypeLabel.exists)
        let validFinishers = ["crowbarBeatdown", "lazarusPitDunking", "deadpoolShooting", "characterMorph", "gavelOfDoom"]
        XCTAssertTrue(validFinishers.contains(finisherTypeLabel.label))
    }

    func testErrorStateWhenBackendFails() throws {
        // Simulate network failure by setting launch argument
        app.launchArguments.append("-forceNetworkError")
        app.terminate()
        app.launch()

        // Try to submit a grievance
        app.buttons["submitGrievanceButton"].tap()
        let plaintiffField = app.textFields["plaintiffTextField"]
        plaintiffField.tap()
        plaintiffField.typeText("Test")
        let defendantField = app.textFields["defendantTextField"]
        defendantField.tap()
        defendantField.typeText("Test")
        let grievanceTextView = app.textViews["grievanceTextView"]
        grievanceTextView.tap()
        grievanceTextView.typeText("Test")
        app.buttons["submitGrievanceActionButton"].tap()

        // Expect error alert
        let errorAlert = app.alerts["Error"]
        XCTAssertTrue(errorAlert.waitForExistence(timeout: 10))
        errorAlert.buttons["OK"].tap()

        // Verify status shows error
        let statusLabel = app.staticTexts["trialStatusLabel"]
        XCTAssertTrue(statusLabel.label.contains("error"))
    }

    func testGuestCharacterAppearsInTrial() throws {
        // Start a trial that includes a guest character (e.g., from a specific franchise)
        app.buttons["startTrialWithGuestButton"].tap()

        // Wait for a speech turn from a guest speaker
        let guestTurn = app.staticTexts.matching(NSPredicate(format: "identifier CONTAINS 'speaker-guest'")).firstMatch
        XCTAssertTrue(guestTurn.waitForExistence(timeout: 60))

        // Verify guest name is displayed
        let guestNameLabel = app.staticTexts["guestNameLabel"]
        XCTAssertTrue(guestNameLabel.exists)
        XCTAssertFalse(guestNameLabel.label.isEmpty)
    }

    func testCinematicFrameChangesDuringTrial() throws {
        app.buttons["quickStartTrialButton"].tap()

        // Wait for at least two speech turns to compare camera angles
        let speechTurns = app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH 'speechTurn-'"))
        let firstTurn = speechTurns.element(boundBy: 0)
        XCTAssertTrue(firstTurn.waitForExistence(timeout: 30))

        // Wait for second turn
        let secondTurn = speechTurns.element(boundBy: 1)
        XCTAssertTrue(secondTurn.waitForExistence(timeout: 30))

        // Verify that the camera angle label changes (assuming each turn shows its angle)
        let cameraAngleLabel = app.staticTexts["cameraAngleLabel"]
        let initialAngle = cameraAngleLabel.label
        // Wait for angle to change
        let angleChangedPredicate = NSPredicate(format: "label != %@", initialAngle)
        expectation(for: angleChangedPredicate, evaluatedWith: cameraAngleLabel, handler: nil)
        waitForExpectations(timeout: 30, handler: nil)
    }
}