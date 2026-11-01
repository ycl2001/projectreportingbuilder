import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var draft = ReportDraft()

    var body: some View {
        Form {
            ProjectInformationSection(name: $draft.projectName, update: $draft.projectUpdate)
            MilestoneSection(metric: $draft.milestones)
            ImageImportSection(image: $draft.image)
        }
        .formStyle(.grouped)
        .navigationTitle("Project Reporting Builder")
        .frame(minWidth: 460, idealWidth: 640, minHeight: 520, idealHeight: 760)
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
    @State private var isLoading = false
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
