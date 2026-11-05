import Foundation
import Testing
@testable import MihirakiPDFUtility

@Suite("PDF Cache Cleanup Tests")
struct PDFCacheCleanupTests {
    @Test("cleanupStalePdfCopies removes matching pdf-render and folder_images files only")
    func cleanupStalePdfCopiesRemovesMatchingFiles() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appending(path: "PDFCacheCleanupTest_\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let target1 = tempDir.appending(path: "pdf-render-12345.pdf")
        let target2 = tempDir.appending(path: "folder_images_abc.pdf")
        let keep1 = tempDir.appending(path: "regular_doc.pdf")
        let keep2 = tempDir.appending(path: "pdf-render-12345.txt")

        try "dummy1".write(to: target1, atomically: true, encoding: .utf8)
        try "dummy2".write(to: target2, atomically: true, encoding: .utf8)
        try "keep1".write(to: keep1, atomically: true, encoding: .utf8)
        try "keep2".write(to: keep2, atomically: true, encoding: .utf8)

        let deletedCount = PDFCacheCleanup.cleanupStalePdfCopies(in: [tempDir])
        #expect(deletedCount == 2)

        #expect(!FileManager.default.fileExists(atPath: target1.path))
        #expect(!FileManager.default.fileExists(atPath: target2.path))
        #expect(FileManager.default.fileExists(atPath: keep1.path))
        #expect(FileManager.default.fileExists(atPath: keep2.path))
    }

    @Test("migrateLegacyLogsIfNeeded executes once and sets flag")
    func migrateLegacyLogsIfNeededSetsFlag() {
        let suiteName = "test.migration.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        #expect(defaults.bool(forKey: "fixed_location_labels_v1") == false)

        PDFCacheCleanup.migrateLegacyLogsIfNeeded(userDefaults: defaults)

        #expect(defaults.bool(forKey: "fixed_location_labels_v1") == true)

        // Second call should do nothing and stay true
        PDFCacheCleanup.migrateLegacyLogsIfNeeded(userDefaults: defaults)
        #expect(defaults.bool(forKey: "fixed_location_labels_v1") == true)
    }
}
