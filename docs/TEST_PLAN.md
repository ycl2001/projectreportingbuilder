# Project Reporting Builder — Test Plan and Verification Record

## Document Status

This document describes the implemented automated coverage and remaining manual verification for `feat/report-history`. It is not a list of proposed features.

The latest reported full regression result is:

**106 passed, 0 failed, 0 skipped.**

This result covers the `projectreportingbuilder` test plan and includes expanded parameterized Swift Testing cases and macOS XCUI tests. The suite was not rerun solely for this documentation update.

## Test Environment and Configuration

| Item | Verified configuration |
| --- | --- |
| Platform | Native macOS application |
| Deployment target | macOS 27.0 |
| Latest reported environment | macOS 27.2, Xcode 27.2, macOS 27.2 SDK |
| Scheme / test plan | `projectreportingbuilder` |
| Unit-test framework | Swift Testing |
| UI-test framework | XCTest and XCUIAutomation |
| Dependencies | Apple platform frameworks only; no third-party test dependencies |

The project defines 49 test functions in Xcode's test list. Parameterized Swift Testing functions expand those definitions into the 106 reported test executions.

## How to Run

In Xcode, select the shared `projectreportingbuilder` scheme, choose **My Mac**, and use **Product > Test** (Command-U).

From the repository root:

```sh
xcodebuild test \
  -project projectreportingbuilder/projectreportingbuilder.xcodeproj \
  -scheme projectreportingbuilder \
  -destination 'platform=macOS'
```

Record the macOS/Xcode versions, commit, appearance, locale, result bundle, and any manual settings when creating a new verification baseline.

## Automated Test Inventory

### Unit tests

| Test file | Primary coverage | Related requirements |
| --- | --- | --- |
| [`projectreportingbuilderTests.swift`](../projectreportingbuilder/projectreportingbuilderTests/projectreportingbuilderTests.swift) | Milestone parsing and validation, raw draft preservation, source-independent image bytes, corrupt/unsupported/oversized image rejection. | FR-01, FR-02, FR-03; NFR-02 |
| [`OptionalProgressTests.swift`](../projectreportingbuilder/projectreportingbuilderTests/OptionalProgressTests.swift) | `PercentageMetric` boundaries/precision, optional progress, invalid estimates, and switching between progress modes without using inactive values. | FR-02, FR-04 |
| [`ReportBuilderTests.swift`](../projectreportingbuilder/projectreportingbuilderTests/ReportBuilderTests.swift) | Source preservation, milestone accuracy, invalid-metric omission, missing text behavior, and image payload handling. | FR-01, FR-02, FR-04; NFR-05 |
| [`CardSharingTests.swift`](../projectreportingbuilder/projectreportingbuilderTests/CardSharingTests.swift) | Plain-text context, percentage formatting, clipboard text/RTF/PNG representations, failure atomicity, fixed rendering behavior, and opaque Light/Dark backgrounds. | FR-06, FR-07; NFR-02 |
| [`UnifiedReportTests.swift`](../projectreportingbuilder/projectreportingbuilderTests/UnifiedReportTests.swift) | Summary-only, Summary+Progress, and all-section report text; combined clipboard data; Light/Dark report PNGs; image aspect ratio. | FR-04, FR-05, FR-06, FR-07 |
| [`AppearanceTests.swift`](../projectreportingbuilder/projectreportingbuilderTests/AppearanceTests.swift) | System/Light/Dark mapping and safe fallback for an unknown stored preference. | FR-07 |
| [`ReportStoreTests.swift`](../projectreportingbuilder/projectreportingbuilderTests/ReportStoreTests.swift) | Save/reload, store reinitialisation, newest-first dates, optional progress modes/notes, original image assets, draft conversion, deletion isolation, corrupt records/images, collision prevention, lifecycle reuse, and missing-image read-only fallback. | FR-09, FR-10, FR-11; NFR-02, NFR-05, NFR-06 |
| [`ReportHistoryTests.swift`](../projectreportingbuilder/projectreportingbuilderTests/ReportHistoryTests.swift) | Unsaved-editor replacement protection and eligibility rules for saving only a fresh, not-yet-saved generated preview. | FR-08, FR-10; NFR-05 |

### UI tests

| Test file / flow | Automated behavior exercised | Related requirements |
| --- | --- | --- |
| [`ReportInputUITests.swift`](../projectreportingbuilder/projectreportingbuilderUITests/ReportInputUITests.swift) | Project input and image import/replacement behavior through the macOS interface. | FR-01, FR-03 |
| `testGenerationValidationAndSnapshotRefresh` in [`ReportWorkspaceUITests.swift`](../projectreportingbuilder/projectreportingbuilderUITests/ReportWorkspaceUITests.swift) | Required input, Summary-only generation, unified preview, milestone validation, Command-Return generation, stale snapshot preservation/regeneration, and minimum-window resizing. | FR-01, FR-02, FR-05, FR-08; NFR-01, NFR-03 |
| `testOptionalPercentageAndMethodSwitching` | Percentage validation, progress notes, milestone calculations, progress-source labels, mode switching, and generation with progress skipped. | FR-02, FR-04 |
| `testCopyAndExportSummary` | Individual-card Copy feedback, native save-panel PNG export, exported-file existence, and export cancellation. | FR-06; NFR-02 |
| `testHistorySaveProtectionAndDeletion` | Explicit save feedback, duplicate-save prevention, stale-save disabling, History navigation, unsaved-work warning, cancellation, delete confirmation, and list refresh. | FR-08, FR-09, FR-10, FR-11 |
| [`projectreportingbuilderUITests.swift`](../projectreportingbuilder/projectreportingbuilderUITests/projectreportingbuilderUITests.swift) | Basic launch and launch-performance scaffolding. | Supporting coverage only; no quantitative performance requirement is inferred. |

