import Foundation

enum DiagnosticStorageProfile: String, Sendable {
    case standard, reduced, minimal, stopped
}

struct DiagnosticStoragePlan: Sendable {
    let availableBytes: Int64?
    let budgetBytes: Int64
    let profile: DiagnosticStorageProfile
    let pageCounts: [Int]
    let includesImageStress: Bool
}

/// Estimates cover the maximum simultaneously live input, output and temporary
/// files, not just input PDF size. Calibrate against actual generators in H03/H05.
struct DiagnosticStorageBudget: Sendable {
    static let mebibyte: Int64 = 1_024 * 1_024
    let reserveBytes: Int64 = 512 * mebibyte
    let maximumBytes: Int64 = 512 * mebibyte

    func budget(availableBytes: Int64?) -> Int64 {
        guard let availableBytes, availableBytes > reserveBytes else { return 0 }
        return min(maximumBytes, availableBytes / 10, availableBytes - reserveBytes)
    }

    func plan(availableBytes: Int64?) -> DiagnosticStoragePlan {
        let bytes = budget(availableBytes: availableBytes)
        let profile: DiagnosticStorageProfile
        let pages: [Int]
        // Conservative provisional peak estimates, with a 2x safety factor.
        if fits(estimatedPeakBytes: 128 * Self.mebibyte, budgetBytes: bytes) {
            profile = .standard
            pages = [12, 100, 500, 1100]
        } else if fits(estimatedPeakBytes: 32 * Self.mebibyte, budgetBytes: bytes) {
            profile = .reduced
            pages = [12, 100]
        } else if fits(estimatedPeakBytes: 4 * Self.mebibyte, budgetBytes: bytes) {
            profile = .minimal
            pages = [12]
        } else {
            profile = .stopped
            pages = []
        }
        return DiagnosticStoragePlan(
            availableBytes: availableBytes.flatMap { $0 >= 0 ? $0 : nil },
            budgetBytes: bytes, profile: profile, pageCounts: pages,
            includesImageStress: profile == .standard
        )
    }

    func fits(estimatedPeakBytes: Int64, budgetBytes: Int64) -> Bool {
        // Division avoids overflow for malformed or very large estimates.
        estimatedPeakBytes > 0 && budgetBytes > 0 && estimatedPeakBytes <= budgetBytes / 2
    }

    /// Recheck before each write batch. Existing files count against the original
    /// run budget; only additional writes count against current free space.
    func canContinue(
        initialBudgetBytes: Int64, usedBytes: Int64,
        additionalEstimatedBytes: Int64, availableBytes: Int64?
    ) -> Bool {
        guard usedBytes >= 0, additionalEstimatedBytes > 0,
              initialBudgetBytes >= usedBytes else { return false }
        return fits(
            estimatedPeakBytes: additionalEstimatedBytes,
            budgetBytes: min(initialBudgetBytes - usedBytes, budget(availableBytes: availableBytes))
        )
    }
}
