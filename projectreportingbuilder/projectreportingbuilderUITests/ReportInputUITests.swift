import AppKit
import XCTest
import XCUIAutomation

final class ReportInputUITests: XCTestCase {
    @MainActor
    func testInputAndImageReplacement() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        // macOS can restore a prior session with all windows closed.
        if !app.windows.firstMatch.waitForExistence(timeout: 3) {
            app.typeKey("n", modifierFlags: .command)
        }

        let name = app.textFields["projectName"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        clickInput(name)
        name.typeText("Portal rollout")
        let update = app.textViews["projectUpdate"]
        clickInput(update)
        update.typeText("Delivery is on track.\nNext: pilot release.")
        chooseProgress("Milestones", in: app)
        let completed = app.textFields["completedMilestones"]
        clickInput(completed)
        completed.typeText("3")
        let total = app.textFields["totalMilestones"]
        clickInput(total)
        total.typeText("10")
        XCTAssertEqual(app.staticTexts["milestoneProgress"].value as? String, "30%")

        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let bitmap = try XCTUnwrap(NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: 16, pixelsHigh: 16,
            bitsPerSample: 8, samplesPerPixel: 3, hasAlpha: false,
            isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        ))
        for y in 0..<16 {
            for x in 0..<16 { bitmap.setColor(.systemBlue, atX: x, y: y) }
        }
        let png = directory.appendingPathComponent("project.png")
        let jpeg = directory.appendingPathComponent("replacement.jpg")
        try XCTUnwrap(bitmap.representation(using: .png, properties: [:])).write(to: png)
        try XCTUnwrap(bitmap.representation(using: .jpeg, properties: [:])).write(to: jpeg)

        try selectImage(png, in: app)
        XCTAssertTrue(app.images["imagePreview"].waitForExistence(timeout: 10))
        XCTAssertTrue((app.staticTexts["imageFilename"].value as? String ?? "").contains("project.png"))

        app.buttons["generateCards"].click()
        XCTAssertTrue(app.images["generatedImage"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["generatedImageCaption"].value as? String, "project.png")
        XCTAssertEqual(app.staticTexts["generatedPercentage"].value as? String, "30%")

        try selectImage(jpeg, in: app)
        let replacement = NSPredicate(format: "value CONTAINS %@", "replacement.jpg")
        expectation(for: replacement, evaluatedWith: app.staticTexts["imageFilename"])
        waitForExpectations(timeout: 10)
        XCTAssertTrue(app.images["imagePreview"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["cardsOutOfDate"].exists)
        XCTAssertEqual(app.staticTexts["generatedImageCaption"].value as? String, "project.png")
        app.buttons["generateCards"].click()
        XCTAssertEqual(app.staticTexts["generatedImageCaption"].value as? String, "replacement.jpg")
        XCTAssertFalse(app.descendants(matching: .any)["cardsOutOfDate"].exists)

        // Cancellation must leave both the prior image and text intact.
        clickInput(app.buttons["importImage"])
        let cancel = app.buttons["Cancel"].firstMatch
        XCTAssertTrue(cancel.waitForExistence(timeout: 5))
        cancel.click()
        XCTAssertTrue((app.staticTexts["imageFilename"].value as? String ?? "").contains("replacement.jpg"))
        XCTAssertEqual(name.value as? String, "Portal rollout")
        XCTAssertEqual(update.value as? String, "Delivery is on track.\nNext: pilot release.")

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Imported JPEG preview"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    @MainActor
    private func selectImage(_ url: URL, in app: XCUIApplication) throws {
        let button = app.buttons["importImage"]
        clickInput(button)
        XCTAssertTrue(app.buttons["Cancel"].firstMatch.waitForExistence(timeout: 5))
        app.typeKey("g", modifierFlags: [.command, .shift])
        app.typeKey("a", modifierFlags: .command)
        app.typeText(url.path)
        app.typeKey(.return, modifierFlags: [])
        let importButton = app.buttons["Import"].firstMatch
        XCTAssertTrue(importButton.waitForExistence(timeout: 5))
        importButton.click()
        XCTAssertTrue(app.buttons["Cancel"].firstMatch.waitForNonExistence(timeout: 5), app.debugDescription)
    }
}
