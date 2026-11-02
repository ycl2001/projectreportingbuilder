import Foundation

/// Builds only the selected, valid progress metric; never infers missing progress.
enum ReportBuilder {
    static func build(from draft: ReportDraft) -> [SnippetCard] {
        var cards: [SnippetCard] = [
            .summary(.init(projectName: draft.projectName, updateNotes: draft.projectUpdate))
        ]
        switch draft.progressMethod {
        case .none:
            break
        case .percentage:
            if draft.estimatedPercentage.progress != nil {
                cards.append(.kpi(.estimate(draft.estimatedPercentage, note: draft.progressNote)))
            }
        case .milestones:
            if draft.milestones.progress != nil {
                cards.append(.kpi(.milestones(draft.milestones, note: draft.progressNote)))
            }
        }
        if let image = draft.image {
            cards.append(.image(.init(image: image)))
        }
        return cards
    }
}
