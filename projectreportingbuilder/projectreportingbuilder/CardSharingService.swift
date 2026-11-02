import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// Shares immutable generated cards, never the draft currently being edited.
@MainActor
enum CardSharingService {
    enum SharingError: LocalizedError {
        case invalidMetric, invalidImage, renderFailed, tooLarge, clipboardFailed
        var errorDescription: String? {
            switch self {
            case .invalidMetric: "This card has invalid progress. Correct the inputs and generate again."
            case .invalidImage: "The card's image could not be decoded."
            case .renderFailed: "The card could not be rendered as PNG."
            case .tooLarge: "This card is too tall to export. Shorten its text and generate again."
            case .clipboardFailed: "The clipboard could not be updated. Please try again."
            }
        }
    }

    static func title(for card: SnippetCard) -> String {
        switch card {
        case .summary: "Summary"
        case .kpi: "Project progress"
        case .image: "Project image"
        }
    }

    static func plainText(for card: SnippetCard) throws -> String {
        switch card {
        case .summary(let content):
            return "\(content.projectName)\n\n\(content.updateNotes)"
        case .kpi(let content):
            guard let progress = content.progress else { throw SharingError.invalidMetric }
            let source: String
            switch content {
            case .estimate: source = "Self-reported"
            case .milestones: source = "Calculated from milestones"
            }
            var text = "Project progress: \(progress.formatted(.percent.precision(.fractionLength(0...4))))\n\(source)"
            if let completed = content.completed, let total = content.total {
                text += "\n\(completed) of \(total) milestones completed"
            }
            if !content.note.isEmpty { text += "\n\n\(content.note)" }
            return text
        case .image(let content):
            return "Project image\n\(content.caption)"
        }
    }

    static func reportPlainText(for cards: [SnippetCard]) throws -> String {
        var sections: [String] = []
        for card in cards {
            switch card {
            case .summary(let content):
                sections.append(content.projectName)
                sections.append("Summary\n\(content.updateNotes)")
            case .kpi, .image:
                sections.append(try plainText(for: card))
            }
        }
        return sections.joined(separator: "\n\n")
    }

    static func pngData(for card: SnippetCard, colorScheme: ColorScheme) throws -> Data {
        _ = try plainText(for: card)
        var image: NSImage?
        if case .image(let content) = card {
            guard let decoded = NSImage(data: content.image.data), decoded.isValid else {
                throw SharingError.invalidImage
            }
            image = decoded
        }
        // Resolve AppKit semantic colors consistently with the SwiftUI environment.
        let appearance = NSAppearance(named: colorScheme == .dark ? .darkAqua : .aqua)
        var result: Result<Data, Error> = .failure(SharingError.renderFailed)
        appearance?.performAsCurrentDrawingAppearance {
            result = Result {
                let content = SnippetCardContent(card: card, preparedImage: image)
                    .padding(16)
                    .frame(width: 640)
                    .fixedSize(horizontal: false, vertical: true)
                    .background(Color(nsColor: .windowBackgroundColor))
                    .environment(\.colorScheme, colorScheme)
                let renderer = ImageRenderer(content: content)
                renderer.scale = 2
                renderer.isOpaque = true
                var height: CGFloat = 0
                renderer.render { size, _ in height = size.height }
                // Bound bitmap allocation instead of silently clipping long cards.
                guard height > 0 else { throw SharingError.renderFailed }
                guard height <= 8_000 else { throw SharingError.tooLarge }
                guard let cgImage = renderer.cgImage,
                      let data = NSBitmapImageRep(cgImage: cgImage).representation(using: .png, properties: [:]) else {
                    throw SharingError.renderFailed
                }
                return data
            }
        }
        return try result.get()
    }

