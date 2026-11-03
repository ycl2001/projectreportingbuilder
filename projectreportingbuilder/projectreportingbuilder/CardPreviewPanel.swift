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

private enum PreviewScrollAnchor: Hashable {
    case reportHeader
}

struct CardPreviewPanel: View {
    let cards: [CardPreviewItem]
    let hasChanges: Bool
    let generationID: UUID
    let canSaveReport: Bool
    let saveReport: () throws -> Void

    var body: some View {
        VStack(spacing: 0) {
            WorkspaceHeading(title: "Report Preview", subtitle: "One cohesive project report, ready to review and share.")
            Divider()
            if cards.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: "rectangle.stack")
                            .font(.largeTitle)
                            .foregroundStyle(Color.accessibleSecondary)
                            .accessibilityHidden(true)
                        Text("Build your project report")
                            .font(.title2.weight(.semibold))
                        Text("Start with a project name and update, then choose Generate Report.")
                            .foregroundStyle(Color.accessibleSecondary)
                        Text("Progress and images are optional.")
                            .font(.callout)
                            .foregroundStyle(Color.accessibleSecondary)
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
                        Text("This report shows your last generation. Choose Generate Report to refresh it.")
                            .font(.callout)
                            .foregroundStyle(Color.accessibleSecondary)
                    } else {
                        Label("Report is up to date", systemImage: "checkmark.circle")
                            .font(.callout)
                            .accessibilityIdentifier("cardsUpToDate")
                    }
                    Text(cards.count == 1 ? "1 section · Ready to share" : "\(cards.count) sections · Ready to share")
                        .font(.caption)
                        .foregroundStyle(Color.accessibleSecondary)
                        .accessibilityIdentifier("generatedCardCount")
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            UnifiedReportView(cards: cards.map(\.card))
                                .id(PreviewScrollAnchor.reportHeader)
                            ReportSharingActions(
                                cards: cards.map(\.card),
                                canSave: canSaveReport,
                                save: saveReport
                            )

                            VStack(alignment: .leading, spacing: 12) {
                                Text("Share individual sections")
                                    .font(.headline)
                                    .accessibilityAddTraits(.isHeader)
                                Text("Copy or export a reusable Snippet Card without sharing the full report.")
                                    .font(.callout)
                                    .foregroundStyle(Color.accessibleSecondary)
                                ForEach(cards) { item in
                                    SnippetSharingRow(item: item)
                                }
                            }
                            .padding(.top, 8)
                        }
                        .id(generationID)
                        .frame(maxWidth: 760)
                        .frame(maxWidth: .infinity)
                        .padding(20)
                    }
                    .accessibilityIdentifier("cardPreviewScroll")
                    .onChange(of: generationID) {
                        proxy.scrollTo(PreviewScrollAnchor.reportHeader, anchor: .top)
                    }
                }
            }
        }
        .background(.background.secondary)
    }
}

struct ReportSharingActions: View {
    let cards: [SnippetCard]
    var canSave = false
    var save: (() throws -> Void)?
    @Environment(\.colorScheme) private var colorScheme
    @State private var feedback: String?
    @State private var isSharing = false
    @State private var isSaving = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    copyButton
                    exportButton
                    if save != nil {
                        saveButton
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    copyButton
                    exportButton
                    if save != nil {
                        saveButton
                    }
                }
            }
            .disabled(isSharing || isSaving)
            if let feedback {
                Text(feedback)
                    .font(.callout)
                    .foregroundStyle(Color.accessibleSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("reportSharingFeedback")
            }
        }
    }

    private var copyButton: some View {
        Button {
            do {
                try CardSharingService.copyReport(cards, colorScheme: colorScheme)
                feedback = "Copied the full report as text and image."
            } catch {
                feedback = "Copy failed: \(error.localizedDescription)"
            }
        } label: {
            Label("Copy Report", systemImage: "doc.on.doc")
        }
        .buttonStyle(.borderedProminent)
        .accessibilityIdentifier("copyReport")
    }

    private var exportButton: some View {
        Button {
            isSharing = true
            feedback = nil
            Task {
                defer { isSharing = false }
                do {
                    if let url = try await CardSharingService.exportReport(cards, colorScheme: colorScheme) {
                        feedback = "Exported \(url.lastPathComponent)."
                    }
                } catch {
                    feedback = "Export failed: \(error.localizedDescription)"
                }
            }
        } label: {
            Label("Export Report as PNG…", systemImage: "square.and.arrow.up")
        }
        .accessibilityIdentifier("exportReport")
    }

    private var saveButton: some View {
        Button {
            guard let save else { return }
            isSaving = true
            defer { isSaving = false }
            do {
                try save()
                feedback = "Saved this generated report."
            } catch {
                feedback = "Save failed: \(error.localizedDescription)"
            }
        } label: {
            Label("Save Report", systemImage: "archivebox")
        }
        .disabled(!canSave)
        .help(canSave ? "Save this generated report snapshot." : "Generate an up-to-date report before saving.")
        .accessibilityIdentifier("saveReport")
    }
}

private struct SnippetSharingRow: View {
    let item: CardPreviewItem
    @Environment(\.colorScheme) private var colorScheme
    @State private var feedback: String?
    @State private var isSharing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Label(CardSharingService.title(for: item.card), systemImage: "rectangle.on.rectangle")
                    .font(.callout.weight(.medium))
                Spacer(minLength: 8)
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
                    .font(.caption)
                    .foregroundStyle(Color.accessibleSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("sharingFeedback-\(item.id)")
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.accessibleBoundary, lineWidth: 1)
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
        generationID: UUID(),
        canSaveReport: true,
        saveReport: {}
    )
    .frame(width: 500, height: 740)
}
