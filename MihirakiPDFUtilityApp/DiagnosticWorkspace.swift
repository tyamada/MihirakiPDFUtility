import Foundation

enum DiagnosticWorkspaceError: Error {
    case unsafeDirectory
    case unknownRun
}

/// One shared owner serializes recovery and creation across all app windows.
/// UUID directories are the on-disk run records, including partially created runs.
actor DiagnosticWorkspace {
    static let shared = DiagnosticWorkspace()
    private let root: URL
    private let fileManager = FileManager.default
    private var activeRuns: Set<UUID> = []

    init(baseDirectory: URL = FileManager.default.temporaryDirectory) {
        root = baseDirectory.resolvingSymlinksInPath()
            .appending(path: "MihirakiDiagnosticRuns", directoryHint: .isDirectory)
    }

    func begin() throws -> UUID {
        try recoverAbandonedRuns()
        let id = UUID()
        let directory = directory(for: id)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: false)
        activeRuns.insert(id)
        return id
    }

    func directory(for id: UUID) -> URL {
        root.appending(path: id.uuidString, directoryHint: .isDirectory)
    }

    func finish(_ id: UUID) throws {
        guard activeRuns.contains(id) else { throw DiagnosticWorkspaceError.unknownRun }
        // A failed removal becomes abandoned and is retried on next recovery.
        defer { activeRuns.remove(id) }
        do {
            try validateRoot()
            let directory = directory(for: id)
            // A missing directory may already have been purged by the OS.
            if fileManager.fileExists(atPath: directory.path) {
                try fileManager.removeItem(at: directory)
            }
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile || error.code == .fileNoSuchFile {
            return
        }
    }

    func recoverAbandonedRuns() throws {
        try prepareRoot()
        let children = try fileManager.contentsOfDirectory(
            at: root, includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey]
        )
        for child in children {
            guard let id = UUID(uuidString: child.lastPathComponent),
                  !activeRuns.contains(id) else { continue }
            let values = try child.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
            // removeItem removes a link itself, never traverse its destination.
            if values.isDirectory == true || values.isSymbolicLink == true {
                try fileManager.removeItem(at: child)
            }
        }
    }

    private func prepareRoot() throws {
        if !fileManager.fileExists(atPath: root.path) {
            try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        }
        try validateRoot()
    }

    private func validateRoot() throws {
        // Inspect the directory entry itself; directory-hinted URLs may reject
        // a symbolic link before URL resource values can report its type.
        let attributes = try fileManager.attributesOfItem(atPath: root.path)
        guard attributes[.type] as? FileAttributeType == .typeDirectory else {
            throw DiagnosticWorkspaceError.unsafeDirectory
        }
    }
}
