# Project Reporting Builder

Project Reporting Builder is a native macOS SwiftUI proof of concept created for the Apple IS&T internship technical assessment.

## Project Overview

Enterprise project managers regularly collect narrative updates, progress figures, and screenshots, then reformat the same information for stakeholders, email, and messaging tools. Project Reporting Builder provides a lightweight reporting workspace that turns those inputs into structured, accessible, and reusable project reports without requiring a cloud service.

The application is intended for project managers, technical program managers, engineering leads, and stakeholders who prepare or consume recurring project updates.

## Implemented Features

- Manual project-name entry and a multiline editor for typed or pasted updates.
- Optional progress tracking using either a self-reported percentage or completed/total milestones.
- Progress notes for context that does not belong in the numeric metric itself.
- Local PNG and JPEG import, validation, replacement, removal, and preview.
- Reusable Summary, KPI/Progress, and Image Snippet Cards.
- A unified report preview with one project header and the available report sections.
- Clipboard sharing for individual Snippet Cards or the complete report, with plain-text, RTF, and PNG representations.
- Native PNG export for individual cards and complete reports.
- Persisted System, Light, and Dark appearance preferences.
- Persistent local Report History:
  - Explicitly save the currently generated report snapshot.
  - Browse saved reports newest first.
  - Open a previous report as a read-only snapshot and use its report-level Copy/Export actions.
  - Duplicate a saved report into the existing editor as a new draft.
  - Confirm before replacing unsaved editor work or deleting a saved report.
  - Keep original-quality image bytes in separately managed local assets.

## Technology and Architecture

The project uses Swift, SwiftUI, and native macOS frameworks only. There are no third-party dependencies and no required cloud backend.

The reporting flow is deliberately separated into small types:

- [`ReportDraft`](projectreportingbuilder/projectreportingbuilder/ReportDraft.swift) holds editable user input and validation state.
- [`ReportBuilder`](projectreportingbuilder/projectreportingbuilder/ReportBuilder.swift) deterministically converts a valid draft into modular [`SnippetCard`](projectreportingbuilder/projectreportingbuilder/SnippetCard.swift) values. It does not infer missing progress or rewrite the user's update.
- [`SnippetCardViews`](projectreportingbuilder/projectreportingbuilder/SnippetCardViews.swift) renders the reusable sections and unified report.
- [`CardSharingService`](projectreportingbuilder/projectreportingbuilder/CardSharingService.swift) uses `NSPasteboard`, `ImageRenderer`, `NSBitmapImageRep`, and `NSSavePanel` for clipboard and PNG sharing.
- [`SavedReport`](projectreportingbuilder/projectreportingbuilder/SavedReport.swift) is the Codable snapshot representation.
- [`ReportStore`](projectreportingbuilder/projectreportingbuilder/ReportStore.swift) stores one JSON record per report under the user's Application Support directory and manages image files separately.
- [`ReportHistoryView`](projectreportingbuilder/projectreportingbuilder/ReportHistoryView.swift) browses, opens, duplicates, and deletes saved snapshots without mutating the current draft merely to view history.

Generated cards form an immutable preview snapshot. Editing the draft after generation marks the preview as stale; Copy/Export continues to use the visible generated snapshot, and Save Report is disabled until the report is regenerated.

## Getting Started

### Requirements

- A Mac running macOS 27.0 or later. The Xcode project deployment target is macOS 27.0.
- Xcode 27.2 with the macOS 27 SDK. The project configuration was last upgraded with Xcode 27.2.

### Open, build, and run

From the repository root:

```sh
open projectreportingbuilder/projectreportingbuilder.xcodeproj
```

In Xcode:

1. Select the shared `projectreportingbuilder` scheme.
2. Select **My Mac** as the run destination.
3. Build with **Product > Build** (Command-B).
4. Run with **Product > Run** (Command-R).

The application target uses automatic code signing. If Xcode requests signing configuration on another machine, select an available development team for local execution.

### Run the tests

Use **Product > Test** (Command-U), or run the suite from the repository root:

```sh
xcodebuild test \
  -project projectreportingbuilder/projectreportingbuilder.xcodeproj \
  -scheme projectreportingbuilder \
  -destination 'platform=macOS'
```

