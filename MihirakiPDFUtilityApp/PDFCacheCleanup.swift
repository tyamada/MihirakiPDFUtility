import Foundation

/// Utility for cleaning up stale temporary PDF files and legacy diagnostic data left by earlier app executions.
enum PDFCacheCleanup {
    private static let fixedLocationLabelsMigrationKey = "fixed_location_labels_v1"

    /// Deletes stale temporary PDF copies matching `pdf-render-*.pdf` or `folder_images_*.pdf`.
    @discardableResult
    static func cleanupStalePdfCopies(
        in directories: [URL] = defaultCleanupDirectories(),
        fileManager: FileManager = .default
    ) -> Int {
        var deletedCount = 0

        for directory in directories {
            guard let files = try? fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isRegularFileKey]
            ) else {
                continue
            }

            for file in files {
                let name = file.lastPathComponent
                let isTarget = (name.hasPrefix("pdf-render-") && name.hasSuffix(".pdf"))
                    || (name.hasPrefix("folder_images_") && name.hasSuffix(".pdf"))

                if isTarget {
                    do {
                        try fileManager.removeItem(at: file)
                        deletedCount += 1
                    } catch {
                        // Best effort deletion
                    }
                }
            }
        }

        return deletedCount
    }

    /// Performs one-time migration to clean up legacy logs if the migration flag is not set.
    static func migrateLegacyLogsIfNeeded(
        userDefaults: UserDefaults = .standard,
        fileManager: FileManager = .default
    ) {
        guard !userDefaults.bool(forKey: fixedLocationLabelsMigrationKey) else {
            return
        }

        // Clean up any legacy unformatted log files in Application Support
        if let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let legacyLogFile = appSupport.appending(path: "app_audit_logs.txt")
            if fileManager.fileExists(atPath: legacyLogFile.path) {
                try? fileManager.removeItem(at: legacyLogFile)
            }
            let legacyLogDir = appSupport.appending(path: "app_logs", directoryHint: .isDirectory)
            if fileManager.fileExists(atPath: legacyLogDir.path) {
                try? fileManager.removeItem(at: legacyLogDir)
            }
        }

        userDefaults.set(true, forKey: fixedLocationLabelsMigrationKey)
    }

    static func defaultCleanupDirectories() -> [URL] {
        var dirs: [URL] = [FileManager.default.temporaryDirectory]
        if let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            dirs.append(caches)
        }
        return dirs
    }
}
