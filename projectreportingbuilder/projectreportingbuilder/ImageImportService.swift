import Foundation
import ImageIO
import UniformTypeIdentifiers

nonisolated enum ImageImportService {
    static let maximumBytes = 20 * 1_024 * 1_024
    static let maximumPixels = 40_000_000

    enum ImportError: LocalizedError {
        case tooLarge
        case unsupportedOrCorrupt

        var errorDescription: String? {
            switch self {
            case .tooLarge:
                String(localized: "Choose an image smaller than 20 MB and no larger than 40 megapixels.")
            case .unsupportedOrCorrupt:
                String(localized: "This file could not be read as a PNG or JPEG image. Choose another image.")
            }
        }
    }

    static func load(from url: URL) throws -> ImportedImage {
        let hasAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasAccess { url.stopAccessingSecurityScopedResource() }
        }
        // A false return can also mean a URL already accessible to this process.
        // Attempt the read and let its error describe an actual access failure.
        let file = try FileHandle(forReadingFrom: url)
        defer { try? file.close() }
        let data = try file.read(upToCount: maximumBytes + 1) ?? Data()
        return try decode(data: data, filename: url.lastPathComponent)
    }

    static func decode(data: Data, filename: String) throws -> ImportedImage {
        guard data.count <= maximumBytes else { throw ImportError.tooLarge }
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let type = CGImageSourceGetType(source),
              [UTType.png.identifier, UTType.jpeg.identifier].contains(type as String),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int,
              width > 0, height > 0 else {
            throw ImportError.unsupportedOrCorrupt
        }
        guard width <= maximumPixels / height else { throw ImportError.tooLarge }
        guard CGImageSourceCreateImageAtIndex(source, 0, nil) != nil,
              CGImageSourceGetStatus(source) == .statusComplete else {
            throw ImportError.unsupportedOrCorrupt
        }
        return ImportedImage(filename: filename, data: data)
    }
}
