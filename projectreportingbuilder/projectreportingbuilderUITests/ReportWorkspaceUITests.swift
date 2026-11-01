import XCTest
import XCUIAutomation

final class ReportWorkspaceUITests: XCTestCase {
    @MainActor
    func testGenerationValidationAndSnapshotRefresh() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        // macOS can restore a prior session with all windows closed.
        if !app.windows.firstMatch.waitForExistence(timeout: 3) {
            app.typeKey("n", modifierFlags: .command)
        }
        let generate = app.buttons["generateCards"]
        XCTAssertTrue(generate.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertFalse(generate.isEnabled)
        XCTAssertTrue(app.descendants(matching: .any)["cardsEmptyState"].exists)

        replaceText(in: app.textFields["projectName"], with: "Atlas rollout")
        let update = app.textViews["projectUpdate"]
        update.click()
        update.typeText("Pilot completed.\nNext: wider release.")
        replaceText(in: app.textFields["completedMilestones"], with: "11")
        replaceText(in: app.textFields["totalMilestones"], with: "10")
        XCTAssertFalse(generate.isEnabled)
        XCTAssertTrue(app.descendants(matching: .any)["metricValidation"].exists)

        replaceText(in: app.textFields["completedMilestones"], with: "3")
        XCTAssertTrue(generate.isEnabled)
        // The primary action must also work without moving focus from the editor.
        app.typeKey(.return, modifierFlags: .command)
        XCTAssertTrue(app.staticTexts["generatedProjectName"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["generatedProjectName"].value as? String, "Atlas rollout")
        XCTAssertEqual(app.staticTexts["generatedUpdate"].value as? String, "Pilot completed.\nNext: wider release.")
        XCTAssertEqual(app.staticTexts["generatedPercentage"].value as? String, "30%")
        XCTAssertEqual(app.staticTexts["generatedMilestoneCounts"].value as? String, "3 of 10 milestones completed")
        XCTAssertFalse(app.images["generatedImage"].exists)

        replaceText(in: app.textFields["completedMilestones"], with: "7")
        XCTAssertTrue(app.descendants(matching: .any)["cardsOutOfDate"].exists)
        XCTAssertEqual(app.staticTexts["generatedPercentage"].value as? String, "30%")

        // Reverting an edit returns to the generated snapshot.
        replaceText(in: app.textFields["completedMilestones"], with: "3")
        XCTAssertFalse(app.descendants(matching: .any)["cardsOutOfDate"].exists)
        replaceText(in: app.textFields["completedMilestones"], with: "7")
        generate.click()
        XCTAssertEqual(app.staticTexts["generatedPercentage"].value as? String, "70%")
        XCTAssertFalse(app.descendants(matching: .any)["cardsOutOfDate"].exists)

        replaceText(in: app.textFields["totalMilestones"], with: "0")
        XCTAssertFalse(generate.isEnabled)
        XCTAssertEqual(app.staticTexts["generatedPercentage"].value as? String, "70%")
        XCTAssertTrue(app.descendants(matching: .any)["cardsOutOfDate"].exists)

        // Both panels should remain usable at the window's supported minimum.
        let window = app.windows.firstMatch
        let corner = window.coordinate(withNormalizedOffset: CGVector(dx: 1, dy: 1))
        corner.click(forDuration: 0.1, thenDragTo: corner.withOffset(CGVector(dx: -250, dy: -170)))
        XCTAssertTrue(generate.isHittable)
        XCTAssertTrue(app.scrollViews["cardPreviewScroll"].exists)

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Reporting workspace after resize"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    private func replaceText(in field: XCUIElement, with text: String) {
        field.click()
        field.typeKey("a", modifierFlags: .command)
        field.typeText(text)
    }
}
