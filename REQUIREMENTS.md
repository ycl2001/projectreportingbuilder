# Project Reporting Builder — Requirements Traceability

## 1. Assessment Scope

The assessment asks for a lightweight, responsive web or macOS proof of concept that:

- Ingests raw text, numerical metric data, and image assets.
- Transforms those inputs into modular, visually polished Snippet Cards.
- Supports immediate copying or export for reuse in messaging and email.
- Addresses accessibility compliance expectations in the interface and shared output.
- Demonstrates engineering quality through documentation, configuration, tests, and consistent coding conventions.
- May include optional visual polish, cloud concepts, or innovative enhancements where time permits.

Project Reporting Builder addresses the brief as a native macOS SwiftUI application. Cloud services and AI are not required for its implemented workflow.

## 2. Status Definitions

| Status | Meaning |
| --- | --- |
| **Implemented and verified** | Present in source and covered by relevant automated tests or the latest completed regression run. |
| **Implemented; manual validation pending** | Present in source, but the remaining behavior requires human interaction or assistive-technology review not demonstrated by current automated evidence. |
| **Deferred / out of scope** | Intentionally not implemented in this proof of concept. |

## 3. Functional Requirements Matrix

| Requirement ID | Description | Implementation | Status | Verification evidence |
| --- | --- | --- | --- | --- |
| FR-01 | Accept a project name and typed or pasted project update; require both before generation and preserve the supplied text. | `ReportDraft` owns raw input and `ContentView` provides native text controls. `ReportBuilder` carries the text into the Summary card without rewriting it. | **Implemented and verified** | [`ReportDraft.swift`](projectreportingbuilder/projectreportingbuilder/ReportDraft.swift), [`ContentView.swift`](projectreportingbuilder/projectreportingbuilder/ContentView.swift), [`ReportBuilderTests.swift`](projectreportingbuilder/projectreportingbuilderTests/ReportBuilderTests.swift), [`ReportWorkspaceUITests.swift`](projectreportingbuilder/projectreportingbuilderUITests/ReportWorkspaceUITests.swift) |
| FR-02 | Support optional percentage or milestone progress, contextual notes, deterministic calculations, and clear invalid-input feedback. | `PercentageMetric` validates 0–100. `MilestoneMetric` validates digit-only whole numbers, nonzero total, bounds, and completed ≤ total. Only the selected valid metric generates a KPI card. | **Implemented and verified** | [`PercentageMetric.swift`](projectreportingbuilder/projectreportingbuilder/PercentageMetric.swift), [`ReportDraft.swift`](projectreportingbuilder/projectreportingbuilder/ReportDraft.swift), [`OptionalProgressTests.swift`](projectreportingbuilder/projectreportingbuilderTests/OptionalProgressTests.swift), [`projectreportingbuilderTests.swift`](projectreportingbuilder/projectreportingbuilderTests/projectreportingbuilderTests.swift) |
| FR-03 | Import and preview a local PNG or JPEG while handling cancellation, replacement, unsupported data, and excessive size safely. | The native file importer delegates to `ImageImportService`; decoded original bytes and filename are retained. Limits are 20 MB and 40 megapixels. | **Implemented and verified** | [`ImageImportService.swift`](projectreportingbuilder/projectreportingbuilder/ImageImportService.swift), [`ContentView.swift`](projectreportingbuilder/projectreportingbuilder/ContentView.swift), [`projectreportingbuilderTests.swift`](projectreportingbuilder/projectreportingbuilderTests/projectreportingbuilderTests.swift), [`ReportInputUITests.swift`](projectreportingbuilder/projectreportingbuilderUITests/ReportInputUITests.swift) |
| FR-04 | Generate modular Summary, KPI/Progress, and Image Snippet Cards from the corresponding user inputs. | `ReportBuilder` creates a Summary, optionally one valid KPI, and optionally one Image card using the `SnippetCard` model and reusable rendering views. | **Implemented and verified** | [`ReportBuilder.swift`](projectreportingbuilder/projectreportingbuilder/ReportBuilder.swift), [`SnippetCard.swift`](projectreportingbuilder/projectreportingbuilder/SnippetCard.swift), [`SnippetCardViews.swift`](projectreportingbuilder/projectreportingbuilder/SnippetCardViews.swift), [`ReportBuilderTests.swift`](projectreportingbuilder/projectreportingbuilderTests/ReportBuilderTests.swift) |
| FR-05 | Provide a resizable two-pane workspace and a unified report preview with one project title and conditional Summary, Progress, and Image sections. | `ContentView` uses `HSplitView`; `UnifiedReportView` composes the generated Snippet Cards with shared spacing and dividers. | **Implemented and verified** | [`ContentView.swift`](projectreportingbuilder/projectreportingbuilder/ContentView.swift), [`SnippetCardViews.swift`](projectreportingbuilder/projectreportingbuilder/SnippetCardViews.swift), [`UnifiedReportTests.swift`](projectreportingbuilder/projectreportingbuilderTests/UnifiedReportTests.swift), resize coverage in [`ReportWorkspaceUITests.swift`](projectreportingbuilder/projectreportingbuilderUITests/ReportWorkspaceUITests.swift) |
| FR-06 | Copy and export both the complete report and individual Snippet Cards. | `CardSharingService` creates plain-text, RTF, and PNG clipboard representations and exports opaque PNG files through `NSSavePanel`. | **Implemented and verified** | [`CardSharingService.swift`](projectreportingbuilder/projectreportingbuilder/CardSharingService.swift), [`CardSharingTests.swift`](projectreportingbuilder/projectreportingbuilderTests/CardSharingTests.swift), [`UnifiedReportTests.swift`](projectreportingbuilder/projectreportingbuilderTests/UnifiedReportTests.swift), [`ReportWorkspaceUITests.swift`](projectreportingbuilder/projectreportingbuilderUITests/ReportWorkspaceUITests.swift) |
| FR-07 | Follow System appearance by default and persist optional Light or Dark overrides; keep exported PNGs legible in both appearances. | `AppAppearance` is stored with `@AppStorage`. Semantic colours drive views and explicit opaque backgrounds drive image rendering. | **Implemented and verified** | [`projectreportingbuilderApp.swift`](projectreportingbuilder/projectreportingbuilder/projectreportingbuilderApp.swift), [`AccessibleColors.swift`](projectreportingbuilder/projectreportingbuilder/AccessibleColors.swift), [`AppearanceTests.swift`](projectreportingbuilder/projectreportingbuilderTests/AppearanceTests.swift), [`CardSharingTests.swift`](projectreportingbuilder/projectreportingbuilderTests/CardSharingTests.swift), [`UnifiedReportTests.swift`](projectreportingbuilder/projectreportingbuilderTests/UnifiedReportTests.swift) |
| FR-08 | Keep generated output consistent with the inputs used at generation time, indicate later edits, and prevent stale snapshots from being saved. | `DraftRevision` tracks generated inputs. Sharing reads immutable generated cards, stale feedback is shown, and `ReportSaveEligibility` requires a fresh, unsaved preview. | **Implemented and verified** | [`ContentView.swift`](projectreportingbuilder/projectreportingbuilder/ContentView.swift), [`CardPreviewPanel.swift`](projectreportingbuilder/projectreportingbuilder/CardPreviewPanel.swift), [`ReportHistoryTests.swift`](projectreportingbuilder/projectreportingbuilderTests/ReportHistoryTests.swift), [`ReportWorkspaceUITests.swift`](projectreportingbuilder/projectreportingbuilderUITests/ReportWorkspaceUITests.swift) |
| FR-09 | Persist explicitly saved generated-report snapshots locally, list them newest first, and preserve managed image assets across store recreation. | `SavedReport` is Codable. `ReportStore` writes independent JSON records and separate image assets under Application Support; no automatic saving occurs. | **Implemented and verified** | [`SavedReport.swift`](projectreportingbuilder/projectreportingbuilder/SavedReport.swift), [`ReportStore.swift`](projectreportingbuilder/projectreportingbuilder/ReportStore.swift), [`ReportStoreTests.swift`](projectreportingbuilder/projectreportingbuilderTests/ReportStoreTests.swift) |
| FR-10 | Duplicate a saved report into a new editable draft without mutating its original snapshot, and warn before replacing unsaved editor work. | `ReportStore.draftForEditing` reconstructs the draft; `ReportHistoryView` requests confirmation when `DraftReplacementProtection` detects current work and clears generated output after replacement. | **Implemented; manual validation pending** | Conversion, lifecycle, and protection logic are covered by [`ReportStoreTests.swift`](projectreportingbuilder/projectreportingbuilderTests/ReportStoreTests.swift) and [`ReportHistoryTests.swift`](projectreportingbuilder/projectreportingbuilderTests/ReportHistoryTests.swift). [`ReportWorkspaceUITests.swift`](projectreportingbuilder/projectreportingbuilderUITests/ReportWorkspaceUITests.swift) verifies that the warning appears and can be cancelled; accepting the UI replacement remains a manual check. |
| FR-11 | Open saved reports read-only with supported Copy/Export actions and delete a selected report only after confirmation. | `ReportHistoryView` displays `ReportStore.ViewSnapshot` without replacing the editor. `ReportStore.delete` removes the selected record and its report-owned image. Missing images produce a controlled warning while usable sections remain available. | **Implemented and verified** | [`ReportHistoryView.swift`](projectreportingbuilder/projectreportingbuilder/ReportHistoryView.swift), [`ReportStoreTests.swift`](projectreportingbuilder/projectreportingbuilderTests/ReportStoreTests.swift), deletion flow in [`ReportWorkspaceUITests.swift`](projectreportingbuilder/projectreportingbuilderUITests/ReportWorkspaceUITests.swift) |