    static func reportPNGData(for cards: [SnippetCard], colorScheme: ColorScheme) throws -> Data {
        _ = try reportPlainText(for: cards)
        var images: [UUID: NSImage] = [:]
        for card in cards {
            guard case .image(let content) = card else { continue }
            guard let decoded = NSImage(data: content.image.data), decoded.isValid else {
                throw SharingError.invalidImage
            }
            images[content.image.id] = decoded
        }

        let appearance = NSAppearance(named: colorScheme == .dark ? .darkAqua : .aqua)
        var result: Result<Data, Error> = .failure(SharingError.renderFailed)
        appearance?.performAsCurrentDrawingAppearance {
            result = Result {
                let content = UnifiedReportView(cards: cards, preparedImages: images)
                    .padding(16)
                    .frame(width: 640)
                    .fixedSize(horizontal: false, vertical: true)
                    .background(Color(nsColor: .windowBackgroundColor))
                    .environment(\.colorScheme, colorScheme)
                let renderer = ImageRenderer(content: content)
                renderer.scale = 2
                renderer.isOpaque = true
                var height: CGFloat = 0
                renderer.render { size, _ in height = size.height }
                guard height > 0 else { throw SharingError.renderFailed }
                guard height <= 8_000 else { throw SharingError.tooLarge }
                guard let cgImage = renderer.cgImage,
                      let data = NSBitmapImageRep(cgImage: cgImage).representation(using: .png, properties: [:]) else {
                    throw SharingError.renderFailed
                }
                return data
            }
        }
        return try result.get()
    }

    static func copy(_ card: SnippetCard, colorScheme: ColorScheme, to pasteboard: NSPasteboard = .general) throws {
        let text = try plainText(for: card)
        let png = try pngData(for: card, colorScheme: colorScheme)
        try copy(text: text, png: png, to: pasteboard)
    }

    static func copyReport(_ cards: [SnippetCard], colorScheme: ColorScheme, to pasteboard: NSPasteboard = .general) throws {
        let text = try reportPlainText(for: cards)
        let png = try reportPNGData(for: cards, colorScheme: colorScheme)
        try copy(text: text, png: png, to: pasteboard)
    }

    private static func copy(text: String, png: Data, to pasteboard: NSPasteboard) throws {
        let richText = NSAttributedString(string: text, attributes: [.font: NSFont.systemFont(ofSize: 14)])
        let rtf = try richText.data(from: NSRange(location: 0, length: richText.length),
                                    documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
        let item = NSPasteboardItem()
        guard item.setString(text, forType: .string),
              item.setData(rtf, forType: .rtf),
              item.setData(png, forType: .png) else { throw SharingError.clipboardFailed }
        // Prepare every representation before touching the user's clipboard.
        pasteboard.clearContents()
        guard pasteboard.writeObjects([item]) else { throw SharingError.clipboardFailed }
    }

    static func writePNG(_ data: Data, to url: URL) throws {
        try data.write(to: url, options: .atomic)
    }

    /// Returns nil on cancellation; no success message or file is produced.
    static func export(_ card: SnippetCard, colorScheme: ColorScheme) async throws -> URL? {
        let data = try pngData(for: card, colorScheme: colorScheme)
        return try await exportPNG(
            data,
            suggestedName: "\(title(for: card)).png",
            panelTitle: "Export Snippet Card"
        )
    }

    static func exportReport(_ cards: [SnippetCard], colorScheme: ColorScheme) async throws -> URL? {
        let data = try reportPNGData(for: cards, colorScheme: colorScheme)
        return try await exportPNG(
            data,
            suggestedName: "Project Report.png",
            panelTitle: "Export Project Report"
        )
    }

    private static func exportPNG(_ data: Data, suggestedName: String, panelTitle: String) async throws -> URL? {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = suggestedName
        panel.title = panelTitle
        panel.prompt = "Save"
        let response: NSApplication.ModalResponse
        if let window = NSApp.keyWindow {
            response = await panel.beginSheetModal(for: window)
        } else {
            response = await panel.begin()
        }
        guard response == .OK, let url = panel.url else { return nil }
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        try writePNG(data, to: url)
        return url
    }
}
