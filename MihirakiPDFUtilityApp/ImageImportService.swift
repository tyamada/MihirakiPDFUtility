import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct ImageImportFile: Identifiable, Sendable {
    let url: URL
    let creationDate: Date?
    let modificationDate: Date?

    var id: URL { url }
    var name: String { url.lastPathComponent }
}

enum ImageSortKey: String, CaseIterable, Identifiable, Sendable {
    case name, creationDate, modificationDate

    var id: Self { self }
    var title: LocalizedStringResource {
        switch self {
        case .name: "Name"
        case .creationDate: "Creation Date"
        case .modificationDate: "Modification Date"
        }
    }
}

enum ImageSortDirection: String, CaseIterable, Identifiable, Sendable {
    case ascending, descending

    var id: Self { self }
    var title: LocalizedStringResource {
        switch self {
        case .ascending: "Ascending"
        case .descending: "Descending"
        }
    }
}

enum ImageImportOrdering {
    static func sorted(
        _ files: [ImageImportFile],
        by key: ImageSortKey,
        direction: ImageSortDirection
    ) -> [ImageImportFile] {
        files.sorted { lhs, rhs in
            if key != .name {
                let left = key == .creationDate ? lhs.creationDate : lhs.modificationDate
                let right = key == .creationDate ? rhs.creationDate : rhs.modificationDate
                // Unknown dates remain last in both directions; ties use ascending names.
                if left == nil, right != nil { return false }
                if left != nil, right == nil { return true }
                if let left, let right, left != right {
                    return direction == .ascending ? left < right : left > right
                }
            }
            let comparison = lhs.name.localizedStandardCompare(rhs.name)
            let ascending = key != .name || direction == .ascending
            if comparison == .orderedSame {
                return ascending
                    ? lhs.url.absoluteString < rhs.url.absoluteString
                    : lhs.url.absoluteString > rhs.url.absoluteString
            }
            return comparison == (ascending ? .orderedAscending : .orderedDescending)
        }
    }
}

enum ImageImportError: LocalizedError {
    case unreadable(String)
    case noImages
    case conversionFailed

    var errorDescription: String? {
        switch self {
        case .unreadable(let name):
            String(localized: "Unable to read image: \(name)")
        case .noImages:
            String(localized: "No supported images were found in this folder.")
        case .conversionFailed:
            String(localized: "Unable to create a PDF from these images.")
        }
    }
}

/// File access and decoding run on this actor, away from the main actor.
/// Only metadata and completed PDF data cross the actor boundary.
actor ImageImportService {
    func files(in folder: URL) throws -> [ImageImportFile] {
        let accessed = folder.startAccessingSecurityScopedResource()
        defer { if accessed { folder.stopAccessingSecurityScopedResource() } }
        let keys: Set<URLResourceKey> = [
            .isRegularFileKey, .isSymbolicLinkKey, .contentTypeKey,
            .creationDateKey, .contentModificationDateKey
        ]
        let urls = try FileManager.default.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: Array(keys),
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        )
        let supported: [UTType] = [.jpeg, .png, .heic, .heif, .tiff, .gif, .bmp]
        return try urls.compactMap { url in
            try Task.checkCancellation()
            let values = try url.resourceValues(forKeys: keys)
            guard values.isRegularFile == true, values.isSymbolicLink != true,
                  let type = values.contentType ?? UTType(filenameExtension: url.pathExtension),
                  supported.contains(where: { type.conforms(to: $0) }) else { return nil }
            return ImageImportFile(
                url: url,
                creationDate: values.creationDate,
                modificationDate: values.contentModificationDate
            )
        }
    }

    func makePDF(
        from files: [ImageImportFile],
        in folder: URL,
        progress: @Sendable (Int) async -> Void
    ) async throws -> Data {
        guard !files.isEmpty else { throw ImageImportError.noImages }
        try Task.checkCancellation()
        let accessed = folder.startAccessingSecurityScopedResource()
        defer { if accessed { folder.stopAccessingSecurityScopedResource() } }

        let data = NSMutableData()
        guard let consumer = CGDataConsumer(data: data),
              let context = CGContext(consumer: consumer, mediaBox: nil, nil) else {
            throw ImageImportError.conversionFailed
        }
        var closed = false
        defer { if !closed { context.closePDF() } }
        for (index, file) in files.enumerated() {
            try Task.checkCancellation()
            try autoreleasepool {
                guard let source = CGImageSourceCreateWithURL(file.url as CFURL, nil),
                      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
                      let width = properties[kCGImagePropertyPixelWidth] as? NSNumber,
                      let height = properties[kCGImagePropertyPixelHeight] as? NSNumber,
                      width.intValue > 0, height.intValue > 0 else {
                    throw ImageImportError.unreadable(file.name)
                }
                // Decode only the first frame at its original resolution, applying EXIF orientation.
                let options: [CFString: Any] = [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceThumbnailMaxPixelSize: max(width.intValue, height.intValue),
                    kCGImageSourceShouldCacheImmediately: true
                ]
                guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
                    throw ImageImportError.unreadable(file.name)
                }
                var bounds = CGRect(x: 0, y: 0, width: image.width, height: image.height)
                let box = Data(bytes: &bounds, count: MemoryLayout<CGRect>.size)
                context.beginPDFPage([kCGPDFContextMediaBox as String: box] as CFDictionary)
                context.setFillColor(CGColor(gray: 1, alpha: 1))
                context.fill(bounds)
                context.draw(image, in: bounds)
                context.endPDFPage()
            }
            await progress(index + 1)
        }
        try Task.checkCancellation()
        context.closePDF()
        closed = true
        return data as Data
    }
}
