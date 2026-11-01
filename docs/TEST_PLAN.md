# Test Plan

This template covers the proposed PoC. Reporting features are not yet implemented, and no cases below have been executed. `Not Run` does not indicate a pass.

## Execution Details

- Date / tester: —
- Commit / build: —
- macOS / Xcode version: —
- Hardware / display scale: —
- Locale / appearance / accessibility settings: —

Use Swift Testing for calculations and validation, XCUIAutomation for suitable UI flows, and manual checks for output quality, pasteboard interoperability and accessibility. Existing test scaffolding does not establish functional coverage.

## Test Cases

| Test case ID | Description | Expected result | Actual result | Status |
| --- | --- | --- | --- | --- |
| TXT-01 | Enter a title and multiline body. | Preview preserves content and intended line breaks. | — | Not Run |
| TXT-02 | Enter Unicode, emoji and long text. | Text remains readable; agreed wrapping or length validation prevents overflow. | — | Not Run |
| MET-01 | Enter valid values for each implemented metric formula. | Results match independently calculated examples and documented rounding. | — | Not Run |
| MET-02 | Use zero, negative, decimal and large values. | Valid values calculate correctly; invalid ranges and zero denominators produce clear feedback. | — | Not Run |
| MET-03 | Enter malformed numbers and locale-specific separators. | Parsing follows the documented locale policy and flags invalid input. | — | Not Run |
| IMG-01 | Import a supported local image. | Image appears with correct orientation and intended aspect ratio. | — | Not Run |
| IMG-02 | Import a corrupt, unsupported or oversized image. | Useful feedback appears; the app remains usable and retains the draft. | — | Not Run |
| IMG-03 | Cancel image selection. | Existing draft and image remain unchanged. | — | Not Run |
| CARD-01 | Preview text, metrics and an image together. | Content is correctly formatted without clipping or overlap. | — | Not Run |
| CARD-02 | Preview supported combinations of optional content. | Layout adapts cleanly and missing required content is identified. | — | Not Run |
| CLIP-01 | Copy a card and paste into an image-capable macOS app. | Pasted image matches card content and intended dimensions. | — | Not Run |
| CLIP-02 | Attempt copying invalid content or simulate rendering failure. | Sharing is prevented or an error appears; success is not falsely reported. | — | Not Run |
| PNG-01 | Export a card and open the PNG in Preview. | File decodes correctly with intended content, dimensions, scale and background. | — | Not Run |
| PNG-02 | Cancel export or choose an existing filename. | Cancellation preserves the draft; replacement follows save-dialog confirmation behavior. | — | Not Run |
| PNG-03 | Simulate a failed file write. | Useful error feedback appears and the draft is retained. | — | Not Run |
| VAL-01 | Leave required input empty or whitespace-only. | Field feedback identifies missing content and prevents invalid output. | — | Not Run |
| VAL-02 | Correct invalid input. | Errors clear and valid preview/sharing becomes available. | — | Not Run |
| WIN-01 | Resize from the supported minimum to a large window. | Inputs and actions remain reachable without unintended clipping or overlap. | — | Not Run |
| WIN-02 | Export the same card at different editor window sizes. | Output size and layout remain consistent with export policy. | — | Not Run |
| A11Y-01 | Navigate and activate controls using only the keyboard. | Focus order is logical and visible; controls work without focus traps. | — | Not Run |
| A11Y-02 | Use VoiceOver for inputs, validation and sharing. | Controls have meaningful labels; values and feedback are discoverable. | — | Not Run |
| A11Y-03 | Inspect light/dark appearance, Increase Contrast and supported text scaling. | Content remains readable and status is not conveyed by color alone. | — | Not Run |

## Result Recording

Use `Not Run`, `Pass`, `Fail` or `Blocked`. Replace actual results with observed behavior and reference evidence or defect notes. Record chosen formulas, limits and export dimensions with test fixtures before executing affected cases. Summarize failures and untested areas in the later implementation report.
