import Foundation

/// Persists explicit generated-report snapshots as independent records.
@MainActor
final class ReportStore {
    struct ViewSnapshot {
        let report: SavedReport
        let cards: [SnippetCard]
        let imageIssue: StoreError?
    }

    enum StoreError: LocalizedError, Equatable {
        case reportNotFound
        case reportAlreadyExists
        case invalidSnapshot
        case invalidRecord
        case missingImage
        case corruptImage

        var errorDescription: String? {
            switch self {
            case .reportNotFound:
                String(localized: "The saved report could not be found.")
            case .reportAlreadyExists:
                String(localized: "A report with this identifier already exists.")
            case .invalidSnapshot:
                String(localized: "The generated report is not valid and could not be saved.")
            case .invalidRecord:
                String(localized: "The saved report record is damaged or invalid.")
            case .missingImage:
                String(localized: "The saved report image could not be found.")
            case .corruptImage:
                String(localized: "The saved report image is damaged or unsupported.")
            }
        }
    }

    let rootDirectoryURL: URL
    let recordsDirectoryURL: URL
    let imagesDirectoryURL: URL

    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder = JSONDecoder()

    convenience init(fileManager: FileManager = .default) throws {
        let applicationSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let applicationDirectory = applicationSupport.appendingPathComponent(
            Bundle.main.bundleIdentifier ?? "ProjectReportingBuilder",
            isDirectory: true
        )
        try self.init(
            rootDirectoryURL: applicationDirectory.appendingPathComponent("ReportHistory", isDirectory: true),
            fileManager: fileManager
        )
    }

    init(rootDirectoryURL: URL, fileManager: FileManager = .default) throws {
        self.rootDirectoryURL = rootDirectoryURL
        self.recordsDirectoryURL = rootDirectoryURL.appendingPathComponent("Records", isDirectory: true)
        self.imagesDirectoryURL = rootDirectoryURL.appendingPathComponent("Images", isDirectory: true)
        self.fileManager = fileManager

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder

        try fileManager.createDirectory(at: recordsDirectoryURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: imagesDirectoryURL, withIntermediateDirectories: true)
    }

    /// Saves exactly the generated cards currently shown in the preview.
    @discardableResult
    func save(
        cards: [SnippetCard],
        id: UUID = UUID(),
        createdAt: Date = Date()
    ) throws -> SavedReport {
        let recordURL = recordURL(for: id)
        let imageURL = imageURL(for: id)
        guard !fileManager.fileExists(atPath: recordURL.path),
              !fileManager.fileExists(atPath: imageURL.path) else {
            throw StoreError.reportAlreadyExists
        }

        let snapshot = try makeSnapshot(from: cards, id: id, createdAt: createdAt)
        var wroteImage = false

        do {
            if let imageCard = cards.compactMap(\.imageContent).onlyElement {
                try writeWithoutOverwriting(imageCard.image.data, to: imageURL)
                wroteImage = true
            }
            let data = try encoder.encode(snapshot)
            try writeWithoutOverwriting(data, to: recordURL)
            return snapshot
        } catch {
            if wroteImage {
                try? fileManager.removeItem(at: imageURL)
            }
            throw error
        }
    }

    /// Returns every readable record, newest first. One damaged record does not hide the others.
    func list() -> [SavedReport] {
        guard let URLs = try? fileManager.contentsOfDirectory(
            at: recordsDirectoryURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return [] }

        return URLs
            .filter { $0.pathExtension == "json" }
            .compactMap { readRecord(at: $0) }
            .sorted {
                if $0.createdAt == $1.createdAt {
                    return $0.id.uuidString > $1.id.uuidString
                }
                return $0.createdAt > $1.createdAt
            }
    }

    func load(id: UUID) -> SavedReport? {
        readRecord(at: recordURL(for: id), expectedID: id)
    }

    func draftForEditing(id: UUID) throws -> ReportDraft {
        guard let report = load(id: id) else { throw StoreError.reportNotFound }
        return try draft(from: report)
    }

    func draft(from report: SavedReport) throws -> ReportDraft {
        var draft = draftInputs(from: report)

        if let reference = report.image {
            draft.image = try loadImage(for: report, reference: reference)
        }

        return draft
    }

    /// Loads a read-only snapshot while preserving usable report sections if its image asset is unavailable.
    func snapshotForViewing(id: UUID) throws -> ViewSnapshot {
        guard let report = load(id: id) else { throw StoreError.reportNotFound }
        var draft = draftInputs(from: report)
        var imageIssue: StoreError?

        if let reference = report.image {
            do {
                draft.image = try loadImage(for: report, reference: reference)
            } catch let error as StoreError where error == .missingImage || error == .corruptImage {
                imageIssue = error
            }
        }

        return ViewSnapshot(
            report: report,
            cards: ReportBuilder.build(from: draft),
            imageIssue: imageIssue
        )
    }

