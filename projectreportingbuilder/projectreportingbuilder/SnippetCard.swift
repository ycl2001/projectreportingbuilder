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
        case milestones(MilestoneMetric)
        case estimate(PercentageMetric)

        var progress: Double? {
            switch self {
            case .milestones(let metric): metric.progress
            case .estimate(let metric): metric.progress
            }
        }

        var percentage: Double? {
            switch self {
            case .milestones(let metric): metric.progress.map { $0 * 100 }
            case .estimate(let metric): metric.percentage
            }
        }

        var completed: Int? {
            guard case let .milestones(metric) = self,
                  case let .valid(completed, _) = metric.validation else { return nil }
            return completed
        }

        var total: Int? {
            guard case let .milestones(metric) = self,
                  case let .valid(_, total) = metric.validation else { return nil }
            return total
        }
    }

    struct ImageContent {
        let image: ImportedImage
        var caption: String { image.filename }
    }
}
