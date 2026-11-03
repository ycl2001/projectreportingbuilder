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
                    Text(cards.count == 1 ? "1 card · Ready to share" : "\(cards.count) cards · Ready to share")
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
    @Environment(\.colorScheme) private var colorScheme
    @State private var feedback: String?
    @State private var isSharing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SnippetCardContent(card: item.card)
            HStack {
                Button {
                    do {
                        try CardSharingService.copy(item.card, colorScheme: colorScheme)
                        feedback = "Copied text and image."
                    } catch {
                        feedback = "Copy failed: \(error.localizedDescription)"
                    }
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .accessibilityLabel("Copy \(CardSharingService.title(for: item.card)) card")
                .accessibilityIdentifier("copy-\(item.id)")
                Button {
                    isSharing = true
                    feedback = nil
                    Task {
                        defer { isSharing = false }
                        do {
                            if let url = try await CardSharingService.export(item.card, colorScheme: colorScheme) {
                                feedback = "Exported \(url.lastPathComponent)."
                            }
                        } catch {
                            feedback = "Export failed: \(error.localizedDescription)"
                        }
                    }
                } label: {
                    Label("Export PNG…", systemImage: "square.and.arrow.up")
                }
                .accessibilityLabel("Export \(CardSharingService.title(for: item.card)) card as PNG")
                .accessibilityIdentifier("export-\(item.id)")
            }
            .disabled(isSharing)
            if let feedback {
                Text(feedback)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("sharingFeedback-\(item.id)")
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
