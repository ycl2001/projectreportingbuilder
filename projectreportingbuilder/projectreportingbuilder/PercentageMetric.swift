import Foundation

enum ProgressMethod: String {
    case none
    case percentage
    case milestones
}

struct PercentageMetric {
    var input = ""

    /// Accept decimal digits with an optional dot, without guessing units or locale.
    var percentage: Double? {
        let value = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = value.split(separator: ".", omittingEmptySubsequences: false)
        guard (1...2).contains(parts.count),
              parts.allSatisfy({ !$0.isEmpty && $0.utf8.allSatisfy { (48...57).contains($0) } }),
              let number = Double(value), number.isFinite, (0...100).contains(number) else {
            return nil
        }
        return number
    }

    var progress: Double? { percentage.map { $0 / 100 } }

    var validationMessage: LocalizedStringResource? {
        if input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Enter an estimated percentage from 0 to 100."
        }
        return percentage == nil ? "Use a number from 0 to 100, with a dot for decimals (for example, 62.5)." : nil
    }
}
