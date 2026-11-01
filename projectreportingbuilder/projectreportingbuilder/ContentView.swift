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
        draft.hasProjectInformation && draft.milestones.progress != nil && !isImportingImage
    }

    private var hasChanges: Bool {
        generatedRevision.map { $0 != DraftRevision(draft) } ?? false
    }

    var body: some View {
        HSplitView {
            VStack(spacing: 0) {
                WorkspaceHeading(title: "Project inputs", subtitle: "Shape your next project update.")
                Form {
                    ProjectInformationSection(name: $draft.projectName, update: $draft.projectUpdate)
                    MilestoneSection(metric: $draft.milestones)
                    ImageImportSection(image: $draft.image, isLoading: $isImportingImage)
                }
                .formStyle(.grouped)
                .accessibilityIdentifier("inputForm")
                Divider()
                GenerationControls(
                    hasProjectInformation: draft.hasProjectInformation,
                    metricMessage: draft.milestones.validation.message,
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
    let completed: String
    let total: String
    let imageID: UUID?

    init(_ draft: ReportDraft) {
        name = draft.projectName
        update = draft.projectUpdate
        completed = draft.milestones.completedInput
        total = draft.milestones.totalInput
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
                    Text("Add a project name and update to generate cards.")
                } else if let metricMessage {
                    Text(metricMessage)
                } else {
                    Text("Ready to generate. Images are optional.")
                }
            }
            .font(.callout)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("generationFeedback")

            Button(action: generate) {
                Label("Generate Cards", systemImage: "rectangle.stack")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.return, modifiers: .command)
            .disabled(!canGenerate)
            .help("Generate previews from your current inputs (Command–Return).")
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
                .foregroundStyle(.secondary)
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
        Section("Project information") {
            TextField("Project name", text: $name, prompt: Text("e.g. Customer portal rollout"))
                .accessibilityIdentifier("projectName")
            VStack(alignment: .leading, spacing: 8) {
                Text("Project update")
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $update)
                        .frame(minHeight: 120)
                        .accessibilityLabel("Project update")
                        .accessibilityIdentifier("projectUpdate")
                    if update.isEmpty {
                        Text("Summarize progress, risks and next steps…")
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 8)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                }
            }
            if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || update.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Enter a project name and update. Your draft stays editable while fields are empty.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct MilestoneSection: View {
    @Binding var metric: MilestoneMetric

    var body: some View {
        Section("Milestones") {
            TextField("Completed milestones", text: $metric.completedInput, prompt: Text("e.g. 3"))
                .accessibilityIdentifier("completedMilestones")
            TextField("Total milestones", text: $metric.totalInput, prompt: Text("e.g. 10"))
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
                .foregroundStyle(.secondary)
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
        Section("Project image") {
            Button(image == nil ? "Import image…" : "Replace image…") {
                isImporterPresented = true
            }
            .accessibilityIdentifier("importImage")
            .disabled(isLoading)

            Text("Optional PNG or JPEG, up to 20 MB and 40 megapixels.")
                .font(.callout)
                .foregroundStyle(.secondary)

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

#Preview {
    ContentView()
}
