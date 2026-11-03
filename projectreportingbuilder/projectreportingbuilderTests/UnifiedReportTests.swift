import AppKit
import SwiftUI
import Testing
@testable import projectreportingbuilder

@MainActor
struct UnifiedReportTests {
    @Test func combinedTextSupportsEverySectionCombination() throws {
        let summary = SnippetCard.summary(.init(projectName: "Atlas", updateNotes: "Pilot is ready."))
        let progress = SnippetCard.kpi(.milestones(
            .init(completedInput: "3", totalInput: "4"),
            note: "Validation remains."
        ))
        let image = SnippetCard.image(.init(image: .init(filename: "Roadmap.png", data: try imageData())))

        let summaryOnly = try CardSharingService.reportPlainText(for: [summary])
        #expect(summaryOnly == "Atlas\n\nSummary\nPilot is ready.")

        let withProgress = try CardSharingService.reportPlainText(for: [summary, progress])
        #expect(withProgress.contains("Project progress: 75%"))
        #expect(withProgress.contains("3 of 4 milestones completed"))
        #expect(withProgress.contains("Validation remains."))

        let complete = try CardSharingService.reportPlainText(for: [summary, progress, image])
        #expect(complete.hasPrefix(summaryOnly))
        #expect(complete.hasSuffix("Project image\nRoadmap.png"))
    }

    @Test func combinedClipboardContainsTextRichTextAndPNG() throws {
        let board = NSPasteboard.withUniqueName()
        defer { board.releaseGlobally() }
        let cards: [SnippetCard] = [
            .summary(.init(projectName: "Atlas", updateNotes: "Ready to share")),
            .kpi(.estimate(.init(input: "60"), note: "Delivery remains on track."))
        ]

        try CardSharingService.copyReport(cards, colorScheme: .light, to: board)

        let expectedText = try CardSharingService.reportPlainText(for: cards)
        #expect(board.string(forType: .string) == expectedText)
        let rtf = try #require(board.data(forType: .rtf))
        let decoded = try NSAttributedString(
            data: rtf,
            options: [.documentType: NSAttributedString.DocumentType.rtf],
            documentAttributes: nil
        )
        #expect(decoded.string == board.string(forType: .string))
        #expect(NSBitmapImageRep(data: try #require(board.data(forType: .png))) != nil)
    }

    @Test func combinedPNGIncludesAvailableSectionsInBothAppearances() throws {
        let summary = SnippetCard.summary(.init(projectName: "Atlas", updateNotes: "Pilot is ready."))
        let progress = SnippetCard.kpi(.milestones(.init(completedInput: "3", totalInput: "4"), note: "Validation remains."))
        let image = SnippetCard.image(.init(image: .init(filename: "blue-wide.png", data: try imageData())))
        let combinations = [[summary], [summary, progress], [summary, progress, image]]

        for scheme in [ColorScheme.light, .dark] {
            var previousHeight = 0
            for cards in combinations {
                let data = try CardSharingService.reportPNGData(for: cards, colorScheme: scheme)
                let bitmap = try #require(NSBitmapImageRep(data: data))
                #expect(bitmap.pixelsWide == 1280)
                #expect(bitmap.pixelsHigh > previousHeight)
                previousHeight = bitmap.pixelsHigh
            }
        }
    }

    @Test func combinedPNGPreservesImageAspectRatio() throws {
        let cards: [SnippetCard] = [
            .summary(.init(projectName: "Atlas", updateNotes: "Image verification")),
            .image(.init(image: .init(filename: "blue-wide.png", data: try imageData())))
        ]
        let data = try CardSharingService.reportPNGData(for: cards, colorScheme: .light)
        let bitmap = try #require(NSBitmapImageRep(data: data))
        var bounds: (minX: Int, maxX: Int, minY: Int, maxY: Int)?

        for y in 0..<bitmap.pixelsHigh {
            for x in 0..<bitmap.pixelsWide {
                guard let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB),
                      color.blueComponent > 0.7,
                      color.redComponent < 0.3,
                      color.greenComponent > 0.25,
                      color.greenComponent < 0.55 else { continue }
                if let current = bounds {
                    bounds = (min(current.minX, x), max(current.maxX, x), min(current.minY, y), max(current.maxY, y))
                } else {
                    bounds = (x, x, y, y)
                }
            }
        }

        let imageBounds = try #require(bounds)
        let width = Double(imageBounds.maxX - imageBounds.minX + 1)
        let height = Double(imageBounds.maxY - imageBounds.minY + 1)
        #expect(abs(width / height - 2) < 0.05)
    }

    private func imageData() throws -> Data {
        let bitmap = try #require(NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: 80,
            pixelsHigh: 40,
            bitsPerSample: 8,
            samplesPerPixel: 3,
            hasAlpha: false,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ))
        for y in 0..<40 {
            for x in 0..<80 {
                bitmap.setColor(NSColor(deviceRed: 0.1, green: 0.4, blue: 0.9, alpha: 1), atX: x, y: y)
            }
        }
        return try #require(bitmap.representation(using: .png, properties: [:]))
    }
}
