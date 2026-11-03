import SwiftUI
import Testing
@testable import projectreportingbuilder

struct AppearanceTests {
    @Test(arguments: [
        (AppAppearance.system, Optional<ColorScheme>.none),
        (AppAppearance.light, Optional(ColorScheme.light)),
        (AppAppearance.dark, Optional(ColorScheme.dark))
    ])
    func appearanceMapsToExpectedColorScheme(
        appearance: AppAppearance,
        expected: ColorScheme?
    ) {
        #expect(appearance.colorScheme == expected)
        #expect(AppAppearance.colorScheme(for: appearance.rawValue) == expected)
    }

    @Test func unknownStoredAppearanceFallsBackToSystem() {
        #expect(AppAppearance.colorScheme(for: "unknown") == nil)
    }
}