## 4. Non-functional Requirements

| Requirement ID | Area | Requirement and implementation | Status | Evidence / remaining validation |
| --- | --- | --- | --- | --- |
| NFR-01 | Accessibility | Use native controls, semantic colours, meaningful labels/identifiers, text equivalents, keyboard shortcuts, and output that is not colour-only. | **Implemented; manual validation pending** | Accessibility labels and identifiers appear throughout [`ContentView.swift`](projectreportingbuilder/projectreportingbuilder/ContentView.swift), [`CardPreviewPanel.swift`](projectreportingbuilder/projectreportingbuilder/CardPreviewPanel.swift), and [`ReportHistoryView.swift`](projectreportingbuilder/projectreportingbuilder/ReportHistoryView.swift). XCUI tests exercise identifiers and Command-Return. A live VoiceOver usability pass is not yet confirmed. |
| NFR-02 | Reliability | Empty or invalid input, corrupt images, cancelled export, missing history assets, and corrupt records must fail safely with usable feedback. | **Implemented and verified** | Validation and failure paths are covered by [`projectreportingbuilderTests.swift`](projectreportingbuilder/projectreportingbuilderTests/projectreportingbuilderTests.swift), [`CardSharingTests.swift`](projectreportingbuilder/projectreportingbuilderTests/CardSharingTests.swift), and [`ReportStoreTests.swift`](projectreportingbuilder/projectreportingbuilderTests/ReportStoreTests.swift). |
| NFR-03 | Usability | Keep primary input, generation, sharing, and history actions discoverable in a resizable macOS workspace. | **Implemented; manual validation pending** | Native controls, toolbar History action, empty states, progress feedback, and minimum-size UI automation are present. Broader keyboard-only and assistive-technology walkthroughs remain manual. |
| NFR-04 | Maintainability | Separate editable state, validation, deterministic transformation, view rendering, sharing, and persistence; avoid third-party dependencies. | **Implemented and verified** | `ReportDraft`, `ReportBuilder`, `SnippetCard`, `CardSharingService`, and `ReportStore` provide explicit boundaries. The Xcode project declares no package dependencies. |
| NFR-05 | Data integrity | Save only generated snapshots, avoid ID overwrite, retain original input values and image bytes, and isolate deletion to one report. | **Implemented and verified** | [`ReportStore.swift`](projectreportingbuilder/projectreportingbuilder/ReportStore.swift), [`ReportHistoryTests.swift`](projectreportingbuilder/projectreportingbuilderTests/ReportHistoryTests.swift), and [`ReportStoreTests.swift`](projectreportingbuilder/projectreportingbuilderTests/ReportStoreTests.swift). |
| NFR-06 | Local data handling | Process report inputs locally and store history in the user's Application Support directory; do not require external APIs or a backend. | **Implemented and verified by source inspection** | [`ReportStore.swift`](projectreportingbuilder/projectreportingbuilder/ReportStore.swift), [`ImageImportService.swift`](projectreportingbuilder/projectreportingbuilder/ImageImportService.swift), and the Xcode project configuration. This is not a production security or privacy certification. |
| NFR-07 | Portability / deployment | Build as a native macOS application using the shared scheme and documented toolchain baseline. | **Implemented and verified** | [`project.xcproj`](projectreportingbuilder/projectreportingbuilder.xcodeproj/project.xcproj) configures macOS 27.0, Swift, Debug/Release configurations, and native app/test targets; the project was last upgraded with Xcode 27.2. |
| NFR-08 | Testability | Keep calculations and storage deterministic, inject temporary store roots in tests, and cover core user flows with unit and UI tests. | **Implemented and verified** | Tests reside in [`projectreportingbuilderTests`](projectreportingbuilder/projectreportingbuilderTests) and [`projectreportingbuilderUITests`](projectreportingbuilder/projectreportingbuilderUITests). Latest reported result: **106 passed, 0 failed, 0 skipped**. |

