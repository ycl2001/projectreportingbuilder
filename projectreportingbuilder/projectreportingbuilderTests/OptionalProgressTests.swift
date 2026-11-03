import Testing
@testable import projectreportingbuilder

@MainActor
struct OptionalProgressTests {
    @Test func summaryNeedsNoProgressAndIgnoresInactiveValues() {
        var draft = ReportDraft(projectName: "Atlas", projectUpdate: "On track")
        draft.milestones = MilestoneMetric(completedInput: "invalid", totalInput: "0")
        draft.estimatedPercentage.input = "invalid"
        #expect(draft.progressMethod == .none)
        #expect(draft.canGenerate)
        let cards = ReportBuilder.build(from: draft)
        #expect(cards.count == 1)
        guard case .summary = cards[0] else {
            Issue.record("Expected summary only.")
            return
        }
    }

    @Test(arguments: [("0", 0.0), ("100", 100.0), ("62.5", 62.5), (" 7.125 ", 7.125)])
    func estimatedPercentageIsAccurate(input: String, expected: Double) throws {
        var draft = ReportDraft(projectName: "Atlas", projectUpdate: "On track")
        draft.progressMethod = .percentage
        draft.estimatedPercentage.input = input
        #expect(draft.canGenerate)
        let cards = ReportBuilder.build(from: draft)
        #expect(cards.count == 2)
        guard case let .kpi(card) = cards[1], case let .estimate(source, _) = card else {
            Issue.record("Expected explicitly estimated KPI.")
            return
        }
        #expect(source.input == input)
        #expect(card.percentage == expected)
        #expect(abs(try #require(card.progress) - expected / 100) < 0.000001)
        #expect(card.completed == nil)
        #expect(card.total == nil)
    }

    @Test(arguments: ["", " ", "-1", "100.01", "101", "abc", "NaN", "inf", "1e2", "50%", "62,5", "1.2.3", ".", "+5"])
    func invalidEstimateCannotGenerateKPI(input: String) {
        var draft = ReportDraft(projectName: "Atlas", projectUpdate: "On track")
        draft.progressMethod = .percentage
        draft.estimatedPercentage.input = input
        #expect(draft.progressValidationMessage != nil)
        #expect(!draft.canGenerate)
        #expect(draft.estimatedPercentage.progress == nil)
        #expect(ReportBuilder.build(from: draft).count == 1)
    }

    @Test func switchingMethodsPreservesValuesAndUsesOnlySelectedMetric() throws {
        var draft = ReportDraft(projectName: "Atlas", projectUpdate: "On track")
        draft.milestones = MilestoneMetric(completedInput: "2", totalInput: "8")
        draft.estimatedPercentage.input = "62.5"
        draft.progressNote = "  Discovery done.\nMigration remains. 🚀  "
        for method in [ProgressMethod.percentage, .milestones, .none, .percentage] {
            draft.progressMethod = method
            let cards = ReportBuilder.build(from: draft)
            if method == .none {
                #expect(cards.count == 1)
            } else {
                guard case let .kpi(card) = cards[1] else {
                    Issue.record("Expected selected KPI.")
                    return
                }
                #expect(card.percentage == (method == .percentage ? 62.5 : 25))
                #expect(card.note == draft.progressNote)
                draft.progressNote = "Edited after generation"
                #expect(card.note != draft.progressNote)
                draft.progressNote = card.note
            }
            #expect(draft.estimatedPercentage.input == "62.5")
            #expect(draft.milestones.completedInput == "2")
            #expect(draft.milestones.totalInput == "8")
        }
    }
}
