import SwiftUI

/// Stable presentation identity for the builder's one-card-per-kind output.
struct CardPreviewItem: Identifiable {
    enum Kind: Hashable {
        case summary, kpi, image
    }

    let card: SnippetCard

    init(_ card: SnippetCard) {
        self.card = card
    }

    var id: Kind {
        switch card {
        case .summary: .summary
        case .kpi: .kpi
        case .image: .image
        }
    }
}

struct CardPreviewPanel: View {
    let cards: [CardPreviewItem]
    let hasChanges: Bool
    let generationID: UUID

    var body: some View {
        VStack(spacing: 0) {
            WorkspaceHeading(title: "Snippet Cards", subtitle: "A clear view of your project, ready to review.")
            Divider()
            if cards.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: "rectangle.stack")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                        Text("Turn your update into cards")
                            .font(.title2.weight(.semibold))
                        Text("Start with a project name and update, then choose Generate Cards.")
                            .foregroundStyle(.secondary)
                        Text("Progress and images are optional.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 420, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(28)
                }
                .accessibilityIdentifier("cardsEmptyState")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    if hasChanges {
                        Label("Changes not generated", systemImage: "arrow.clockwise.circle")
                            .font(.headline)
                            .accessibilityIdentifier("cardsOutOfDate")
                        Text("These cards show your last generation. Choose Generate Cards to refresh them.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    } else {
                        Label("Cards are up to date", systemImage: "checkmark.circle")
                            .font(.callout)
                            .accessibilityIdentifier("cardsUpToDate")
                    }
                    Text(cards.count == 1 ? "1 card · Preview only" : "\(cards.count) cards · Preview only")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("generatedCardCount")
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)

                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(cards) { item in
                            CardPreviewRow(item: item)
                        }
                    }
                    .id(generationID)
                    .frame(maxWidth: 760)
                    .frame(maxWidth: .infinity)
                    .padding(20)
                }
                .accessibilityIdentifier("cardPreviewScroll")
            }
        }
        .background(.background.secondary)
    }
}

private struct CardPreviewRow: View {
    let item: CardPreviewItem

    var body: some View {
        VStack {
            switch item.card {
            case .summary(let card):
                SummaryCardView(card: card)
            case .kpi(let card):
                KPICardView(card: card)
            case .image(let card):
                ImageCardView(card: card)
            }
        }
    }
}

#Preview("Generated cards") {
    let draft = ReportDraft(
        projectName: "Customer portal rollout",
        projectUpdate: "Pilot delivery is on track.\n\nNext: validate the release with the support team.",
        milestones: MilestoneMetric(completedInput: "7", totalInput: "10"),
        progressMethod: .milestones
    )
    CardPreviewPanel(
        cards: ReportBuilder.build(from: draft).map(CardPreviewItem.init),
        hasChanges: false,
        generationID: UUID()
    )
    .frame(width: 500, height: 740)
}
