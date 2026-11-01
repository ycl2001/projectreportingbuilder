import Foundation

/// A report contains one summary, one KPI, and an optional image card.
/// Payloads retain the original input; presentation supplies empty-state text.
enum SnippetCard {
    case summary(Summary)
    case kpi(KPI)
    case image(ImageContent)

    struct Summary {
        let projectName: String
        let updateNotes: String
    }

    struct KPI {
        let milestones: MilestoneMetric

        var validation: MilestoneMetric.Validation { milestones.validation }
        var progress: Double? { milestones.progress }
        var percentage: Double? { progress.map { $0 * 100 } }

        var completed: Int? {
            guard case let .valid(completed, _) = validation else { return nil }
            return completed
        }

        var total: Int? {
            guard case let .valid(_, total) = validation else { return nil }
            return total
        }
    }

    struct ImageContent {
        let image: ImportedImage

        // Phase 1 has no separate caption field; retain the full filename.
        var caption: String { image.filename }
    }
}
