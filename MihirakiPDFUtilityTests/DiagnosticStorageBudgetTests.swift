import Testing
@testable import MihirakiPDFUtility

struct DiagnosticStorageBudgetTests {
    let policy = DiagnosticStorageBudget()
    let mib = DiagnosticStorageBudget.mebibyte

    @Test func unavailableAndLowSpaceStopGeneration() {
        for value: Int64? in [nil, -1, 0, 512 * mib, 520 * mib - 1] {
            #expect(policy.plan(availableBytes: value).profile == .stopped)
        }
        #expect(policy.plan(availableBytes: 0).availableBytes == 0)
        #expect(policy.plan(availableBytes: nil).availableBytes == nil)
    }

    @Test func profileBoundaries() {
        #expect(policy.plan(availableBytes: 520 * mib).profile == .minimal)
        #expect(policy.plan(availableBytes: 640 * mib - 1).profile == .minimal)
        #expect(policy.plan(availableBytes: 640 * mib).profile == .reduced)
        #expect(policy.plan(availableBytes: 2560 * mib - 1).profile == .reduced)
        let full = policy.plan(availableBytes: 2560 * mib)
        #expect(full.profile == .standard)
        #expect(full.pageCounts == [12, 100, 500, 1100])
        #expect(full.includesImageStress)
        let reduced = policy.plan(availableBytes: 640 * mib)
        #expect(reduced.pageCounts == [12, 100])
        #expect(!reduced.includesImageStress)
    }

    @Test func budgetIsCappedAndCannotOverflow() {
        #expect(policy.budget(availableBytes: Int64.max) == 512 * mib)
        #expect(!policy.fits(estimatedPeakBytes: Int64.max, budgetBytes: Int64.max))
        #expect(!policy.fits(estimatedPeakBytes: -1, budgetBytes: 10))
        #expect(!policy.fits(estimatedPeakBytes: 0, budgetBytes: 10))
    }

    @Test func capacityDropAndUsageStopFurtherWrites() {
        let initial = policy.budget(availableBytes: 2560 * mib)
        #expect(policy.canContinue(initialBudgetBytes: initial, usedBytes: 0,
                                   additionalEstimatedBytes: 4 * mib, availableBytes: 520 * mib))
        #expect(!policy.canContinue(initialBudgetBytes: initial, usedBytes: 0,
                                    additionalEstimatedBytes: 4 * mib, availableBytes: 520 * mib - 1))
        #expect(!policy.canContinue(initialBudgetBytes: initial, usedBytes: initial,
                                    additionalEstimatedBytes: 1, availableBytes: Int64.max))
        #expect(!policy.canContinue(initialBudgetBytes: initial, usedBytes: 0,
                                    additionalEstimatedBytes: 1, availableBytes: nil))
    }
}
