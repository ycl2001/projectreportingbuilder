import SwiftUI
import AppKit

struct SummaryCardView: View {
    let card: SnippetCard.Summary

    var body: some View {
        CardSurface(title: "Summary") {
            CardText(value: card.projectName, placeholder: "Project name not provided")
                .font(.title2)
                .accessibilityIdentifier("generatedProjectName")
            CardText(value: card.updateNotes, placeholder: "No project update provided")
                .accessibilityIdentifier("generatedUpdate")
        }
    }
}

struct KPICardView: View {
    let card: SnippetCard.KPI

    var body: some View {
        CardSurface(title: "Project progress") {
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
    @State private var preview: NSImage?
    @State private var didLoad = false

    var body: some View {
        CardSurface(title: "Project image") {
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
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accessibleBoundary, lineWidth: 1)
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

    var body: some View {
        switch card {
        case .summary(let content): SummaryCardView(card: content)
        case .kpi(let content): KPICardView(card: content)
        case .image(let content): ImageCardView(card: content, preparedImage: preparedImage)
        }
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
