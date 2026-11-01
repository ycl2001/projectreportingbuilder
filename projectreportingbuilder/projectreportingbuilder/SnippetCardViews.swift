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
        CardSurface(title: "Milestone progress") {
            if let completed = card.completed,
               let total = card.total,
               let progress = card.progress {
                Text("\(completed) of \(total) milestones completed")
                    .accessibilityIdentifier("generatedMilestoneCounts")
                    .fixedSize(horizontal: false, vertical: true)
                Text(progress, format: .percent.precision(.fractionLength(0...1)))
                    .font(.largeTitle)
                    .monospacedDigit()
                    .accessibilityIdentifier("generatedPercentage")
                ProgressView(value: progress)
                    .accessibilityLabel("Milestones completed")
                    .accessibilityValue(Text(progress, format: .percent.precision(.fractionLength(0...1))))
            } else {
                if let message = card.validation.message {
                    Label {
                        Text(message)
                            .fixedSize(horizontal: false, vertical: true)
                    } icon: {
                        Image(systemName: "info.circle")
                    }
                }
                // Keep invalid input visible so it can be corrected during integration.
                Text("Completed input")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                CardText(value: card.milestones.completedInput, placeholder: "Not provided")
                Text("Total input")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                CardText(value: card.milestones.totalInput, placeholder: "Not provided")
            }
        }
    }
}

struct ImageCardView: View {
    let card: SnippetCard.ImageContent
    @State private var preview: NSImage?
    @State private var didLoad = false

    var body: some View {
        CardSurface(title: "Project image") {
            if let preview {
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
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
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
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Text(verbatim: value)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