## Requirement Coverage Matrix

| Requirement | Automated evidence | Coverage status |
| --- | --- | --- |
| FR-01 Project text input | Draft, builder, and workspace UI tests preserve and regenerate typed/pasted content. | **Covered** |
| FR-02 Numeric metrics and validation | Parameterized percentage/milestone validation plus UI error and switching flows. | **Covered** |
| FR-03 Image ingestion | Decode/limit tests and image import/replacement UI flow. | **Covered** |
| FR-04 Modular Snippet Card generation | Builder and unified-report combination tests. | **Covered** |
| FR-05 Responsive workspace and unified preview | Unified-report tests and minimum-window XCUI resize flow. | **Covered; broader visual review remains manual** |
| FR-06 Clipboard and PNG export | Clipboard representation, rendering, aspect-ratio, and individual Summary save-panel tests. | **Covered; external destination interoperability remains manual** |
| FR-07 Appearance preferences | Preference mapping and Light/Dark opaque PNG rendering tests. | **Covered; final human visual review remains manual** |
| FR-08 Generated-report snapshot consistency | Draft-revision, stale-preview, save-eligibility, and XCUI stale-state flows. | **Covered** |
| FR-09 Local Report History | Store restart, ordering, progress/image persistence, and explicit-save UI flow. | **Covered** |
| FR-10 Duplicate previous report | Draft reconstruction, full save→restart→open→duplicate→edit→generate→save lifecycle, and unsaved-change protection. | **Logic covered; accepting replacement through the UI remains manual** |
| FR-11 Open and delete saved reports | Read-only snapshot/missing-image tests, isolated deletion tests, and confirmed-delete XCUI flow. | **Covered; read-only sharing to an external destination remains manual** |

## Detailed Coverage

### Input validation and deterministic generation

Automated cases verify:

- Empty or whitespace-only project information cannot enable generation.
- Raw project text is retained without invented content.
- Percentage input accepts valid 0–100 values and rejects missing, malformed, non-finite, or out-of-range values.
- Milestones reject missing values, non-digits, decimals, signs, oversized integers, zero total, and completed greater than total.
- Progress can be skipped without blocking Summary generation.
- Switching progress modes preserves user input but generates only the selected valid metric.
- Generated percentages and milestone counts remain deterministic.
- PNG/JPEG input is decoded rather than trusted by extension and is bounded by byte and pixel limits.

### Unified reports, Copy, and Export

Automated cases verify:

- Summary-only, Summary+Progress, and Summary+Progress+Image combinations.
- Complete-report text retains project title, narrative, metric source, values, notes, and image filename.
- Individual and complete-report clipboard data includes plain text, RTF, and decodable PNG.
- A failed share preparation does not replace prior clipboard contents.
- Light and Dark PNG output is opaque and uses appearance-specific backgrounds.
- Unified PNG height grows as sections are added.
- Imported images retain their intended aspect ratio.
- Individual Summary export writes a PNG through the native save panel; cancelling export does not report success.

The automated suite does not demonstrate paste behavior in every email or messaging client, nor does the UI suite drive the complete-report save panel.

### Snapshot consistency

Automated unit and UI coverage verifies that:

- Generated output remains unchanged while newer draft edits are pending.
- The interface exposes an out-of-date state.
- Reverting inputs to the generated revision clears that state.
- Regeneration replaces the snapshot with current valid input.
- Save Report requires an existing, current, not-already-saved generation.
- Saved snapshots are made from generated cards, not newer ungenerated draft input.

### History persistence and draft reuse

[`ReportStoreTests.swift`](../projectreportingbuilder/projectreportingbuilderTests/ReportStoreTests.swift) covers:

- Saving and loading an independent Codable report record.
- Persistence after constructing a new `ReportStore` for the same directory.
- Multiple creation dates sorted newest first.
- No-progress, percentage, and milestone snapshots with contextual notes.
- Original image bytes stored in a separate managed asset rather than JSON.
- Conversion of raw persisted values back into an editable `ReportDraft`.
- Deleting one record and image without damaging another.
- Skipping corrupt JSON records while retaining readable records.
- Controlled missing/corrupt-image errors and read-only fallback.
- Refusing to overwrite an existing UUID.
- The Save → Restart → Open → Duplicate → Edit → Generate → Save lifecycle while preserving the original snapshot.

