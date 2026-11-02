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
        clickInput(update)
        update.typeText("Pilot completed.\nNext: wider release.")
        XCTAssertTrue(generate.isEnabled)
        generate.click()
        XCTAssertTrue(app.staticTexts["generatedProjectName"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["generatedPercentage"].exists)
        XCTAssertEqual(app.staticTexts["generatedCardCount"].value as? String, "1 card · Preview only")

        clickInput(app.popUpButtons["progressMethod"])
        chooseProgress("Milestone completion", in: app)
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
    func testOptionalPercentageAndMethodSwitching() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        if !app.windows.firstMatch.waitForExistence(timeout: 3) {
            app.typeKey("n", modifierFlags: .command)
        }
        replaceText(in: app.textFields["projectName"], with: "Migration")
        clickInput(app.textViews["projectUpdate"])
        app.textViews["projectUpdate"].typeText("Discovery complete.")
        let generate = app.buttons["generateCards"]
        XCTAssertTrue(generate.isEnabled)

        clickInput(app.popUpButtons["progressMethod"])
        chooseProgress("Completion percentage", in: app)
        XCTAssertFalse(generate.isEnabled)
        replaceText(in: app.textFields["estimatedPercentage"], with: "101")
        XCTAssertFalse(generate.isEnabled)
        replaceText(in: app.textFields["estimatedPercentage"], with: "62.5")
        generate.click()
        XCTAssertEqual(app.staticTexts["generatedPercentage"].value as? String, "62.5%")
        XCTAssertEqual(app.staticTexts["generatedProgressSource"].value as? String, "Manual estimate")
        XCTAssertFalse(app.staticTexts["generatedMilestoneCounts"].exists)

        clickInput(app.popUpButtons["progressMethod"])
        chooseProgress("Milestone completion", in: app)
        replaceText(in: app.textFields["completedMilestones"], with: "2")
        replaceText(in: app.textFields["totalMilestones"], with: "8")
        generate.click()
        XCTAssertEqual(app.staticTexts["generatedPercentage"].value as? String, "25%")
        XCTAssertEqual(app.staticTexts["generatedProgressSource"].value as? String, "Calculated from milestones")

        clickInput(app.popUpButtons["progressMethod"])
        chooseProgress("Completion percentage", in: app)
        XCTAssertEqual(app.textFields["estimatedPercentage"].value as? String, "62.5")
        clickInput(app.popUpButtons["progressMethod"])
        chooseProgress("Milestone completion", in: app)
        XCTAssertEqual(app.textFields["completedMilestones"].value as? String, "2")
        XCTAssertEqual(app.textFields["totalMilestones"].value as? String, "8")
        clickInput(app.popUpButtons["progressMethod"])
        chooseProgress("No progress metric", in: app)
        XCTAssertTrue(generate.isEnabled)
        generate.click()
        XCTAssertFalse(app.staticTexts["generatedPercentage"].exists)
        XCTAssertTrue(app.staticTexts["generatedProjectName"].exists)
    }

    @MainActor
    private func replaceText(in field: XCUIElement, with text: String) {
        clickInput(field)
        field.typeKey("a", modifierFlags: .command)
        field.typeText(text)
    }
}

extension XCTestCase {
    @MainActor
    func clickInput(_ element: XCUIElement) {
        let app = XCUIApplication()
        app.activate()
        let scroll = app.scrollViews["inputForm"]
        XCTAssertTrue(element.waitForExistence(timeout: 5))
        // Scroll from the form margin so the nested text editor cannot consume it.
        for _ in 0..<12 {
            let visible = scroll.frame.insetBy(dx: 0, dy: 8)
            if visible.contains(element.frame) { break }
            let delta: CGFloat = element.frame.midY > visible.midY ? -150 : 150
            scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.5))
                .scroll(byDeltaX: 0, deltaY: delta)
        }
        let hittable = NSPredicate(format: "hittable == true")
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: hittable, object: element)], timeout: 5), .completed)
        element.click()
    }
}

extension XCTestCase {
    @MainActor
    func chooseProgress(_ title: String, in app: XCUIApplication) {
        let item = app.menuItems[title]
        XCTAssertTrue(item.waitForExistence(timeout: 5))
        // Avoid XCTest's menu traversal reopening an already-open native popup.
        item.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
    }
}
