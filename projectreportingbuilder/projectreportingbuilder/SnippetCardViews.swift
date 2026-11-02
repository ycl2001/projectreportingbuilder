import SwiftUI
import AppKit

enum SnippetCardPresentation {
    case standalone
    case reportSection
}

struct SummaryCardView: View {
    let card: SnippetCard.Summary
    var presentation: SnippetCardPresentation = .standalone

    var body: some View {
        CardSurface(title: "Summary", presentation: presentation) {
            if presentation == .standalone {
                CardText(value: card.projectName, placeholder: "Project name not provided")
                    .font(.title2)
                    .accessibilityIdentifier("generatedProjectName")
            }
            CardText(value: card.updateNotes, placeholder: "No project update provided")
                .accessibilityIdentifier("generatedUpdate")
        }
    }
}

struct KPICardView: View {
    let card: SnippetCard.KPI
    var presentation: SnippetCardPresentation = .standalone

    var body: some View {
        CardSurface(title: "Progress", presentation: presentation) {
            switch card {
            case .milestones:
                Text("Calculated from milestones")
                    .font(.callout)
                    .foregroundStyle(Color.accessibleSecondary)
                    .accessibilityIdentifier("generatedProgressSource")
                if let completed = card.completed, let total = card.total {
                    Text("\(completed) of \(total) milestones completed")
                        .accessibilityIdentifier("generatedMilestoneCounts")
                        .fixedSize(horizontal: false, vertical: true)
                }
            case .estimate:
                Text("Self-reported")
                    .font(.callout)
                    .foregroundStyle(Color.accessibleSecondary)
                    .accessibilityIdentifier("generatedProgressSource")
            }
            if let progress = card.progress {
                Text(progress, format: .percent.precision(.fractionLength(0...4)))
                    .font(.largeTitle)
                    .monospacedDigit()
                    .accessibilityIdentifier("generatedPercentage")
                ProgressView(value: progress)
                    .progressViewStyle(CardProgressStyle())
                    .accessibilityLabel("Project completion")
                    .accessibilityValue(Text(progress, format: .percent.precision(.fractionLength(0...4))))
            } else {
                Text("Progress unavailable")
            }
            if !card.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(verbatim: card.note)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("generatedProgressNote")
            }
        }
    }
}

struct ImageCardView: View {
    let card: SnippetCard.ImageContent
    var preparedImage: NSImage? = nil
    var presentation: SnippetCardPresentation = .standalone
    @State private var preview: NSImage?
    @State private var didLoad = false

    var body: some View {
        CardSurface(title: "Image", presentation: presentation) {
            if let preview = preparedImage ?? preview {
                Image(nsImage: preview)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 320)
                    .accessibilityLabel("Project image: \(card.caption)")
                    .accessibilityIdentifier("generatedImage")
            } else if didLoad {
                Label("Image preview unavailable", systemImage: "photo")
            } else {
                ProgressView("Loading image preview…")
            }
            CardText(value: card.caption, placeholder: "Unnamed image")
                .accessibilityIdentifier("generatedImageCaption")
                .font(.callout)
        }
        .task(id: card.image.id) {
            guard preparedImage == nil else { return }
            // Decode only when the attachment changes, not on every body evaluation.
            preview = NSImage(data: card.image.data)
            didLoad = true
        }
    }
}

private struct CardSurface<Content: View>: View {
    let title: LocalizedStringKey
    let presentation: SnippetCardPresentation
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(presentation == .standalone ? 20 : 0)
        .background(
            presentation == .standalone ? Color(nsColor: .controlBackgroundColor) : Color.clear,
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accessibleBoundary, lineWidth: presentation == .standalone ? 1 : 0)
        }
        .accessibilityElement(children: .contain)
    }
}

private struct CardText: View {
    let value: String
    let placeholder: LocalizedStringKey

    var body: some View {
        if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Text(placeholder)
                .foregroundStyle(Color.accessibleSecondary)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Text(verbatim: value)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct SnippetCardContent: View {
    let card: SnippetCard
    var preparedImage: NSImage? = nil
    var presentation: SnippetCardPresentation = .standalone

    var body: some View {
        switch card {
        case .summary(let content):
            SummaryCardView(card: content, presentation: presentation)
        case .kpi(let content):
            KPICardView(card: content, presentation: presentation)
        case .image(let content):
            ImageCardView(card: content, preparedImage: preparedImage, presentation: presentation)
        }
    }
}

struct UnifiedReportView: View {
    let cards: [SnippetCard]
    var preparedImages: [UUID: NSImage] = [:]

    @MainActor private var items: [CardPreviewItem] {
        cards.map(CardPreviewItem.init)
    }

    private var projectName: String {
        for card in cards {
            if case .summary(let summary) = card {
                return summary.projectName
            }
        }
        return ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            UnifiedReportHeader(projectName: projectName)
            Divider()
            ForEach(items) { item in
                UnifiedReportSection(
                    item: item,
                    preparedImage: preparedImage(for: item.card)
                )
                if item.id != items.last?.id {
                    Divider()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(28)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.accessibleBoundary, lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("unifiedReportPreview")
    }

    private func preparedImage(for card: SnippetCard) -> NSImage? {
        guard case .image(let content) = card else { return nil }
        return preparedImages[content.image.id]
    }
}

private struct UnifiedReportHeader: View {
    let projectName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Project report")
                .font(.callout.weight(.semibold))
                .foregroundStyle(Color.accessibleSecondary)
                .accessibilityAddTraits(.isHeader)
            if projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Project name not provided")
                    .foregroundStyle(Color.accessibleSecondary)
                    .font(.title.weight(.semibold))
                    .accessibilityIdentifier("generatedProjectName")
            } else {
                Text(verbatim: projectName)
                    .font(.title.weight(.semibold))
                    .accessibilityIdentifier("generatedProjectName")
            }
        }
    }
}

private struct UnifiedReportSection: View {
    let item: CardPreviewItem
    let preparedImage: NSImage?

    var body: some View {
        SnippetCardContent(
            card: item.card,
            preparedImage: preparedImage,
            presentation: .reportSection
        )
    }
}

private struct CardProgressStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.accessibleBoundary)
                Capsule().fill(.tint)
                    .frame(width: geometry.size.width * (configuration.fractionCompleted ?? 0))
            }
        }
        .frame(height: 6)
    }
}
