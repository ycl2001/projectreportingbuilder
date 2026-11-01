# Architecture — Proposed

**Status: Proposed.** This model/view/service design targets a three-day macOS PoC. Only the starter SwiftUI application and test scaffolding have been inspected; the reporting components below are not implemented or verified.

## Proposed Application Structure

Keep the existing Xcode project and app entry point. Add small model, view and service files inside the existing source directory only as implementation needs them. No additional targets, packages or infrastructure are proposed.

- Models: draft input, validated card content and metric values.
- Views: input editor, reusable card view, preview and sharing controls.
- Services: image loading, card rendering, clipboard copying and PNG export.

Start with SwiftUI presentation state. Introduce one editor view model only if validation and orchestration become too complex for a simple view composition.

## SwiftUI Components

- `ContentView`: hosts the editor, preview and sharing controls.
- Proposed `SnippetEditorView`: text, metric and image inputs with inline validation.
- Proposed `SnippetCardView`: reusable presentation of validated card content.
- Proposed sharing controls: copy/export actions and success/error feedback.

Support window resizing, keyboard navigation and accessibility labels. Give exports deliberate dimensions independent of the editor window size.

## Data Models

Use lightweight Swift value types:

- `SnippetDraft`: editable title/body, raw metric strings and an optional imported image.
- `Metric`: validated numbers, labels and calculated values where applicable.
- `SnippetCard`: validated text, formatted metrics and optional image for rendering.
- Validation results: field-specific messages for the editor.

Separate editable input from validated output so partial numeric entry cannot produce misleading calculations. Keep draft/image data in memory initially; no database is proposed.

## Input Processing and Validation

Validate required content and parse numbers using a documented locale policy. Reject invalid or non-finite results. Define formulas, units and rounding before implementation; handle zero denominators explicitly. Establish text and image size limits during implementation and display actionable feedback.

Decode supported images before accepting them. Handle unsupported/corrupt files and picker cancellation without losing the draft. Keep parsing and calculations in pure functions suitable for unit tests.

## Snippet Card Generation

Convert a valid draft into `SnippetCard` data and render it through the same card view used for preview. Choose an explicit output size, scale and background for consistent sharing. Verify the rendering API against the project's supported macOS versions during implementation.

## Clipboard and Export Services

- Rendering service: produces an image from the reusable card view.
- Clipboard service: publishes that image through the native macOS pasteboard.
- PNG export service: presents a destination picker, encodes PNG and writes the chosen file.

Keep platform I/O outside the card view. Report rendering and write failures in the editor; cancellation preserves input. Respect sandbox file access when enabled.

## Data Flow

```text
Text / metrics / selected image
              ↓
         Editable draft
              ↓
   Validation and calculations → Field errors
              ↓
     Validated SnippetCard
              ↓
      Reusable card preview
              ↓
       Shared image render
           ↙         ↘
      Clipboard     PNG file
```

## Key Technical Decisions

- Prefer native UI and small platform services without third-party dependencies.
- Reuse one card layout for preview and sharing.
- Isolate calculations from UI and file operations for focused tests.
- Keep UI state on the main actor; use async/await for asynchronous work where needed.
- Defer persistence, networking and multiple templates.
- Add abstractions only to test platform boundaries or remove duplication.

Update this document to describe implemented behavior only after code and testing have been verified.
