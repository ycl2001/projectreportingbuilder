//
//  projectreportingbuilderApp.swift
//  projectreportingbuilder
//
//  Created by Yen-Chun Liu on 2/11/2026.
//

import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    static let storageKey = "appAppearance"

    case system
    case light
    case dark

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    static func colorScheme(for storedValue: String) -> ColorScheme? {
        AppAppearance(rawValue: storedValue)?.colorScheme
    }
}

@main
struct projectreportingbuilderApp: App {
    @AppStorage(AppAppearance.storageKey)
    private var storedAppearance = AppAppearance.system.rawValue

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(AppAppearance.colorScheme(for: storedAppearance))
        }
        .defaultSize(width: 1060, height: 760)
        .windowResizability(.contentMinSize)

        Settings {
            AppearanceSettingsView()
        }
    }
}

private struct AppearanceSettingsView: View {
    @AppStorage(AppAppearance.storageKey)
    private var storedAppearance = AppAppearance.system.rawValue

    var body: some View {
        Form {
            Picker("Appearance", selection: $storedAppearance) {
                ForEach(AppAppearance.allCases) { appearance in
                    Text(appearance.title)
                        .tag(appearance.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Application appearance")
        }
        .formStyle(.grouped)
        .frame(width: 320)
        .padding()
    }
}