The test targets use Swift Testing for unit tests and XCTest/XCUIAutomation for macOS UI tests.

## Usage Walkthrough

1. Enter a project name and type or paste the current project update.
2. Optionally choose Percentage or Milestones, add a progress note, and import a PNG or JPEG image.
3. Select **Generate Report** to create the unified preview.
4. Use **Copy Report** or **Export Report as PNG**, or share an individual Summary, Progress, or Image Snippet Card.
5. Select **Save Report** to store the generated snapshot. Newer ungenerated editor changes are never silently included.
6. Open **History** to view previous snapshots. Use **Duplicate as New Draft** to load a prior report's inputs, edit them for the next reporting period, and generate a new report without changing the original snapshot.

## Engineering Quality

- **Validation:** Project name and update are required. Percentage input is bounded to 0–100; milestone input requires non-negative whole numbers, a total above zero, and completed not exceeding total. Image decoding accepts PNG/JPEG files up to 20 MB and 40 megapixels and reports unsupported or corrupt data.
- **Reusable architecture:** Input state, deterministic transformation, card rendering, sharing, and persistence are separate types rather than one view-owned implementation.
- **Snapshot consistency:** Generated output remains stable while the draft changes, stale-preview feedback is displayed, and stale or already-saved previews cannot be saved again.
- **Accessibility foundations:** Views use semantic system colours, native controls, explicit accessibility labels/identifiers, headers, text alternatives, and keyboard shortcuts. Automated tests exercise identifiers and selected keyboard flows.
- **Local persistence:** Report JSON and managed image assets are written under Application Support. Records are independent, writes avoid overwriting existing report IDs, corrupt records are skipped, and a missing saved image does not prevent usable text/progress sections from opening.
- **Automated testing:** Unit and UI coverage includes validation, deterministic generation, optional progress, image handling, clipboard representations, light/dark PNG rendering, unified reports, persistence, restart/reload, duplication, deletion, stale-save protection, and responsive workspace behavior.

### Latest reported verification result

**106 passed, 0 failed, 0 skipped.**

This is the latest reported full regression result for the `projectreportingbuilder` test plan. It includes parameterized Swift Testing cases and macOS UI tests. See [`REQUIREMENTS.md`](REQUIREMENTS.md) for requirement-level evidence.

## Design Decisions, Validation & Future Work

### Design decisions

Project Reporting Builder is a local-first macOS PoC focused on producing reliable stakeholder reports:

- **Local persistence:** Reports are saved only on explicit request, using independent Codable JSON records and separately managed image assets under Application Support. This avoids a required backend while keeping saved snapshots reproducible across launches.
- **Flexible source input:** Project managers can type or paste updates, then optionally add percentage or milestone progress, context, and an image. The workflow accommodates varied reporting formats without forcing an external schema or integration.
- **Deterministic output:** Validation and `ReportBuilder` generate reports without inventing or rewriting project information. Generated snapshots remain stable until the user explicitly regenerates them.
- **Reusable Snippet Cards:** Summary, KPI/Progress, and Image sections compose one unified report while remaining independently copyable and exportable.

### Verification boundaries

Automated coverage verifies validation, deterministic generation, sharing, appearance-aware PNG rendering, persistence, history, and core macOS UI flows. Live VoiceOver usability and a complete keyboard-only manual walkthrough remain unverified. Destination-specific clipboard behavior and the complete Light/Dark manual export matrix also require final human validation.

### Possible future enhancements

Potential extensions include editable image captions, optional AI-assisted suggestions with explicit user review, integrations with external project-management or communication tools, custom report templates, and historical comparisons or trend views.

### Deliberately excluded from this PoC

Cloud sync, accounts, multi-user collaboration, and production backend infrastructure are not part of the current implementation. Production security assessment, scalability testing, data-governance review, and enterprise deployment validation are also outside the scope of this technical proof of concept.

## Requirements Traceability

[`REQUIREMENTS.md`](REQUIREMENTS.md) maps the assessment scope to source files, acceptance criteria, and automated or manual verification status.
