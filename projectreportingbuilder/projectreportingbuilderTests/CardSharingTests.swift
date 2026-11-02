import AppKit
import SwiftUI
import Testing
@testable import projectreportingbuilder

@MainActor
struct CardSharingTests {
    @Test func textPreservesSourceAndContext() throws {
        let summary = SnippetCard.summary(.init(projectName: "Atlas 🚀", updateNotes: "First\n\nSecond"))
        #expect(try CardSharingService.plainText(for: summary) == "Atlas 🚀\n\nFirst\n\nSecond")
        let card = SnippetCard.kpi(.milestones(.init(completedInput: "3", totalInput: "8"), note: "Pilot done.\nRollout remains."))
        let text = try CardSharingService.plainText(for: card)
        #expect(text.contains("37.5%"))
        #expect(text.contains("Calculated from milestones"))
        #expect(text.contains("3 of 8 milestones completed"))
        #expect(text.hasSuffix("Pilot done.\nRollout remains."))
    }

    @Test(arguments: ["0", "100", "62.5"])
    func selfReportedText(input: String) throws {
        let text = try CardSharingService.plainText(for: .kpi(.estimate(.init(input: input))))
        #expect(text.contains("\(input)%"))
        #expect(text.contains("Self-reported"))
        #expect(!text.contains("milestones"))
    }

    @Test func clipboardHasReadableAndFormattedRepresentations() throws {
        let board = NSPasteboard.withUniqueName()
        defer { board.releaseGlobally() }
        let card = SnippetCard.summary(.init(projectName: "Atlas", updateNotes: "Ready\nTo share"))
        try CardSharingService.copy(card, colorScheme: .light, to: board)
        #expect(board.string(forType: .string) == "Atlas\n\nReady\nTo share")
        let rtf = try #require(board.data(forType: .rtf))
        let decoded = try NSAttributedString(data: rtf, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil)
        #expect(decoded.string == board.string(forType: .string))
        #expect(NSBitmapImageRep(data: try #require(board.data(forType: .png))) != nil)
    }

    @Test func failuresDoNotReplaceClipboard() throws {
        let board = NSPasteboard.withUniqueName()
        defer { board.releaseGlobally() }
        board.setString("Keep this", forType: .string)
        let invalid = SnippetCard.kpi(.estimate(.init(input: "101")))
        #expect(throws: (any Error).self) { try CardSharingService.copy(invalid, colorScheme: .light, to: board) }
        #expect(board.string(forType: .string) == "Keep this")
        let corrupt = SnippetCard.image(.init(image: .init(filename: "broken.png", data: Data([0]))))
        #expect(throws: (any Error).self) { try CardSharingService.pngData(for: corrupt, colorScheme: .light) }
        let missingDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("card.png")
        #expect(throws: (any Error).self) { try CardSharingService.writePNG(Data([0]), to: missingDirectory) }
    }

    @Test func pngPreservesContentSizeAndAppearance() throws {
        let bitmap = try #require(NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 80, pixelsHigh: 40, bitsPerSample: 8, samplesPerPixel: 3, hasAlpha: false, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0))
        for y in 0..<40 { for x in 0..<80 { bitmap.setColor(NSColor(deviceRed: 0.1, green: 0.4, blue: 0.9, alpha: 1), atX: x, y: y) } }
        let imageData = try #require(bitmap.representation(using: .png, properties: [:]))
        Attachment.record(imageData, named: "source-image.png")
        let cards: [SnippetCard] = [
            .summary(.init(projectName: "Atlas", updateNotes: String(repeating: "Detailed update\n", count: 30))),
            .kpi(.milestones(.init(completedInput: "3", totalInput: "8"), note: "Pilot complete.\nRollout remains.")),
            .image(.init(image: .init(filename: "blue-wide.png", data: imageData)))
        ]
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("CardSharing-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        for (index, card) in cards.enumerated() {
            var light: Data?
            for scheme in [ColorScheme.light, .dark] {
                let data = try CardSharingService.pngData(for: card, colorScheme: scheme)
                Attachment.record(data, named: "\(index)-\(scheme == .light ? "light" : "dark").png")
                let rep = try #require(NSBitmapImageRep(data: data))
                #expect(rep.pixelsWide == 1280)
                #expect(rep.pixelsHigh > 100)
                if index == 2 {
                    let center = try #require(rep.colorAt(x: rep.pixelsWide / 2, y: rep.pixelsHigh / 2)?.usingColorSpace(.deviceRGB))
                    #expect(center.blueComponent > 0.7)
                    #expect(center.redComponent < 0.3)
                }
                if index == 0 { #expect(rep.pixelsHigh > 900) }
                if scheme == .light { light = data } else { #expect(data != light) }
                try CardSharingService.writePNG(data, to: folder.appendingPathComponent("\(index)-\(scheme == .light ? "light" : "dark").png"))
            }
        }
    }
}
