import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var draft = ReportDraft()
    @State private var isImportingImage = false
    @State private var cards: [CardPreviewItem] = []
    @State private var generatedRevision: DraftRevision?
    @State private var generationID = UUID()

    private var canGenerate: Bool {
        draft.canGenerate && !isImportingImage
    }

    private var hasChanges: Bool {
        generatedRevision.map { $0 != DraftRevision(draft) } ?? false
    }

    var body: some View {
        HSplitView {
            VStack(spacing: 0) {
                WorkspaceHeading(title: "Project inputs", subtitle: "Shape your next project update.")
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        ProjectInformationSection(name: $draft.projectName, update: $draft.projectUpdate)
                        Divider()
                        ProgressInputSection(
                            method: $draft.progressMethod,
                            percentage: $draft.estimatedPercentage,
                            milestones: $draft.milestones,
                            note: $draft.progressNote
                        )
                        Divider()
                        ImageImportSection(image: $draft.image, isLoading: $isImportingImage)
                    }
                    .padding(20)
                }
                .accessibilityIdentifier("inputForm")
                Divider()
                GenerationControls(
                    hasProjectInformation: draft.hasProjectInformation,
                    metricMessage: draft.progressValidationMessage,
                    isImportingImage: isImportingImage,
                    canGenerate: canGenerate,
                    generate: generateCards
                )
            }
            .frame(minWidth: 360, idealWidth: 430, maxWidth: 560)
            CardPreviewPanel(cards: cards, hasChanges: hasChanges, generationID: generationID)
                .frame(minWidth: 360, idealWidth: 570, maxWidth: .infinity)
        }
        .navigationTitle("Project Reporting Builder")
        .frame(minWidth: 780, idealWidth: 1060, minHeight: 560, idealHeight: 760)
    }

    private func generateCards() {
        guard canGenerate else { return }
        cards = ReportBuilder.build(from: draft).map(CardPreviewItem.init)
        generatedRevision = DraftRevision(draft)
        // Recreate the snapshot's accessibility elements when generated values change.
        generationID = UUID()
    }
}

/// Compare editable input without adding UI-only equality requirements to domain models.
private struct DraftRevision: Equatable {
    let name: String
    let update: String
    let method: ProgressMethod
    let note: String
    let percentage: String
    let completed: String
    let total: String
    let imageID: UUID?

    init(_ draft: ReportDraft) {
        name = draft.projectName
        update = draft.projectUpdate
        method = draft.progressMethod
        note = draft.progressMethod == .none ? "" : draft.progressNote
        percentage = draft.progressMethod == .percentage ? draft.estimatedPercentage.input : ""
        completed = draft.progressMethod == .milestones ? draft.milestones.completedInput : ""
        total = draft.progressMethod == .milestones ? draft.milestones.totalInput : ""
        imageID = draft.image?.id
    }
}

private struct GenerationControls: View {
    let hasProjectInformation: Bool
    let metricMessage: LocalizedStringResource?
    let isImportingImage: Bool
    let canGenerate: Bool
    let generate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Group {
                if isImportingImage {
                    Text("Wait for the image to finish importing.")
                } else if !hasProjectInformation {
                    Text("Add a project name and update to generate a report.")
                } else if let metricMessage {
                    Text(metricMessage)
                } else {
                    Text("Ready to generate.")
                }
            }
            .font(.callout)
            .foregroundStyle(Color.accessibleSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("generationFeedback")

            Button(action: generate) {
                Label("Generate Report", systemImage: "rectangle.stack")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.return, modifiers: .command)
            .disabled(!canGenerate)
            .help("Generate a report from your current inputs (Command–Return).")
            .accessibilityIdentifier("generateCards")
        }
        .padding(20)
        .background(.bar)
    }
}

struct WorkspaceHeading: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.title2.weight(.semibold))
                .accessibilityAddTraits(.isHeader)
            Text(subtitle)
                .font(.callout)
                .foregroundStyle(Color.accessibleSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
    }
}

private struct ProjectInformationSection: View {
    @Binding var name: String
    @Binding var update: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Project name")
                    .font(.headline)
                TextField("Project name", text: $name, prompt: Text("e.g. Customer portal rollout"))
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("projectName")
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Project update")
                    .font(.headline)
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $update)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .frame(height: 180)
                        .padding(8)
                        .accessibilityLabel("Project update")
                        .accessibilityIdentifier("projectUpdate")
                    if update.isEmpty {
                        Text("Progress, risks and next steps…")
                            .foregroundStyle(Color.accessibleSecondary)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                }
                .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accessibleBoundary, lineWidth: 1)
                }
            }
        }
    }
}

