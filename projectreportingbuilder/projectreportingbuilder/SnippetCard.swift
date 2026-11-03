import Foundation

/// A summary with optional progress and image cards. Payloads retain source input.
enum SnippetCard {
    case summary(Summary)
    case kpi(KPI)
    case image(ImageContent)

    struct Summary {
        let projectName: String
        let updateNotes: String
    }

    enum KPI {
        case milestones(MilestoneMetric, note: String = "")
        case estimate(PercentageMetric, note: String = "")

        var note: String {
            switch self {
            case .milestones(_, let note), .estimate(_, let note): note
            }
        }

        var progress: Double? {
            switch self {
            case .milestones(let metric, _): metric.progress
            case .estimate(let metric, _): metric.progress
            }
        }

        var percentage: Double? {
            switch self {
            case .milestones(let metric, _): metric.progress.map { $0 * 100 }
            case .estimate(let metric, _): metric.percentage
            }
        }

        var completed: Int? {
            guard case let .milestones(metric, _) = self,
                  case let .valid(completed, _) = metric.validation else { return nil }
            return completed
        }

        var total: Int? {
            guard case let .milestones(metric, _) = self,
                  case let .valid(_, total) = metric.validation else { return nil }
            return total
        }
    }

    struct ImageContent {
        let image: ImportedImage
        var caption: String { image.filename }
    }
}
