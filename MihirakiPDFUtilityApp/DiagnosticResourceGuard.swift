import Foundation
import Dispatch
import Synchronization

/// The dispatch source lives for the process; all cross-queue state is protected by Mutex.
final class DiagnosticMemoryPressure: @unchecked Sendable {
    static let shared = DiagnosticMemoryPressure()
    private let pressured = Mutex(false)
    private let source: any DispatchSourceMemoryPressure

    private init() {
        source = DispatchSource.makeMemoryPressureSource(eventMask: [.normal, .warning, .critical],
                                                        queue: .global(qos: .utility))
        source.setEventHandler { [weak self] in
            guard let self else { return }
            let events = self.source.data
            self.pressured.withLock { $0 = events.contains(.warning) || events.contains(.critical) }
        }
        source.resume()
    }

    var isPressured: Bool { pressured.withLock { $0 } }
}

struct DiagnosticResourceStop: Error {
    let detail: String
}

struct DiagnosticResourceGuard: Sendable {
    let thermalPolicy: DiagnosticThermalPolicy
    var memoryPressure: @Sendable () -> Bool = { DiagnosticMemoryPressure.shared.isPressured }

    var deadline: ContinuousClock.Instant? = nil

    @TaskLocal static var current: DiagnosticResourceGuard?

    func reason() -> String? {
        if let deadline, ContinuousClock.now >= deadline {
            return String(localized: "Diagnostics stopped because the case exceeded its time limit. Remaining tests were skipped.")
        }
        if memoryPressure() {
            return String(localized: "Diagnostics stopped because of memory pressure. Remaining tests were skipped. Try again after closing other apps.")
        }
        if thermalPolicy.skipReason() != nil {
            return String(localized: "Diagnostics stopped because of the device thermal state. Remaining tests were skipped. Let the device cool before trying again.")
        }
        return nil
    }

    static func measureOffMain(
        _ measure: @escaping @Sendable () throws -> PerformanceTestMeasurement
    ) async throws -> PerformanceTestMeasurement {
        let inheritedGuard = current
        let task = Task.detached(priority: .userInitiated) {
            try Self.$current.withValue(inheritedGuard) {
                try Self.check()
                let result = try measure()
                try Self.check()
                return result
            }
        }
        return try await withTaskCancellationHandler {
            try await task.value
        } onCancel: {
            task.cancel()
        }
    }

    static func check() throws {
        try Task.checkCancellation()
        if let reason = current?.reason() { throw DiagnosticResourceStop(detail: reason) }
    }
}
