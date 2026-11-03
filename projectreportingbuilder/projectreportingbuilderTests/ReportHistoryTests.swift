import Foundation
import Testing
@testable import projectreportingbuilder

@MainActor
struct ReportHistoryTests {
    @Test func duplicateReplacementProtectsUnsavedEditorWork() {
        let emptyDraft = ReportDraft()
        #expect(!DraftReplacementProtection.requiresConfirmation(
            currentDraft: emptyDraft,
            generatedRevision: nil,
            generatedPreviewIsSaved: false
        ))

        var draft = ReportDraft(projectName: "Current", projectUpdate: "Current editor work")
        #expect(DraftReplacementProtection.requiresConfirmation(
            currentDraft: draft,
            generatedRevision: nil,
            generatedPreviewIsSaved: false
        ))

        let generatedRevision = DraftRevision(draft)
        #expect(DraftReplacementProtection.requiresConfirmation(
            currentDraft: draft,
            generatedRevision: generatedRevision,
            generatedPreviewIsSaved: false
        ))
        #expect(!DraftReplacementProtection.requiresConfirmation(
            currentDraft: draft,
            generatedRevision: generatedRevision,
            generatedPreviewIsSaved: true
        ))

        draft.projectUpdate = "Newer ungenerated editor work"
        #expect(DraftReplacementProtection.requiresConfirmation(
            currentDraft: draft,
            generatedRevision: generatedRevision,
            generatedPreviewIsSaved: true
        ))
    }

    @Test(arguments: [
        (false, false, false, false),
        (true, true, false, false),
        (true, false, true, false),
        (true, false, false, true)
    ])
    func saveEligibilityRequiresFreshUnsavedGeneratedPreview(
        hasGeneratedPreview: Bool,
        isStale: Bool,
        alreadySaved: Bool,
        expected: Bool
    ) {
        #expect(ReportSaveEligibility.canSave(
            hasGeneratedPreview: hasGeneratedPreview,
            isStale: isStale,
            alreadySaved: alreadySaved
        ) == expected)
    }
}