## 5. Acceptance Criteria

| Requirement | Measurable acceptance criteria | Status |
| --- | --- | --- |
| FR-01 | Generation remains disabled until non-whitespace project name and update are present; the generated Summary preserves both values. | **Verified by unit and UI tests** |
| FR-02 | Progress may be skipped. A percentage from 0–100 is accepted. Milestones such as 12/15 render 80% and “12 of 15”; invalid, negative, zero-total, non-integer, oversized, or completed-over-total input cannot produce a misleading KPI. | **Verified by parameterized unit tests and UI tests** |
| FR-03 | A valid PNG or JPEG up to 20 MB and 40 megapixels can be imported, previewed, replaced, and retained after the source is unavailable; corrupt, unsupported, or oversized input returns a controlled error. | **Verified by unit and UI tests** |
| FR-04 | A generated report always contains Summary and adds KPI and Image sections only when corresponding valid input exists. No missing category blocks another valid section. | **Verified by unit tests** |
| FR-05 | Summary-only, Summary+Progress, and Summary+Progress+Image reports render under one project title; essential controls remain reachable at the supported minimum window size. | **Verified by unit and UI tests** |
| FR-06 | Copy produces readable text plus RTF and PNG clipboard representations. Complete reports and individual sections produce decodable PNG output; save-panel export writes the selected PNG atomically. | **Verified by unit tests; individual Summary save-panel flow verified by UI test** |
| FR-07 | System maps to no forced colour scheme, Light/Dark overrides persist, and light/dark exported PNGs use legible opaque backgrounds. | **Verified by unit tests; final visual review remains advisable** |
| FR-08 | Editing after generation leaves the visible snapshot unchanged, shows stale state, and disables Save Report until regeneration. Repeated saving of the same generation is disabled. | **Verified by unit and UI tests** |
| FR-09 | Saved reports survive `ReportStore` reinitialisation, appear newest first, preserve optional progress/note values, and keep image bytes outside JSON records. | **Verified by unit tests** |
| FR-10 | Duplicating reconstructs project text, selected progress mode, raw metric inputs, note, and image; editing and saving the duplicate creates another record while the original remains unchanged. Unsaved editor work requires confirmation before replacement. | **Logic verified; accepting the replacement in the live UI requires manual confirmation** |
| FR-11 | Selecting history opens a read-only snapshot without changing the current editor; Copy/Export remains available. Delete requires confirmation, removes only the selected record and its managed image, and leaves other reports intact. | **Verified by unit/UI tests; read-only Copy/Export should also receive a manual destination check** |

