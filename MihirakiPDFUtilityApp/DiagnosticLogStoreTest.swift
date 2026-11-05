import Foundation

private struct DiagnosticLogCapacitySkip: DiagnosticSkipReason {
    let detail = String(localized: "Log store test skipped or stopped because sufficient available storage could not be confirmed.")
}

enum DiagnosticLogStoreTest {
    static func testCase(capacity: DiagnosticStorageCapacity = .live) -> DiagnosticTestCase {
        DiagnosticTestCase(id: "logs.isolatedStore", title: "Isolated Diagnostic Log Store") { directory in
            let fixture = directory.appending(path: "log-store", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: fixture, withIntermediateDirectories: false)
            defer { DiagnosticCaseCleanup.remove(fixture) }
            let policy = DiagnosticStorageBudget()
            let plan = policy.plan(availableBytes: capacity.read(fixture))
            guard plan.availableBytes != nil else { throw DiagnosticLogCapacitySkip() }
            guard plan.pageCounts.contains(12) else { throw DiagnosticLogCapacitySkip() }
            let start = ContinuousClock.now
            let store = DiagnosticLogStore(baseDirectory: fixture)
            let now = Date(timeIntervalSince1970: 1_700_000_000)
            let cutoff = now.addingTimeInterval(-DiagnosticLogStore.retentionInterval)
            func check() throws {
                try DiagnosticResourceGuard.check()
                guard policy.canContinue(initialBudgetBytes: plan.budgetBytes, usedBytes: 0,
                                         additionalEstimatedBytes: 4 * DiagnosticStorageBudget.mebibyte,
                                         availableBytes: capacity.read(fixture)) else {
                    throw DiagnosticLogCapacitySkip()
                }
            }
            try check()
            await store.record(.documentOpenFailed, category: .document, outcome: .failure,
                               now: cutoff.addingTimeInterval(-1))
            try check()
            await store.record(.documentOpened, category: .document, pageCount: 12, now: cutoff)
            try check()
            await store.record(.pagesRotated, category: .editing, duration: .milliseconds(25),
                               pageCount: 12, selectionCount: 2, now: now)
            try check()
            let reopened = DiagnosticLogStore(baseDirectory: fixture)
            let records = await reopened.records(now: now)
            guard records.map(\.event) == [.documentOpened, .pagesRotated],
                  records.first?.timestamp == cutoff,
                  records.last?.durationMilliseconds == 25,
                  records.last?.pageCount == 12, records.last?.selectionCount == 2 else {
                throw CocoaError(.fileReadCorruptFile)
            }
            let allowed: Set<String> = ["id", "timestamp", "category", "event", "outcome",
                                        "durationMilliseconds", "pageCount", "selectionCount"]
            for record in records {
                let object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(record))
                guard let fields = object as? [String: Any], Set(fields.keys).isSubset(of: allowed) else {
                    throw CocoaError(.fileReadCorruptFile)
                }
            }
            try check()
            await reopened.startSession(now: now)
            let restarted = DiagnosticLogStore(baseDirectory: fixture)
            await restarted.startSession(now: now.addingTimeInterval(1))
            let interrupted = await restarted.records(now: now.addingTimeInterval(1))
            guard interrupted.filter({ $0.event == .previousSessionEndedUnexpectedly }).count == 1 else {
                throw CocoaError(.fileReadCorruptFile)
            }
            try check()
            await restarted.handleScenePhase(.background, now: now.addingTimeInterval(2))
            let cleanRestart = DiagnosticLogStore(baseDirectory: fixture)
            await cleanRestart.startSession(now: now.addingTimeInterval(3))
            let finalRecords = await cleanRestart.records(now: now.addingTimeInterval(3))
            guard finalRecords.filter({ $0.event == .previousSessionEndedUnexpectedly }).count == 1 else {
                throw CocoaError(.fileReadCorruptFile)
            }
            let text = await cleanRestart.exportedText(now: now.addingTimeInterval(3))
            guard text.contains("pagesRotated"), !text.contains(fixture.path) else {
                throw CocoaError(.fileReadCorruptFile)
            }
            try check()
            return DiagnosticCaseOutcome(
                status: .passed, duration: start.duration(to: .now),
                detail: String(localized: "Verified log persistence, the 14-day retention boundary, allowed record fields, and interrupted versus clean session recovery in an isolated temporary store.")
            )
        }
    }
}