    private func draftInputs(from report: SavedReport) -> ReportDraft {
        var draft = ReportDraft(projectName: report.projectName, projectUpdate: report.projectUpdate)

        switch report.progress {
        case .none:
            draft.progressMethod = .none
        case .percentage(let input, let note):
            draft.progressMethod = .percentage
            draft.estimatedPercentage = PercentageMetric(input: input)
            draft.progressNote = note
        case .milestones(let completedInput, let totalInput, let note):
            draft.progressMethod = .milestones
            draft.milestones = MilestoneMetric(
                completedInput: completedInput,
                totalInput: totalInput
            )
            draft.progressNote = note
        }

        return draft
    }

    private func loadImage(
        for report: SavedReport,
        reference: SavedReport.ImageReference
    ) throws -> ImportedImage {
        guard reference.assetFilename == assetFilename(for: report.id) else {
            throw StoreError.invalidRecord
        }
        let URL = imagesDirectoryURL.appendingPathComponent(reference.assetFilename, isDirectory: false)
        guard fileManager.fileExists(atPath: URL.path) else { throw StoreError.missingImage }
        let data = try Data(contentsOf: URL)
        do {
            return try ImageImportService.decode(data: data, filename: reference.filename)
        } catch {
            throw StoreError.corruptImage
        }
    }

    func delete(id: UUID) throws {
        let recordURL = recordURL(for: id)
        guard fileManager.fileExists(atPath: recordURL.path) else {
            throw StoreError.reportNotFound
        }
        try fileManager.removeItem(at: recordURL)

        let imageURL = imageURL(for: id)
        if fileManager.fileExists(atPath: imageURL.path) {
            try fileManager.removeItem(at: imageURL)
        }
    }

    private func makeSnapshot(from cards: [SnippetCard], id: UUID, createdAt: Date) throws -> SavedReport {
        let summaries = cards.compactMap(\.summaryContent)
        let progressCards = cards.compactMap(\.progressContent)
        let images = cards.compactMap(\.imageContent)
        guard let summary = summaries.onlyElement,
              progressCards.count <= 1,
              images.count <= 1,
              !summary.projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !summary.updateNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw StoreError.invalidSnapshot
        }

        let progress: SavedReport.Progress?
        switch progressCards.first {
        case .none:
            progress = nil
        case .milestones(let metric, let note):
            guard metric.progress != nil else { throw StoreError.invalidSnapshot }
            progress = .milestones(
                completedInput: metric.completedInput,
                totalInput: metric.totalInput,
                note: note
            )
        case .estimate(let metric, let note):
            guard metric.progress != nil else { throw StoreError.invalidSnapshot }
            progress = .percentage(input: metric.input, note: note)
        }

        let imageReference = images.first.map {
            SavedReport.ImageReference(
                filename: $0.image.filename,
                assetFilename: assetFilename(for: id)
            )
        }
        return SavedReport(
            id: id,
            projectName: summary.projectName,
            createdAt: createdAt,
            projectUpdate: summary.updateNotes,
            progress: progress,
            image: imageReference
        )
    }

    private func readRecord(at URL: URL, expectedID: UUID? = nil) -> SavedReport? {
        guard let data = try? Data(contentsOf: URL),
              let record = try? decoder.decode(SavedReport.self, from: data),
              expectedID.map({ $0 == record.id }) ?? true,
              URL.deletingPathExtension().lastPathComponent == record.id.uuidString,
              !record.projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !record.projectUpdate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              record.image.map({ $0.assetFilename == assetFilename(for: record.id) }) ?? true else {
            return nil
        }
        return record
    }

    private func recordURL(for id: UUID) -> URL {
        recordsDirectoryURL.appendingPathComponent(id.uuidString).appendingPathExtension("json")
    }

    private func imageURL(for id: UUID) -> URL {
        imagesDirectoryURL.appendingPathComponent(assetFilename(for: id))
    }

    private func assetFilename(for id: UUID) -> String {
        "\(id.uuidString).asset"
    }

    /// Publishes a fully written temporary file with a same-directory move that refuses collisions.
    private func writeWithoutOverwriting(_ data: Data, to destinationURL: URL) throws {
        let temporaryURL = destinationURL
            .deletingLastPathComponent()
            .appendingPathComponent(".\(destinationURL.lastPathComponent).\(UUID().uuidString).tmp")
        defer { try? fileManager.removeItem(at: temporaryURL) }
        try data.write(to: temporaryURL, options: .atomic)
        try fileManager.moveItem(at: temporaryURL, to: destinationURL)
    }
}

private extension SnippetCard {
    var summaryContent: Summary? {
        guard case .summary(let summary) = self else { return nil }
        return summary
    }

    var progressContent: KPI? {
        guard case .kpi(let progress) = self else { return nil }
        return progress
    }

    var imageContent: ImageContent? {
        guard case .image(let image) = self else { return nil }
        return image
    }
}

private extension Array {
    var onlyElement: Element? {
        count == 1 ? first : nil
    }
}