private struct ProgressInputSection: View {
    @Binding var method: ProgressMethod
    @Binding var percentage: PercentageMetric
    @Binding var milestones: MilestoneMetric
    @Binding var note: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Progress · Optional")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            Picker("Reporting method", selection: $method) {
                Text("Percentage").tag(ProgressMethod.percentage)
                Text("Milestones").tag(ProgressMethod.milestones)
                Text("Skip").tag(ProgressMethod.none)
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Progress reporting method")
            .accessibilityIdentifier("progressMethod")

            switch method {
            case .none:
                Text("Generate a summary without a KPI card.")
                    .font(.callout)
                    .foregroundStyle(Color.accessibleSecondary)
            case .percentage:
                Text("Reported completion (%)")
                    .font(.subheadline)
                TextField("Reported completion (%)", text: $percentage.input, prompt: Text("e.g. 62.5"))
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("estimatedPercentage")
                Text("Self-reported · 0–100%. Use a dot for decimals.")
                    .font(.callout)
                    .foregroundStyle(Color.accessibleSecondary)
                if let message = percentage.validationMessage {
                    Text(message)
                        .font(.callout)
                        .accessibilityIdentifier("percentageValidation")
                }
            case .milestones:
                MilestoneSection(metric: $milestones)
            }
            if method != .none {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What does this progress represent?")
                        .font(.subheadline)
                    TextField(
                        "What does this progress represent?",
                        text: $note,
                        prompt: Text("Summarise achievements, remaining work, or blockers..."),
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("What does this progress represent? Optional")
                    .accessibilityIdentifier("progressNote")
                }
            }
        }
    }
}

private struct MilestoneSection: View {
    @Binding var metric: MilestoneMetric

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Completed milestones")
                .font(.subheadline)
            TextField("Completed milestones", text: $metric.completedInput, prompt: Text("e.g. 3"))
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("completedMilestones")
            Text("Total milestones")
                .font(.subheadline)
            TextField("Total milestones", text: $metric.totalInput, prompt: Text("e.g. 10"))
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("totalMilestones")
            if let progress = metric.progress {
                LabeledContent("Progress") {
                    Text(progress, format: .percent.precision(.fractionLength(0...1)))
                        .monospacedDigit()
                        .accessibilityIdentifier("milestoneProgress")
                }
                ProgressView(value: progress)
                    .accessibilityLabel("Milestone progress")
            } else if let message = metric.validation.message {
                Label {
                    Text(message)
                } icon: {
                    Image(systemName: "info.circle")
                }
                .font(.callout)
                .foregroundStyle(Color.accessibleSecondary)
                .accessibilityIdentifier("metricValidation")
            }
        }
    }
}

private struct ImageImportSection: View {
    @Binding var image: ImportedImage?
    @State private var isImporterPresented = false
    @Binding var isLoading: Bool
    @State private var importError: String?
    @State private var preview: NSImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Project image · Optional")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            Button(image == nil ? "Import image…" : "Replace image…") {
                isImporterPresented = true
            }
            .accessibilityIdentifier("importImage")
            .disabled(isLoading)

            Text("Optional PNG or JPEG, up to 20 MB and 40 megapixels.")
                .font(.callout)
                .foregroundStyle(Color.accessibleSecondary)

            if isLoading {
                ProgressView("Importing image…")
            }
            if let image {
                Text("Imported file: \(image.filename)")
                    .id(image.id)
                    .accessibilityIdentifier("imageFilename")
            }
            if let preview {
                Image(nsImage: preview)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 240)
                    .accessibilityLabel("Imported project image preview")
                    .accessibilityIdentifier("imagePreview")
            }
            if let importError {
                Text("Image import failed: \(importError)")
                    .font(.callout)
                    .accessibilityIdentifier("imageImportError")
            }
        }
        .task(id: image?.id) {
            preview = image.flatMap { NSImage(data: $0.data) }
        }
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.png, .jpeg],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first { importImage(from: url) }
            case .failure(let error):
                importError = error.localizedDescription
            }
        }
        .fileDialogConfirmationLabel("Import")
    }

    private func importImage(from url: URL) {
        isLoading = true
        importError = nil
        Task {
            defer { isLoading = false }
            do {
                let imported = try await Task.detached(priority: .userInitiated) {
                    try ImageImportService.load(from: url)
                }.value
                guard let decodedPreview = NSImage(data: imported.data) else {
                    throw ImageImportService.ImportError.unsupportedOrCorrupt
                }
                // Replace only after a successful import; failures preserve the prior image.
                image = imported
                preview = decodedPreview
            } catch {
                importError = error.localizedDescription
            }
        }
    }
}

#Preview("System") {
    ContentView()
}

#Preview("Light") {
    ContentView()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ContentView()
        .preferredColorScheme(.dark)
}
