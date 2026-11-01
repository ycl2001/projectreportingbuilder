# Project Reporting Builder

## Project Overview

A native macOS proof of concept for an Apple IS&T take-home assessment. The intended application transforms raw text, numerical metrics and image assets into reusable, visually polished Snippet Cards for clipboard sharing or file export. Scope is limited to a three-day PoC.

**Current state:** inspected code contains the SwiftUI starter window with a globe and “Hello, world!”, an empty Swift Testing example and UI launch/performance test scaffolding. Reporting features are planned, not implemented or verified.

## Problem Statement

Project updates often combine narrative, metrics and screenshots that must be manually reformatted for sharing. This PoC aims to simplify producing consistent, readable reporting cards.

## Objectives

- Convert reporting inputs into a consistent card layout.
- Preview cards before sharing.
- Support clipboard copying and PNG export.
- Keep the implementation small and testable.

## Technology Stack

- macOS, Swift and SwiftUI.
- Xcode for development and builds.
- Swift Testing for unit tests; XCTest with XCUIAutomation for UI tests.
- Proposed native macOS services for image import, clipboard access and export.

## Planned Core Features

- Text and numerical metric input with validation.
- Basic metric calculations with explicit error handling.
- Local image import.
- Reusable Snippet Card layout and preview.
- Copy a rendered card to the clipboard and export it as PNG.

## Project Structure

Existing lowercase names and Xcode layout are preserved:

```text
projectreportingbuilder/                 # Git repository root
├── .gitignore
├── README.md
├── docs/
│   ├── ARCHITECTURE.md
│   └── TEST_PLAN.md
└── projectreportingbuilder/
    ├── projectreportingbuilder.xcodeproj/
    ├── projectreportingbuilder/
    │   ├── Assets.xcassets/
    │   ├── ContentView.swift
    │   └── projectreportingbuilderApp.swift
    ├── projectreportingbuilderTests/
    └── projectreportingbuilderUITests/
```

See [proposed architecture](docs/ARCHITECTURE.md) and [test plan](docs/TEST_PLAN.md).

## Getting Started

Use a Mac with Xcode and the macOS SDK required by the existing project. Consult the target’s build settings for compatibility; this setup does not establish a tested minimum Xcode version or change deployment settings.

From the Git root:

```sh
open projectreportingbuilder/projectreportingbuilder.xcodeproj
```

This setup introduces no dependencies or environment secrets.

## Build and Run Instructions

1. Select the `projectreportingbuilder` application scheme in Xcode.
2. Select **My Mac** as the run destination.
3. Use **Product > Build** (Command-B), then **Product > Run** (Command-R).

The current app displays the starter screen. Builds and runtime behavior have not been validated during this documentation-only setup.

## Testing

Use **Product > Test** (Command-U) to run the existing test targets. Current tests are scaffolding and do not verify reporting functionality. Planned checks in [TEST_PLAN.md](docs/TEST_PLAN.md) are initially marked `Not Run`.

## Known Limitations

- Reporting inputs, calculations, image import, card generation, clipboard copying and export are not implemented.
- Accessibility, resizing, rendering quality and sharing remain unverified.
- Persistence, collaboration and enterprise integrations are outside the initial proposed scope.

## Future Improvements

After validating the basic workflow, consider additional templates, saved drafts, richer metrics and additional export formats.

A final implementation report will be requested separately after development and testing. No requirements specification is included in this setup.
