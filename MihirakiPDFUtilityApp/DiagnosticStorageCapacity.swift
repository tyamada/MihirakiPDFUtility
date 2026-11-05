import Foundation

struct DiagnosticStorageCapacity: Sendable {
    let read: @Sendable (URL) -> Int64?

    static let live = Self { directory in
        resolve(
            opportunistic: {
                var url = directory
                url.removeAllCachedResourceValues()
                return try url.resourceValues(forKeys: [.volumeAvailableCapacityForOpportunisticUsageKey])
                    .volumeAvailableCapacityForOpportunisticUsage
            },
            fallback: {
                var url = directory
                url.removeAllCachedResourceValues()
                return try url.resourceValues(forKeys: [.volumeAvailableCapacityKey])
                    .volumeAvailableCapacity.map(Int64.init)
            }
        )
    }

    // Zero is a valid answer, not a reason to try a more generous capacity API.
    static func resolve(
        opportunistic: () throws -> Int64?,
        fallback: () throws -> Int64?
    ) -> Int64? {
        if let value = try? opportunistic(), value >= 0 { return value }
        if let value = try? fallback(), value >= 0 { return value }
        return nil
    }
}
