# Project Reporting Builder — Proof of Concept Requirements

> **Project type:** Apple IS&T take-home assessment · macOS proof of concept (PoC)  
> **Planned implementation:** Swift + SwiftUI  
> **Delivery window:** 2–4 November 2026 (three days; confirm the recruiter's exact submission time)  
> **Document status:** Implementation requirements derived from the supplied assessment brief

## 1. Assessment brief

Build a lightweight, responsive **Project Reporting Builder** that helps enterprise users transform diverse project updates into modular, visually polished, accessible **Snippet Cards** that can be copied or exported for sharing in email or messaging tools.

The recruiter explicitly requests:

1. A **working PoC** implemented as either a web or macOS tool.
2. Support for **raw text, metric data, and image assets**.
3. Transformation of the inputs into **modular Snippet Cards**.
4. **Visually polished, accessible** card output and a responsive interface.
5. The ability to **copy or export** cards for direct sharing.
6. A **15-minute English presentation** explaining the design, ideas, and implementation.
7. Evidence of **engineering excellence**, including documentation, configuration, testing, and coding conventions.

**Good-to-have (not mandatory):** styled UI, consideration of cloud deployment technologies, and thoughtful enhancements that surprise and delight users.

## 2. Problem statement

Project managers and cross-functional teams receive updates as scattered notes, performance numbers, and screenshots. Preparing a consistent progress report requires manual formatting and repeated copying between tools.

**The PoC aims to demonstrate that a user can turn these three input types into consistent, reusable reporting cards through one lightweight workflow.**

### Target user

An enterprise project manager, product manager, or engineering team lead preparing a weekly status report for stakeholders.

### Primary user story

> As a project manager, I want to enter project notes, milestone metrics, and an image so that I can generate polished reporting cards and share them without manually laying out the report.

## 3. Scope and priorities

The implementation below is the **chosen three-day PoC scope**, not an additional set of obligations stated by Apple.

| Priority | Scope | Decision |
| --- | --- | --- |
| P0 — Required for demo | Input raw notes, metric data, and one image | Implement |
| P0 — Required for demo | Produce three reusable card types | Implement |
| P0 — Required for demo | Working card copy **or** export into a usable format | Implement |
| P0 — Required for demo | Input validation, basic accessibility, responsive layout | Implement |
| P0 — Required for demo | Basic automated tests, README, reproducible setup | Implement |
| P0 — Required for submission | 15-minute presentation and live demo | Prepare |
| P1 — Strongly preferred | Both plain-text copy and PNG export | Implement if core P0 is stable |
| P1 — Preferred | Editing input and regenerating a card | Implement |
| P2 — Optional | Additional card styles, themes, custom templates | Defer |
| P2 — Optional | AI-assisted summarisation / agentic workflow | Defer; describe future approach |
| Out of scope | Login, enterprise database, collaboration, cloud backend, PDF generation | Do not build |

## 4. Functional requirements

### FR-01 — Text input

- Provide a multiline field for raw project progress notes.
- Preserve the user's entered content without inventing new facts.
- Support editing and regenerating the summary card.
- Handle empty input gracefully (show guidance or omit that card).

**Acceptance criteria**

- [ ] A user can type or paste project notes.
- [ ] Generating a Summary Card reflects the entered content.
- [ ] Changing the notes updates the card when regenerated.
- [ ] Empty input does not cause a crash or misleading content.

### FR-02 — Metric input

- Accept a metric title, completed value, and total value.
- Calculate and display a percentage when the total is greater than zero.
- Reject or clearly explain invalid values (e.g., nonnumeric, negative, completed > total, or total = 0 for progress calculations).
- Show both the percentage and original numbers so information is not conveyed by colour alone.

**Acceptance criteria**

- [ ] Input of `12` completed and `15` total displays `80%` and `12 of 15`.
- [ ] Editing the values changes the rendered result.
- [ ] Invalid values receive a clear message and do not generate an incorrect progress result.

### FR-03 — Image ingestion

- Let the user select a local PNG or JPEG image.
- Preview the image in an Image Card.
- Support an editable image caption or description.
- Handle cancellation and invalid files without crashing.

**Acceptance criteria**

- [ ] A user can select a supported local image.
- [ ] The card displays the selected image and caption.
- [ ] The caption remains available in text-based sharing output.

### FR-04 — Snippet Card generation

Implement three modular templates:

1. **Summary Card:** project title or update heading plus text content.
2. **KPI/Progress Card:** metric label, current/total values, calculated percentage, and progress indicator.
3. **Image Card:** uploaded visual with a caption.

Use deterministic transformations and reusable data models. AI is **not required** for the PoC.

**Acceptance criteria**

- [ ] The user can generate a card from each of the three input types.
- [ ] Cards display the corresponding user-supplied information accurately.
- [ ] Cards have consistent spacing, type hierarchy, and styling.
- [ ] A missing input does not prevent other valid cards from rendering.

### FR-05 — Preview and responsive layout

- Use one macOS application window with an input area and a card-preview area.
- Accommodate window resizing by adapting widths, wrapping, or stacking content as appropriate.
- Avoid clipped essential content at the supported minimum window size.

**Acceptance criteria**

- [ ] Inputs and cards are visible in a normal desktop window.
- [ ] The layout remains usable when the window is resized.
- [ ] Longer notes wrap or scroll appropriately rather than overflowing.

### FR-06 — Copy and export

- **Minimum demonstration:** offer a real Copy **or** Export function for a generated card.
- **Planned PoC implementation:** copy a clear plain-text representation; if time allows, also export the rendered card as a PNG.
- Preserve the critical text, labels, values, and image captions in the text fallback.
- Allow users to save a PNG to a chosen location if PNG export is implemented.
- Show understandable feedback when copying or exporting fails.

**Acceptance criteria**

- [ ] Copying a Summary or KPI card produces accurate, readable clipboard content.
- [ ] Pasting the clipboard content into a test destination (e.g., Notes or an email draft) works.
- [ ] If PNG export is implemented, the saved file opens and reflects the selected card.
- [ ] Any limitations in destination compatibility are documented.

## 5. Non-functional requirements

### NFR-01 — Accessibility

- Add meaningful labels and accessible names to form controls and actions.
- Support keyboard navigation, including visible focus where applicable.
- Use legible typography and adequate contrast; do not rely on colour alone.
- Provide text alternatives or captions for meaningful image content.
- Test core flows with VoiceOver and keyboard interaction.
- Consider accessible output: a PNG alone is not an equivalent substitute for text-based sharing.

**Acceptance criteria**

- [ ] Core controls have understandable accessible labels.
- [ ] The main flow can be completed using a keyboard.
- [ ] Key information remains available as text.

### NFR-02 — Reliability and validation

- Do not crash on empty text, invalid numeric input, cancelled file selection, or export failure.
- Keep numeric calculations deterministic and testable.
- Show user-facing error messages for recoverable failures.

### NFR-03 — Maintainability

- Separate input views, card models, transformation logic, and clipboard/export services.
- Use clear Swift naming and consistent coding conventions.
- Keep business logic out of large view bodies where practical.
- Avoid hardcoded secrets and unnecessary third-party dependencies.

### NFR-04 — Privacy and security

- Process inputs locally for this PoC.
- Do not upload user-entered content or images to a remote service.
- Avoid logging potentially sensitive report content.
- Use fabricated demo project information rather than real confidential material.

### NFR-05 — Performance

- Card generation and preview updates should feel immediate with typical short project updates and reasonable image sizes.
- No quantitative production performance service-level objective is claimed for the PoC.

## 6. Proposed technical architecture

**Platform:** macOS  
**Language:** Swift  
**UI:** SwiftUI  
**Clipboard:** `NSPasteboard` (AppKit interop)  
**Image selection:** native file importer / file picker  
**PNG output:** SwiftUI render-to-image approach as supported by the target macOS SDK  
**Tests:** Swift Testing or XCTest  
**Source control:** Git / GitHub

```text
User input (notes, numbers, image)
              |
              v
     Validation + data models
              |
              v
    Deterministic card builder
              |
              v
    Reusable SwiftUI card views
              |
       +------+------+
       |             |
   Clipboard      PNG export
   (text)         (if built)
```

### Suggested repository structure

```text
ProjectReportingBuilder/
├── README.md
├── REQUIREMENTS.md
├── ProjectReportingBuilder.xcodeproj
├── ProjectReportingBuilder/
│   ├── App/
│   ├── Models/
│   ├── Views/
│   └── Services/
├── ProjectReportingBuilderTests/
└── Docs/
    ├── Architecture.md
    └── TestPlan.md
```

> Adapt the folder structure to the real Xcode project; avoid creating empty files solely to match this diagram.

## 7. Testing requirements

### Automated tests (minimum)

| Test ID | Scenario | Expected result |
| --- | --- | --- |
| T-01 | 12 completed / 15 total | 80%, showing original values |
| T-02 | Completed > total or total = 0 | Validation result, no misleading percentage |
| T-03 | Nonempty project notes | Summary Card retains supplied content |
| T-04 | Empty notes | Safe empty state or card omitted |

### Manual acceptance tests

- [ ] Launch the app following README instructions.
- [ ] Enter text, metrics, and an image; generate three accurate cards.
- [ ] Change inputs and regenerate without stale information.
- [ ] Copy content and paste into Notes or an email draft.
- [ ] If implemented, export a PNG and reopen the file.
- [ ] Resize the window and verify no critical clipping.
- [ ] Navigate the essential flow using a keyboard and VoiceOver.
- [ ] Verify errors for unsupported images and invalid metrics.

## 8. Three-day implementation plan

### Day 1 — Monday, 2 November: working vertical slice

- [ ] Initialise Xcode project and Git repository.
- [ ] Define minimal models and validation rules.
- [ ] Create raw text, metric, and image input controls.
- [ ] Create Summary, KPI, and Image Card views.
- [ ] Connect inputs to a Generate action and card preview.
- [ ] Confirm all three input types display correctly; commit working code.

**Exit criterion:** a user can enter all three input types and produce three non-hardcoded cards.

### Day 2 — Tuesday, 3 November: sharing and testing

- [ ] Implement and verify clipboard output.
- [ ] Implement PNG export if feasible without risking the minimum workflow.
- [ ] Add numeric validation and error states.
- [ ] Write and run key unit tests.
- [ ] Check resized layouts, keyboard access, and basic VoiceOver labels.
- [ ] Freeze features after the end-to-end workflow works.

**Exit criterion:** card output is shareable outside the application, with tested core logic.

### Day 3 — Wednesday, 4 November: delivery and presentation

- [ ] Run a final regression pass and fix critical issues.
- [ ] Finish README and technical design/limitations documentation.
- [ ] Capture screenshots and a fallback demo recording if feasible.
- [ ] Create six or seven presentation slides.
- [ ] Rehearse a 15-minute English presentation.
- [ ] Verify a clean build, repository contents, and submission materials.

**Exit criterion:** a reviewer can run, understand, and evaluate the PoC and watch a complete demonstration.

## 9. Presentation requirements (15 minutes, English)

| Segment | Time | Evidence |
| --- | ---: | --- |
| Problem and enterprise user | 1:30 | Reporting pain point and user story |
| Product vision and scoped solution | 1:30 | Intended workflow and design decisions |
| Live demo | 5:00 | Input → Generate → Copy/Export |
| Architecture and trade-offs | 3:00 | Data flow, modularity, platform choice |
| Engineering excellence | 2:00 | Tests, accessibility, configuration, documentation |
| Limitations, roadmap, conclusion | 2:00 | Honest PoC boundaries and next priorities |
| **Total** | **15:00** | |

### Suggested demo data

- **Project:** Atlas Mobile Release
- **Notes:** Sprint 4 completed; security approval remains pending; next step is regression testing.
- **Metric:** 12 out of 15 milestones completed (80%).
- **Image:** a fabricated product screenshot with a descriptive caption.

### Potential follow-up questions

Be ready to explain why SwiftUI was chosen, how the metric is validated, how sharing was tested, what accessibility considerations apply to PNG output, and what would change for enterprise production deployment.

## 10. Submission checklist

- [ ] Runnable macOS SwiftUI PoC.
- [ ] Accessible project source code in GitHub or the specified submission channel.
- [ ] `README.md` with setup, run, test, and known-limitations instructions.
- [ ] `REQUIREMENTS.md` describing scope and acceptance criteria.
- [ ] Automated test results or clear test instructions.
- [ ] Architecture diagram or concise design explanation.
- [ ] Presentation deck and prepared 15-minute English walkthrough.
- [ ] Demo data and optional backup video.

## 11. Explicitly deferred work

The following are **not required for this three-day PoC** and should be discussed only as possible future improvements:

- AI-generated summaries, multi-agent orchestration, and external LLM integrations.
- Cloud hosting or backend services.
- Authentication, role-based access, and team collaboration.
- Persistent multi-project storage and report history.
- PDF, Word, PowerPoint, and comprehensive rich-HTML export.
- Integration with Jira, Slack, Teams, or enterprise email services.
- Production security review, large-scale performance testing, and enterprise rollout.

## 12. Success definition

The PoC is successful if a reviewer can **enter raw text, a metric, and an image; generate accurate, consistent and accessible reporting cards; and use at least one working sharing mechanism to reuse the output outside the app**.

It should also be straightforward to explain **how the code is organised, what was tested, why trade-offs were made, and what is intentionally not production-ready**.

---

*Requirement interpretation note: The assessment permits web **or** macOS. SwiftUI, three specific card templates, and the proposed implementation order are project choices designed for the three-day timeline, not explicit recruiter mandates.*
