import SwiftUI

extension Color {
    /// A subdued semantic foreground that retains WCAG text contrast in both appearances.
    static var accessibleSecondary: Color {
        .primary.opacity(0.72)
    }

    /// A semantic boundary color that remains visible against light and dark surfaces.
    static var accessibleBoundary: Color {
        .primary.opacity(0.42)
    }
}
