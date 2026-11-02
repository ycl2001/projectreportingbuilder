import Foundation
import Testing
@testable import projectreportingbuilder

@MainActor
struct ReportBuilderTests {
    @Test func preservesAllSourceInformation() throws {
        let attachment = ImportedImage(filename: "  Roadmap 🚀.png", data: Data([1, 2, 3]))
        var draft = ReportDraft()
        draft.projectName = "  Project A  "
        draft.projectUpdate = "First line\n\nSecond line 🚀\n"
        draft.progressMethod = .milestones
        draft.milestones = MilestoneMetric(completedInput: " 003 ", totalInput: "010")
        draft.image = attachment

        let cards = ReportBuilder.build(from: draft)
        #expect(cards.count == 3)
        guard case let .summary(summary) = cards[0],
              case let .kpi(kpi) = cards[1],
              case let .image(image) = cards[2] else {
            Issue.record("Expected summary, KPI and image in order.")
            return
        }
        #expect(summary.projectName == draft.projectName)
        #expect(summary.updateNotes == draft.projectUpdate)
        guard case let .milestones(source) = kpi else {
            Issue.record("Expected milestone source.")
            return
        }
        #expect(source.completedInput == " 003 ")
        #expect(source.totalInput == "010")
        #expect(kpi.completed == 3)
        #expect(kpi.total == 10)
        #expect(image.image.id == attachment.id)
        #expect(image.image.data == attachment.data)
        #expect(image.caption == attachment.filename)

        // The builder neither changes the draft nor holds mutable editor state.
        draft.projectName = "Changed"
        draft.milestones.completedInput = "9"
        draft.image = nil
        #expect(summary.projectName == "  Project A  ")
        #expect(kpi.completed == 3)
        #expect(image.image.data == attachment.data)
    }

    @Test(arguments: [
        ("0", "10", 0.0),
        ("3", "10", 0.3),
        ("1", "3", 1.0 / 3.0),
        ("10", "10", 1.0),
        (String(Int.max), String(Int.max), 1.0)
    ])
    func metricAccuracy(completed: String, total: String, expected: Double) throws {
        var draft = ReportDraft()
        draft.progressMethod = .milestones
        draft.milestones = MilestoneMetric(completedInput: completed, totalInput: total)
        let cards = ReportBuilder.build(from: draft)
        guard case let .kpi(card) = cards[1] else {
            Issue.record("Expected KPI card.")
            return
        }
        #expect(card.completed == Int(completed))
        #expect(card.total == Int(total))
        #expect(abs(try #require(card.progress) - expected) < 0.000001)
        #expect(abs(try #require(card.percentage) - expected * 100) < 0.000001)
    }

    @Test(arguments: [
        ("", "10"), ("3", ""), (" ", " "),
        ("abc", "10"), ("-1", "10"), ("1.5", "10"),
        ("0", "0"), ("11", "10"),
        (String(repeating: "9", count: 30), "10")
    ])
    func invalidMetricsNeverProduceValues(completed: String, total: String) {
        var draft = ReportDraft()
        draft.progressMethod = .milestones
        draft.milestones = MilestoneMetric(completedInput: completed, totalInput: total)
        let cards = ReportBuilder.build(from: draft)
        #expect(cards.count == 1)
        #expect(draft.progressValidationMessage == draft.milestones.validation.message)
        #expect(!draft.canGenerate)
        #expect(draft.milestones.completedInput == completed)
        #expect(draft.milestones.totalInput == total)
    }

    @Test(arguments: [("", ""), ("", "Keep these notes"), ("Keep this name", ""), (" \n ", "\t")])
    func missingTextIsRetainedWithoutInventedContent(name: String, update: String) {
        var draft = ReportDraft()
        draft.projectName = name
        draft.projectUpdate = update
        let cards = ReportBuilder.build(from: draft)
        #expect(cards.count == 1)
        guard case let .summary(card) = cards[0] else {
            Issue.record("Expected summary even when fields are missing.")
            return
        }
        #expect(card.projectName == name)
        #expect(card.updateNotes == update)
    }

    @Test func emptyDraftHasNoImageAndNoPercentage() {
        let cards = ReportBuilder.build(from: ReportDraft())
        #expect(cards.count == 1)
        #expect(ReportDraft().progressMethod == .none)
    }

    @Test func emptyImagePayloadIsPreservedForPresentationFallback() {
        var draft = ReportDraft()
        draft.image = ImportedImage(filename: "", data: Data())
        let cards = ReportBuilder.build(from: draft)
        #expect(cards.count == 2)
        guard case let .image(card) = cards[1] else {
            Issue.record("Expected attached image payload to be retained.")
            return
        }
        #expect(card.image.data.isEmpty)
        #expect(card.caption.isEmpty)
    }
}
