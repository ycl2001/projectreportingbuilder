import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import projectreportingbuilder

@MainActor
struct ReportStoreTests {
    @Test func saveAndReloadPreservesGeneratedSnapshot() throws {
        try withStore { store in
            var draft = baseDraft(name: "  Apollo  ", update: "Line one\nLine two 🚀")
            draft.progressMethod = .milestones
            draft.milestones = MilestoneMetric(completedInput: " 03 ", totalInput: "10")
            draft.progressNote = "Waiting for final review."
            let generatedCards = ReportBuilder.build(from: draft)

            draft.projectName = "Newer unsaved name"
            draft.projectUpdate = "Newer unsaved notes"

            let date = Date(timeIntervalSince1970: 1_800_000_000)
            let saved = try store.save(cards: generatedCards, createdAt: date)
            let loaded = try #require(store.load(id: saved.id))

            #expect(loaded == saved)
            #expect(loaded.projectName == "  Apollo  ")
            #expect(loaded.projectUpdate == "Line one\nLine two 🚀")
            #expect(loaded.createdAt == date)
            #expect(loaded.progress == .milestones(
                completedInput: " 03 ",
                totalInput: "10",
                note: "Waiting for final review."
            ))
        }
    }

    @Test func persistsAcrossStoreReinitialisation() throws {
        try withRoot { root in
            let firstStore = try ReportStore(rootDirectoryURL: root)
            let saved = try firstStore.save(cards: ReportBuilder.build(from: baseDraft()))

            let reopenedStore = try ReportStore(rootDirectoryURL: root)
            #expect(reopenedStore.list() == [saved])
            #expect(reopenedStore.load(id: saved.id) == saved)
        }
    }

    @Test func listsMultipleReportingDatesNewestFirst() throws {
        try withStore { store in
            let oldest = try store.save(
                cards: ReportBuilder.build(from: baseDraft(name: "Oldest")),
                createdAt: Date(timeIntervalSince1970: 100)
            )
            let newest = try store.save(
                cards: ReportBuilder.build(from: baseDraft(name: "Newest")),
                createdAt: Date(timeIntervalSince1970: 300)
            )
            let middle = try store.save(
                cards: ReportBuilder.build(from: baseDraft(name: "Middle")),
                createdAt: Date(timeIntervalSince1970: 200)
            )

            #expect(store.list().map(\.id) == [newest.id, middle.id, oldest.id])
        }
    }

    @Test func preservesEveryOptionalProgressModeAndNotes() throws {
        try withStore { store in
            let noProgress = try store.save(cards: ReportBuilder.build(from: baseDraft(name: "None")))

            var percentageDraft = baseDraft(name: "Percentage")
            percentageDraft.progressMethod = .percentage
            percentageDraft.estimatedPercentage = PercentageMetric(input: "62.5")
            percentageDraft.progressNote = "Estimate only"
            let percentage = try store.save(cards: ReportBuilder.build(from: percentageDraft))

            var milestoneDraft = baseDraft(name: "Milestones")
            milestoneDraft.progressMethod = .milestones
            milestoneDraft.milestones = MilestoneMetric(completedInput: "7", totalInput: "9")
            milestoneDraft.progressNote = "Two remain"
            let milestones = try store.save(cards: ReportBuilder.build(from: milestoneDraft))

            #expect(noProgress.progress == nil)
            #expect(percentage.progress == .percentage(input: "62.5", note: "Estimate only"))
            #expect(milestones.progress == .milestones(
                completedInput: "7",
                totalInput: "9",
                note: "Two remain"
            ))
        }
    }

    @Test func persistsImageAsSeparateOriginalQualityAsset() throws {
        try withStore { store in
            let imageData = try makePNG()
            var draft = baseDraft()
            draft.image = try ImageImportService.decode(data: imageData, filename: "Roadmap original.png")

            let saved = try store.save(cards: ReportBuilder.build(from: draft))
            let reference = try #require(saved.image)
            let assetURL = store.imagesDirectoryURL.appendingPathComponent(reference.assetFilename)
            let recordURL = store.recordsDirectoryURL
                .appendingPathComponent(saved.id.uuidString)
                .appendingPathExtension("json")

            #expect(try Data(contentsOf: assetURL) == imageData)
            #expect(try Data(contentsOf: recordURL).count < imageData.count + 1_000)
            #expect(try Data(contentsOf: recordURL).range(of: imageData) == nil)

            let duplicate = try store.draftForEditing(id: saved.id)
            #expect(duplicate.projectName == draft.projectName)
            #expect(duplicate.projectUpdate == draft.projectUpdate)
            #expect(duplicate.image?.filename == "Roadmap original.png")
            #expect(duplicate.image?.data == imageData)
        }
    }

    @Test func convertsSavedProgressBackToEditableDraftData() throws {
        try withStore { store in
            var original = baseDraft(name: "Editable", update: "Keep all source text")
            original.progressMethod = .percentage
            original.estimatedPercentage = PercentageMetric(input: "07.50")
            original.progressNote = "Raw explanatory note"
            let saved = try store.save(cards: ReportBuilder.build(from: original))

            let duplicate = try store.draftForEditing(id: saved.id)
            #expect(duplicate.projectName == original.projectName)
            #expect(duplicate.projectUpdate == original.projectUpdate)
            #expect(duplicate.progressMethod == .percentage)
            #expect(duplicate.estimatedPercentage.input == "07.50")
            #expect(duplicate.progressNote == "Raw explanatory note")
        }
    }

    @Test func deletionRemovesOnlyTheSelectedReportAndItsImage() throws {
        try withStore { store in
            let imageData = try makePNG()
            var firstDraft = baseDraft(name: "Delete me")
            firstDraft.image = try ImageImportService.decode(data: imageData, filename: "first.png")
            let first = try store.save(cards: ReportBuilder.build(from: firstDraft))

            var secondDraft = baseDraft(name: "Keep me")
            secondDraft.image = try ImageImportService.decode(data: imageData, filename: "second.png")
            let second = try store.save(cards: ReportBuilder.build(from: secondDraft))

            try store.delete(id: first.id)

            #expect(store.load(id: first.id) == nil)
            #expect(store.load(id: second.id) == second)
            #expect(!FileManager.default.fileExists(atPath: assetURL(for: first, in: store).path))
            #expect(FileManager.default.fileExists(atPath: assetURL(for: second, in: store).path))
        }
    }

    @Test func missingAndCorruptRecordsDoNotHideValidReports() throws {
        try withStore { store in
            let valid = try store.save(cards: ReportBuilder.build(from: baseDraft()))
            let corruptID = UUID()
            let corruptURL = store.recordsDirectoryURL
                .appendingPathComponent(corruptID.uuidString)
                .appendingPathExtension("json")
            try Data("not json".utf8).write(to: corruptURL)

            #expect(store.load(id: UUID()) == nil)
            #expect(store.load(id: corruptID) == nil)
            #expect(store.list() == [valid])
        }
    }

    @Test func missingAndCorruptImageAssetsReturnControlledErrors() throws {
        try withStore { store in
            let imageData = try makePNG()
            var draft = baseDraft()
            draft.image = try ImageImportService.decode(data: imageData, filename: "image.png")

            let missing = try store.save(cards: ReportBuilder.build(from: draft))
            try FileManager.default.removeItem(at: assetURL(for: missing, in: store))
            do {
                _ = try store.draftForEditing(id: missing.id)
                Issue.record("Expected a missing-image error.")
            } catch let error as ReportStore.StoreError {
                #expect(error == .missingImage)
            }

            let corrupt = try store.save(cards: ReportBuilder.build(from: draft))
            try Data("not an image".utf8).write(to: assetURL(for: corrupt, in: store))
            do {
                _ = try store.draftForEditing(id: corrupt.id)
                Issue.record("Expected a corrupt-image error.")
            } catch let error as ReportStore.StoreError {
                #expect(error == .corruptImage)
            }
        }
    }

    @Test func neverOverwritesAnExistingReport() throws {
        try withStore { store in
            let id = UUID()
            let first = try store.save(
                cards: ReportBuilder.build(from: baseDraft(name: "Original")),
                id: id
            )
            do {
                _ = try store.save(
                    cards: ReportBuilder.build(from: baseDraft(name: "Replacement")),
                    id: id
                )
                Issue.record("Expected an existing-report error.")
            } catch let error as ReportStore.StoreError {
                #expect(error == .reportAlreadyExists)
            }
            #expect(store.load(id: id) == first)
        }
    }

    @Test func savedReportLifecycleSupportsRestartOpenDuplicateEditGenerateAndSave() throws {
        try withRoot { root in
            var originalDraft = baseDraft(name: "Lifecycle", update: "Original saved update")
            originalDraft.progressMethod = .milestones
            originalDraft.milestones = MilestoneMetric(completedInput: "4", totalInput: "8")
            originalDraft.progressNote = "Half of the planned milestones are complete."

            let firstStore = try ReportStore(rootDirectoryURL: root)
            let original = try firstStore.save(
                cards: ReportBuilder.build(from: originalDraft),
                createdAt: Date(timeIntervalSince1970: 100)
            )

            let restartedStore = try ReportStore(rootDirectoryURL: root)
            let opened = try restartedStore.snapshotForViewing(id: original.id)
            #expect(opened.report == original)
            #expect(opened.cards.count == 2)
            #expect(opened.imageIssue == nil)

            var duplicate = try restartedStore.draftForEditing(id: original.id)
            duplicate.projectUpdate = "Edited duplicate update"
            duplicate.milestones.completedInput = "6"
            let regeneratedCards = ReportBuilder.build(from: duplicate)
            let duplicatedSave = try restartedStore.save(
                cards: regeneratedCards,
                createdAt: Date(timeIntervalSince1970: 200)
            )

            #expect(restartedStore.list().map(\.id) == [duplicatedSave.id, original.id])
            #expect(restartedStore.load(id: original.id) == original)
            #expect(duplicatedSave.projectUpdate == "Edited duplicate update")
            #expect(duplicatedSave.progress == .milestones(
                completedInput: "6",
                totalInput: "8",
                note: "Half of the planned milestones are complete."
            ))
        }
    }

    @Test func readOnlySnapshotKeepsUsableSectionsWhenImageIsMissing() throws {
        try withStore { store in
            let imageData = try makePNG()
            var draft = baseDraft()
            draft.progressMethod = .percentage
            draft.estimatedPercentage = PercentageMetric(input: "75")
            draft.image = try ImageImportService.decode(data: imageData, filename: "missing.png")
            let saved = try store.save(cards: ReportBuilder.build(from: draft))
            try FileManager.default.removeItem(at: assetURL(for: saved, in: store))

            let snapshot = try store.snapshotForViewing(id: saved.id)
            #expect(snapshot.report == saved)
            #expect(snapshot.cards.count == 2)
            #expect(snapshot.imageIssue == .missingImage)
        }
    }

    private func baseDraft(
        name: String = "Project Atlas",
        update: String = "Delivery remains on track."
    ) -> ReportDraft {
        ReportDraft(projectName: name, projectUpdate: update)
    }

    private func withStore(_ operation: (ReportStore) throws -> Void) throws {
        try withRoot { root in
            try operation(ReportStore(rootDirectoryURL: root))
        }
    }

    private func withRoot(_ operation: (URL) throws -> Void) throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ReportStoreTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try operation(root)
    }

    private func assetURL(for report: SavedReport, in store: ReportStore) -> URL {
        store.imagesDirectoryURL.appendingPathComponent("\(report.id.uuidString).asset")
    }

    private func makePNG() throws -> Data {
        let context = try #require(CGContext(
            data: nil,
            width: 32,
            height: 18,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ))
        context.setFillColor(CGColor(red: 0.1, green: 0.4, blue: 0.8, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 32, height: 18))
        let image = try #require(context.makeImage())
        let data = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(
            data,
            UTType.png.identifier as CFString,
            1,
            nil
        ))
        CGImageDestinationAddImage(destination, image, nil)
        #expect(CGImageDestinationFinalize(destination))
        return data as Data
    }
}
