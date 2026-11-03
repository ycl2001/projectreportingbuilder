import Foundation

struct ReportDraft {
    var projectName = ""
    var projectUpdate = ""
    var milestones = MilestoneMetric()
    var image: ImportedImage?
    var progressMethod: ProgressMethod = .none
    var estimatedPercentage = PercentageMetric()
    var progressNote = ""

    var progressValidationMessage: LocalizedStringResource? {
        switch progressMethod {
        case .none: nil
        case .percentage: estimatedPercentage.validationMessage
        case .milestones: milestones.validation.message
        }
    }

    var canGenerate: Bool {
        hasProjectInformation && progressValidationMessage == nil
    }

    var hasProjectInformation: Bool {
        !projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !projectUpdate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

nonisolated struct ImportedImage: Sendable, Identifiable {
    let id = UUID()
    let filename: String
    let data: Data
}

struct MilestoneMetric {
    var completedInput = ""
    var totalInput = ""

    enum Validation: Equatable {
        case valid(completed: Int, total: Int)
        case missingInput
        case invalidWholeNumber
        case numberTooLarge
        case zeroTotal
        case completedExceedsTotal

        var message: LocalizedStringResource? {
            switch self {
            case .valid: nil
            case .missingInput: "Enter both completed and total milestones to calculate progress."
            case .invalidWholeNumber: "Use non-negative whole numbers (digits 0–9 only)."
            case .numberTooLarge: "The milestone count is too large. Enter a smaller whole number."
            case .zeroTotal: "Total milestones must be greater than zero."
            case .completedExceedsTotal: "Completed milestones cannot exceed total milestones."
            }
        }
    }

    var validation: Validation {
        let completed = completedInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let total = totalInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !completed.isEmpty, !total.isEmpty else { return .missingInput }
        guard [completed, total].allSatisfy({ value in
            value.utf8.allSatisfy { (48...57).contains($0) }
        }) else { return .invalidWholeNumber }
        guard let completed = Int(completed), let total = Int(total) else {
            return .numberTooLarge
        }
        guard total > 0 else { return .zeroTotal }
        guard completed <= total else { return .completedExceedsTotal }
        return .valid(completed: completed, total: total)
    }

    /// A fraction in 0...1 for percent formatting, or nil for invalid input.
    var progress: Double? {
        guard case let .valid(completed, total) = validation else { return nil }
        // Divide before scaling to avoid integer overflow for large counts.
        return Double(completed) / Double(total)
    }
}
