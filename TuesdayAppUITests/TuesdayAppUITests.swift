import XCTest

final class TuesdayAppUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testDashboardAndPhotoDeviceInventoryWizardFlow() throws {
        let app = XCUIApplication()
        app.launchArguments.append("--uitesting-reset")
        app.launchArguments.append("--uitesting-mock-gemini")
        app.launch()

        let summaryTitle = app.staticTexts["fleet_summary_title"]
        XCTAssertTrue(summaryTitle.waitForExistence(timeout: 8.0))

        // Verify section header says DEVICES
        let devicesHeader = app.staticTexts["devices_section_header"]
        XCTAssertTrue(devicesHeader.waitForExistence(timeout: 5.0))
        XCTAssertTrue(devicesHeader.label.contains("DEVICES"))

        // Navigate to Add Device screen (Photo Inventory Wizard)
        let addDeviceButton = app.buttons["navigate_add_device_button"]
        XCTAssertTrue(addDeviceButton.waitForExistence(timeout: 5.0))
        addDeviceButton.tap()

        let wizardTitle = app.staticTexts["photo_wizard_title"]
        XCTAssertTrue(wizardTitle.waitForExistence(timeout: 5.0))

        // Step 1: Capture sample router photo
        let sampleRouterButton = app.buttons["wizard_sample_router_button"]
        XCTAssertTrue(sampleRouterButton.waitForExistence(timeout: 5.0))
        sampleRouterButton.tap()

        // Step 2: Verify Gemini AI progressive narrowing question appears
        let narrowingQuestion = app.staticTexts["wizard_narrowing_question_label"]
        XCTAssertTrue(narrowingQuestion.waitForExistence(timeout: 6.0))

        // Enter a Model identifier clue and refine
        let clueInput = app.textFields["wizard_clue_input_field"]
        XCTAssertTrue(clueInput.waitForExistence(timeout: 5.0))
        clueInput.tap()
        clueInput.typeText("UCG-Ultra")

        let refineButton = app.buttons["wizard_refine_clue_button"]
        XCTAssertTrue(refineButton.waitForExistence(timeout: 5.0))
        refineButton.tap()

        // Confirm top candidate match
        let confirmCandidateButton = app.buttons["confirm_candidate_button_0"]
        XCTAssertTrue(confirmCandidateButton.waitForExistence(timeout: 5.0))
        confirmCandidateButton.tap()

        // Verify newly discovered device appears on the DEVICES dashboard
        let newDeviceText = app.staticTexts["unifi-ucg-ultra.local"]
        XCTAssertTrue(newDeviceText.waitForExistence(timeout: 5.0))
    }
}
