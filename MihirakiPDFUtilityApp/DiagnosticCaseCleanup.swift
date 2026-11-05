import Foundation
import Synchronization

struct DiagnosticCleanupMeasurement: Codable, Sendable {
    var milliseconds: Double = 0
    var succeeded = true
}

/// Each case owns a recorder; removal continues even when its task is cancelled.
final class DiagnosticCaseCleanup: Sendable {
    @TaskLocal static var current: DiagnosticCaseCleanup?
    private let measurement = Mutex<DiagnosticCleanupMeasurement?>(nil)

    var result: DiagnosticCleanupMeasurement? { measurement.withLock { $0 } }

    static func remove(_ url: URL, using removal: (URL) throws -> Void = { try FileManager.default.removeItem(at: $0) }) {
        let start = ContinuousClock.now
        var succeeded = true
        do {
            try removal(url)
        } catch let error as CocoaError where error.code == .fileNoSuchFile {
            // Already removed by the system; no remaining data.
        } catch {
            succeeded = false
        }
        let duration = start.duration(to: .now)
        let milliseconds = Double(duration.components.seconds) * 1_000
            + Double(duration.components.attoseconds) / 1_000_000_000_000_000
        current?.record(milliseconds: milliseconds, succeeded: succeeded)
    }

    func record(milliseconds: Double, succeeded: Bool) {
        measurement.withLock {
            var value = $0 ?? DiagnosticCleanupMeasurement()
            value.milliseconds += milliseconds
            value.succeeded = value.succeeded && succeeded
            $0 = value
        }
    }
}