[`ReportHistoryTests.swift`](../projectreportingbuilder/projectreportingbuilderTests/ReportHistoryTests.swift) covers replacement warnings and save eligibility. The History XCUI test verifies the warning appears, can be cancelled, and deletion refreshes the list. It does not accept the duplicate confirmation and then inspect the populated editor; that final UI path remains a manual check even though draft reconstruction is covered at the store level.

## Manual Verification Record

No standalone live manual test session is recorded as passed by this document. The latest reported evidence consists of automated unit tests, macOS XCUI tests, source inspection, and a successful application build reported alongside the 106-test regression.

The following observations come from automation and must not be treated as a complete human accessibility or interoperability review:

- XCUIAutomation launched the macOS app and exercised native text fields, text views, buttons, radio controls, sheets, alerts, the save panel, resizing, and keyboard generation.
- UI tests captured a resized-workspace screenshot and an exported Summary PNG as test attachments.
- Unit rendering tests inspected PNG dimensions, opacity, appearance differences, and image proportions.

## Outstanding Manual Checks

| Manual check ID | Procedure | Expected result | Status |
| --- | --- | --- | --- |
| MAN-A11Y-01 | Complete the core workflow using keyboard navigation only, including image import, individual/report sharing, History selection, duplicate confirmation, and deletion. | Logical visible focus order, no focus traps, and all required actions reachable. | **Not run / not confirmed** |
| MAN-A11Y-02 | Use VoiceOver for the editor, validation messages, unified preview, sharing feedback, History list, read-only snapshot, confirmations, and empty/error states. | Meaningful names, values, traits, grouping, and announcements throughout. | **Not run / not confirmed** |
| MAN-A11Y-03 | Review System, Light, and Dark appearances with Increase Contrast and relevant macOS accessibility display settings. | Text and controls remain legible; status is not communicated by colour alone. | **Partially automated; manual review not confirmed** |
| MAN-DUP-01 | Create unsaved editor changes, choose a saved report, accept **Replace and Duplicate**, then inspect all editor fields and regenerate. | Saved text, progress mode/raw values, note, and image populate the draft; preview requires regeneration; original history record remains unchanged. | **Logic automated; UI acceptance not confirmed** |
| MAN-SHARE-01 | Copy complete and individual reports into representative messaging and email clients. | A supported text, RTF, or PNG representation pastes with critical content intact. | **Not run / not confirmed** |
| MAN-SHARE-02 | Export a complete report and each individual section in both Light and Dark appearances, then open the files in Preview. | Files decode, remain legible, include available content, and preserve image proportions. | **Rendering automated; complete manual save/open matrix not confirmed** |
| MAN-HIST-01 | Open a saved read-only snapshot and use its Copy/Export controls without modifying the current editor. | Sharing succeeds and the editor retains its prior values. | **Source/unit evidence present; live manual check not confirmed** |
| MAN-ROBUST-01 | Exercise empty history, a missing managed image, and a corrupt record in a disposable Application Support directory. | Empty/error states remain usable; valid reports remain visible; no crash occurs. | **Store behavior automated; live UI check not confirmed** |

## Diagnostics and Known Verification Limitations

- There are no unresolved application build or automated-test failures in the latest reported regression: **106 passed, 0 failed, 0 skipped**.
- Live VoiceOver usability has not been verified. Source-level labels/identifiers and XCUI element lookup are accessibility foundations, not proof of a complete VoiceOver experience.
- Automated device-interaction inspection was unavailable for the macOS run destination in the verification environment, so no device-tool accessibility hierarchy or live Light/Dark screenshot audit is claimed.
- Clipboard tests use isolated `NSPasteboard` instances; destination-specific behavior in Outlook, Teams, Slack, Mail, or other applications remains outside automated coverage.
- The individual Summary export save-panel flow is automated. Complete-report and every-section save-panel permutations are validated primarily at the rendering/data layer, not through every UI dialog path.
- Duplicate reconstruction is unit-tested, but the current History UI test cancels the replacement warning rather than accepting it.
- AI-assisted reporting is deferred and absent from the application, so it is not part of the product regression baseline.
- Launch performance scaffolding exists, but no production performance target or statistically meaningful performance result is claimed.
- Persistence tests cover current Codable records; schema migration across future incompatible model versions is not implemented or tested.

## Regression Checklist

Before submission or after a functional change:

1. Confirm the active branch and cleanly identify unrelated local changes.
2. Build the `projectreportingbuilder` scheme for **My Mac**.
3. Run the complete test plan and record passed, failed, skipped, and expected-failure counts.
4. If sharing, appearance, history, or accessibility code changed, run the corresponding outstanding manual checks.
5. Record the macOS/Xcode/SDK versions and preserve the result bundle for failures.
6. Update the verification baseline only with observed results; do not carry a prior pass count forward as if it were newly executed.

## Result Vocabulary

- **Passed:** The test was executed and observed to meet its expected result.
- **Failed:** The test was executed and did not meet its expected result.
- **Blocked:** The test could not run because of an identified environment or dependency limitation.
- **Not run / not confirmed:** No sufficient execution evidence exists.
- **Covered:** Automated evidence exists for the stated requirement, but explicitly listed manual gaps still apply.
