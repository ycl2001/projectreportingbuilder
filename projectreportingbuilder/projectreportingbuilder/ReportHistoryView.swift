import SwiftUI

struct ReportHistoryView: View {
    let requiresReplacementConfirmation: Bool
    let duplicateDraft: (ReportDraft) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var store: ReportStore?
    @State private var reports: [SavedReport] = []
    @State private var selectedReportID: SavedReport.ID?
    @State private var snapshot: ReportStore.ViewSnapshot?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var reportPendingDeletion: SavedReport?
    @State private var isDeleteConfirmationPresented = false
    @State private var reportPendingDuplication: SavedReport?
    @State private var isDuplicateConfirmationPresented = false

    var body: some View {
        VStack(spacing: 0) {
            ReportHistoryHeader(reportCount: reports.count)
            Divider()
            if isLoading {
                ProgressView("Loading saved reports…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityIdentifier("historyLoading")
            } else if reports.isEmpty {
                ReportHistoryEmptyState(errorMessage: errorMessage)
            } else {
                ReportHistoryBrowser(
                    reports: reports,
                    selectedReportID: $selectedReportID,
                    snapshot: snapshot,
                    errorMessage: errorMessage,
                    duplicate: requestDuplication,
                    delete: requestDeletion
                )
            }
        }
        .frame(minWidth: 760, idealWidth: 940, minHeight: 520, idealHeight: 680)
        .background(.background)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                .accessibilityIdentifier("closeHistory")
            }
        }
        .task {
            loadHistory()
        }
        .onChange(of: selectedReportID) {
            openSelectedReport()
        }
        .alert(
            "Delete saved report?",
            isPresented: $isDeleteConfirmationPresented,
            presenting: reportPendingDeletion
        ) { report in
            Button("Delete Saved Report", role: .destructive) {
                delete(report)
            }
            Button("Cancel", role: .cancel) {}
        } message: { report in
            Text("This permanently removes the saved “\(report.projectName)” snapshot and its managed image.")
        }
        .alert(
            "Replace unsaved editor changes?",
            isPresented: $isDuplicateConfirmationPresented,
            presenting: reportPendingDuplication
        ) { report in
            Button("Replace and Duplicate", role: .destructive) {
                duplicate(report)
            }
            Button("Cancel", role: .cancel) {}
        } message: { report in
            Text("Duplicating “\(report.projectName)” replaces the current editor inputs. The saved report remains unchanged.")
        }
    }

    private func loadHistory() {
        isLoading = true
        errorMessage = nil
        do {
            let store = try ReportStore()
            self.store = store
            reports = store.list()
            selectedReportID = reports.first?.id
            openSelectedReport()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func openSelectedReport() {
        guard let store, let selectedReportID else {
            snapshot = nil
            return
        }
        do {
            snapshot = try store.snapshotForViewing(id: selectedReportID)
            errorMessage = nil
        } catch {
            snapshot = nil
            errorMessage = error.localizedDescription
        }
    }

    private func requestDuplication(_ report: SavedReport) {
        if requiresReplacementConfirmation {
            reportPendingDuplication = report
            isDuplicateConfirmationPresented = true
        } else {
            duplicate(report)
        }
    }

    private func duplicate(_ report: SavedReport) {
        guard let store else { return }
        do {
            let replacement = try store.draftForEditing(id: report.id)
            duplicateDraft(replacement)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func requestDeletion(_ report: SavedReport) {
        reportPendingDeletion = report
        isDeleteConfirmationPresented = true
    }

    private func delete(_ report: SavedReport) {
        guard let store else { return }
        do {
            try store.delete(id: report.id)
            reports = store.list()
            selectedReportID = reports.first?.id
            openSelectedReport()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct ReportHistoryHeader: View {
    let reportCount: Int

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Report History")
                    .font(.title2.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                Text("Open a saved snapshot or duplicate it into a new editable draft.")
                    .font(.callout)
                    .foregroundStyle(Color.accessibleSecondary)
            }
            Spacer(minLength: 16)
            if reportCount > 0 {
                Text(reportCount == 1 ? "1 saved report" : "\(reportCount) saved reports")
                    .font(.callout)
                    .foregroundStyle(Color.accessibleSecondary)
                    .accessibilityIdentifier("historyReportCount")
            }
        }
        .padding(20)
    }
}

private struct ReportHistoryEmptyState: View {
    let errorMessage: String?

    var body: some View {
        ContentUnavailableView {
            Label("No Saved Reports", systemImage: "clock.arrow.circlepath")
        } description: {
            if let errorMessage {
                Text("History could not be loaded: \(errorMessage)")
            } else {
                Text("Generate a report and choose Save Report to keep a local snapshot.")
            }
        }
        .accessibilityIdentifier("historyEmptyState")
    }
}

private struct ReportHistoryBrowser: View {
    let reports: [SavedReport]
    @Binding var selectedReportID: SavedReport.ID?
    let snapshot: ReportStore.ViewSnapshot?
    let errorMessage: String?
    let duplicate: (SavedReport) -> Void
    let delete: (SavedReport) -> Void

    var body: some View {
        HSplitView {
            ReportHistoryList(
                reports: reports,
                selectedReportID: $selectedReportID,
                duplicate: duplicate,
                delete: delete
            )
            .frame(minWidth: 260, idealWidth: 310, maxWidth: 380)

            ReportHistorySnapshotDetail(
                snapshot: snapshot,
                errorMessage: errorMessage,
                duplicate: duplicate,
                delete: delete
            )
            .frame(minWidth: 460, maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct ReportHistoryList: View {
    let reports: [SavedReport]
    @Binding var selectedReportID: SavedReport.ID?
    let duplicate: (SavedReport) -> Void
    let delete: (SavedReport) -> Void

    var body: some View {
        List(reports, selection: $selectedReportID) { report in
            ReportHistoryRow(report: report)
                .tag(report.id)
                .contextMenu {
                    Button("Duplicate as New Draft") {
                        duplicate(report)
                    }
                    Divider()
                    Button("Delete", role: .destructive) {
                        delete(report)
                    }
                }
        }
        .accessibilityLabel("Saved reports, newest first")
        .accessibilityIdentifier("historyList")
    }
}

private struct ReportHistoryRow: View {
    let report: SavedReport

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(report.projectName)
                .font(.headline)
                .lineLimit(1)
            Text(report.createdAt, format: .dateTime.day().month().year().hour().minute())
                .font(.caption)
                .foregroundStyle(Color.accessibleSecondary)
            Text(report.projectUpdate)
                .font(.callout)
                .lineLimit(2)
            if let progress = report.progress {
                SavedReportProgressLabel(progress: progress)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("historyRow-\(report.id.uuidString)")
    }
}

private struct SavedReportProgressLabel: View {
    let progress: SavedReport.Progress

    var body: some View {
        Label {
            switch progress {
            case .percentage(let input, _):
                Text("\(input)% reported")
            case .milestones(let completedInput, let totalInput, _):
                Text("\(completedInput) of \(totalInput) milestones")
            }
        } icon: {
            Image(systemName: "chart.bar.fill")
        }
        .font(.caption)
        .foregroundStyle(Color.accessibleSecondary)
    }
}

private struct ReportHistorySnapshotDetail: View {
    let snapshot: ReportStore.ViewSnapshot?
    let errorMessage: String?
    let duplicate: (SavedReport) -> Void
    let delete: (SavedReport) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let snapshot {
                    HStack(alignment: .firstTextBaseline) {
                        Label("Read-only saved snapshot", systemImage: "lock")
                            .font(.callout.weight(.medium))
                        Spacer(minLength: 12)
                        Text(snapshot.report.createdAt, format: .dateTime.day().month().year().hour().minute())
                            .font(.caption)
                            .foregroundStyle(Color.accessibleSecondary)
                    }
                    if let imageIssue = snapshot.imageIssue {
                        Label {
                            Text("The report image is unavailable: \(imageIssue.localizedDescription)")
                        } icon: {
                            Image(systemName: "exclamationmark.triangle")
                        }
                        .font(.callout)
                        .foregroundStyle(Color.accessibleSecondary)
                        .accessibilityIdentifier("historyImageWarning")
                    }
                    UnifiedReportView(cards: snapshot.cards)
                    ReportSharingActions(cards: snapshot.cards)
                    Divider()
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 10) {
                            ReportHistoryActionButtons(
                                report: snapshot.report,
                                duplicate: duplicate,
                                delete: delete
                            )
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            ReportHistoryActionButtons(
                                report: snapshot.report,
                                duplicate: duplicate,
                                delete: delete
                            )
                        }
                    }
                } else if let errorMessage {
                    ContentUnavailableView(
                        "Saved Report Unavailable",
                        systemImage: "exclamationmark.triangle",
                        description: Text(errorMessage)
                    )
                } else {
                    ContentUnavailableView(
                        "Select a Saved Report",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("Choose a report from the history list to open its snapshot.")
                    )
                }
            }
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(20)
        }
        .accessibilityIdentifier("historySnapshot")
        .background(.background.secondary)
    }
}

private struct ReportHistoryActionButtons: View {
    let report: SavedReport
    let duplicate: (SavedReport) -> Void
    let delete: (SavedReport) -> Void

    var body: some View {
        Button {
            duplicate(report)
        } label: {
            Label("Duplicate as New Draft", systemImage: "doc.on.doc")
        }
        .buttonStyle(.borderedProminent)
        .accessibilityIdentifier("duplicateSavedReport")

        Button(role: .destructive) {
            delete(report)
        } label: {
            Label("Delete", systemImage: "trash")
        }
        .accessibilityLabel("Delete saved report")
        .accessibilityIdentifier("deleteSavedReport")
    }
}
