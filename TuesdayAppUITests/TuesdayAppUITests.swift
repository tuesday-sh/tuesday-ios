import XCTest

final class TuesdayAppUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testDayZeroWelcomeSeedsForestAndNavigatesAllTabs() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting-reset", "--uitesting-mock-gemini"]
        app.launch()

        // 1. Verify Day-0 TopAppBar & WelcomeCard
        XCTAssertTrue(app.staticTexts["tuesday.sh"].waitForExistence(timeout: 8))
        let seedBtn = app.buttons["ui:slot:enable-demo-cta"]
        XCTAssertTrue(seedBtn.waitForExistence(timeout: 5), "Expected 'seed Forest fleet' button on Day-0 launch")

        // 2. Seed Forest Fleet (12 devices)
        seedBtn.tap()
        XCTAssertTrue(app.staticTexts["NETWORK HARDWARE"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["UniFi Dream Machine Pro"].waitForExistence(timeout: 5))

        // 3. Switch across all 5 main tabs
        app.buttons["ui:slot:nav-tab-bulletins"].tap()
        XCTAssertTrue(app.staticTexts["BULLETIN"].waitForExistence(timeout: 5))

        app.buttons["ui:slot:nav-tab-timeline"].tap()
        XCTAssertTrue(app.staticTexts["OPERATIONAL LIFESPAN & EOL"].waitForExistence(timeout: 5))

        app.buttons["ui:slot:nav-tab-checkup"].tap()
        XCTAssertTrue(app.staticTexts["R2 QUARTERLY AUDIT PILLARS"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["PILLAR 1"].waitForExistence(timeout: 5))

        app.buttons["ui:slot:nav-tab-account"].tap()
        let subRow = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Subscription & Plan")).firstMatch
        XCTAssertTrue(subRow.waitForExistence(timeout: 5))

        // Scroll if needed so footer rows are visible on compact iPhones
        let privacyRow = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Privacy Policy")).firstMatch
        if !privacyRow.waitForExistence(timeout: 2) {
            app.swipeUp()
        }
        XCTAssertTrue(privacyRow.waitForExistence(timeout: 5))

        // 4. Open Ordinal Spine & Reference Guide from Settings
        let refRow = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Ordinal Spine & Reference Guide")).firstMatch
        if !refRow.exists || !refRow.isHittable {
            app.swipeDown()
        }
        XCTAssertTrue(refRow.waitForExistence(timeout: 5))
        refRow.tap()
        XCTAssertTrue(app.staticTexts["SureThingNet Categories (Scale C1 → C8)"].waitForExistence(timeout: 5))
        app.buttons["ui:action:closeReferenceGuide"].firstMatch.tap()

        // 5. Switch back to My Net and open Add Device Offline Gold Search
        app.buttons["ui:slot:nav-tab-status"].tap()
        let addBtn = app.buttons["ui:action:openAddDevice"]
        XCTAssertTrue(addBtn.waitForExistence(timeout: 5))
        addBtn.tap()

        XCTAssertTrue(app.staticTexts["SHARED HARDWARE CLUES (OFFLINE GOLD INDEX)"].waitForExistence(timeout: 5))
        app.buttons["ui:action:cancelAddDevice"].firstMatch.tap()
    }
}
