import Foundation

/// Creates a value snapshot without modifying, trimming, or discarding draft input.
enum ReportBuilder {
    static func build(from draft: ReportDraft) -> [SnippetCard] {
        var cards: [SnippetCard] = [
            .summary(.init(projectName: draft.projectName, updateNotes: draft.projectUpdate)),
            .kpi(.init(milestones: draft.milestones))
        ]
        if let image = draft.image {
            cards.append(.image(.init(image: image)))
        }
        return cards
    }
}