## 6. Requirement Status Summary

### Implemented and verified

- Manual project input, optional validated metrics, progress notes, and PNG/JPEG ingestion.
- Modular Snippet Cards and unified report composition.
- Individual and complete-report clipboard/PNG sharing.
- Persisted System/Light/Dark appearance choice and appearance-aware PNG rendering.
- Generated-snapshot consistency, stale-state detection, and save eligibility.
- Local Report History storage, restart persistence, newest-first ordering, read-only open, and isolated deletion.
- Corrupt-record and missing-image handling.

### Implemented but pending manual validation

- End-to-end acceptance of **Duplicate as New Draft** when it replaces current editor content; reconstruction and protection logic are automated, while the current UI test stops after confirming the warning can be cancelled.
- A live VoiceOver usability walkthrough and complete keyboard-only workflow.
- Final human visual review of every History and sharing state in both Light and Dark appearances.
- Pasting report output into representative external email and messaging clients.

### Deferred or out of scope

- AI-assisted summarisation, organisation, or card recommendations.
- Cloud sync, accounts, collaboration, and external project-management integrations.
- Advanced templates, historical comparisons, and trend charts.
- PDF, presentation, and document export formats.
- Production security certification, enterprise deployment, and quantitative performance guarantees.

## 7. Verification Baseline

The latest reported full regression result is **106 passed, 0 failed, 0 skipped** for the `projectreportingbuilder` test plan. This count includes expanded parameterized Swift Testing cases and macOS XCUI tests.

The project configuration establishes:

- macOS deployment target: **27.0**
- Project upgrade/toolchain baseline: **Xcode 27.2**
- Shared scheme: **`projectreportingbuilder`**
- Unit test framework: **Swift Testing**
- UI test framework: **XCTest/XCUIAutomation**

No claim is made that live VoiceOver behavior, production security, cloud readiness, or enterprise-scale performance has been fully validated.
