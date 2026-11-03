import Foundation

/// A generated report snapshot. Image bytes are stored separately by `ReportStore`.
nonisolated struct SavedReport: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let projectName: String
    let createdAt: Date
    let projectUpdate: String
    let progress: Progress?
    let image: ImageReference?

    enum Progress: Codable, Equatable, Sendable {
        case percentage(input: String, note: String)
        case milestones(completedInput: String, totalInput: String, note: String)
    }

    struct ImageReference: Codable, Equatable, Sendable {
        /// The original display name selected by the user.
        let filename: String
        /// A store-managed name relative to the report images directory.
        let assetFilename: String
    }
}
