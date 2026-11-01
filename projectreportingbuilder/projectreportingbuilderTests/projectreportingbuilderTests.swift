import Foundation
import ImageIO
import UniformTypeIdentifiers
import Testing
@testable import projectreportingbuilder

@MainActor
struct ReportInputTests {
    @Test(arguments: [
        ("3", "10", 0.3),
        ("0", "10", 0.0),
        ("10", "10", 1.0),
        ("1", "3", 1.0 / 3.0),
        (" 2 ", " 8 ", 0.25),
        (String(Int.max), String(Int.max), 1.0)
    ])
    func validProgress(completed: String, total: String, expected: Double) throws {
        let metric = MilestoneMetric(completedInput: completed, totalInput: total)
        let progress = try #require(metric.progress)
        #expect(abs(progress - expected) < 0.000001)
    }

    @Test(arguments: [
        ("11", "10", MilestoneMetric.Validation.completedExceedsTotal),
        ("0", "0", .zeroTotal),
        ("1", "0", .zeroTotal),
        ("", "10", .missingInput),
        ("2", "", .missingInput),
        ("  ", "10", .missingInput),
        ("abc", "10", .invalidWholeNumber),
        ("2", "abc", .invalidWholeNumber),
        ("-1", "10", .invalidWholeNumber),
        ("1", "-10", .invalidWholeNumber),
        ("1.5", "10", .invalidWholeNumber),
        ("+1", "10", .invalidWholeNumber),
        ("1,000", "2000", .invalidWholeNumber),
        (String(repeating: "9", count: 30), "10", .numberTooLarge)
    ])
    func invalidProgress(completed: String, total: String, expected: MilestoneMetric.Validation) {
        let metric = MilestoneMetric(completedInput: completed, totalInput: total)
        #expect(metric.validation == expected)
        #expect(metric.progress == nil)
    }

    @Test func draftPreservesRawTextAndRecognizesEmptyInformation() {
        var draft = ReportDraft()
        #expect(!draft.hasProjectInformation)
        draft.projectName = "  Project A  "
        draft.projectUpdate = "Line one\nLine two 🚀"
        #expect(draft.hasProjectInformation)
        draft.milestones.completedInput = "invalid"
        #expect(draft.projectName == "  Project A  ")
        #expect(draft.projectUpdate == "Line one\nLine two 🚀")
        draft.projectUpdate = " \n "
        #expect(!draft.hasProjectInformation)
    }

    @Test(arguments: [UTType.png.identifier, UTType.jpeg.identifier])
    func imageDataSurvivesSourceRemoval(type: String) throws {
        let data = try makeImage(type: type)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try data.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        let imported = try ImageImportService.load(from: url)
        try FileManager.default.removeItem(at: url)
        #expect(imported.data == data)
        #expect(imported.filename == url.lastPathComponent)
        #expect(CGImageSourceCreateWithData(imported.data as CFData, nil) != nil)
    }

    @Test func corruptAndUnsupportedImagesAreRejected() throws {
        #expect(throws: ImageImportService.ImportError.self) {
            try ImageImportService.decode(data: Data("not an image".utf8), filename: "bad.png")
        }
        let gif = try makeImage(type: UTType.gif.identifier)
        #expect(throws: ImageImportService.ImportError.self) {
            try ImageImportService.decode(data: gif, filename: "renamed.png")
        }
    }

    @Test func oversizedImageIsRejected() {
        let data = Data(count: ImageImportService.maximumBytes + 1)
        #expect(throws: ImageImportService.ImportError.self) {
            try ImageImportService.decode(data: data, filename: "large.png")
        }
    }

    private func makeImage(type: String) throws -> Data {
        let context = try #require(CGContext(
            data: nil, width: 8, height: 8, bitsPerComponent: 8,
            bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ))
        context.setFillColor(CGColor(red: 0.2, green: 0.6, blue: 0.8, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        let image = try #require(context.makeImage())
        let data = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(data, type as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, nil)
        #expect(CGImageDestinationFinalize(destination))
        return data as Data
    }
}
