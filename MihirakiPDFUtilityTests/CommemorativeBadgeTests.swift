import Foundation
@testable import MihirakiPDFUtility
import Testing

@Suite("Commemorative Badge Tests")
@MainActor
struct CommemorativeBadgeTests {
    private func makeTemporaryUserDefaults() -> UserDefaults {
        let suiteName = "test_commemorative_badges_\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @Test("Release Koyomi badge metadata and asset exist")
    func releaseKoyomiBadgeMetadata() {
        let badge = CommemorativeBadgeCatalog.releaseKoyomi
        #expect(badge.id == "commemorative_badge_koyomi")
        #expect(badge.assetName == "BadgeKoyomi")
        #expect(badge.availableUntil == Date(timeIntervalSince1970: 1_830_265_200))

        let catalogBadge = CommemorativeBadgeCatalog.badge(withID: "commemorative_badge_koyomi")
        #expect(catalogBadge == badge)
    }

    @Test("Koyomi badge is available on or after 2026-11-01 00:00 JST, but not before")
    func koyomiBadgeAvailabilityWindow() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!

        let beforeStart = calendar.date(from: DateComponents(year: 2026, month: 10, day: 31, hour: 23, minute: 59, second: 59))!
        let atStart = calendar.date(from: DateComponents(year: 2026, month: 11, day: 1, hour: 0, minute: 0, second: 0))!
        let afterStart = calendar.date(from: DateComponents(year: 2026, month: 11, day: 5, hour: 12, minute: 0, second: 0))!
        let futureDate = calendar.date(from: DateComponents(year: 2030, month: 1, day: 1, hour: 0, minute: 0, second: 0))!

        let badge = CommemorativeBadgeCatalog.releaseKoyomi
        #expect(!badge.isAvailable(at: beforeStart))
        #expect(badge.isAvailable(at: atStart))
        #expect(badge.isAvailable(at: afterStart))
        #expect(!badge.isAvailable(at: futureDate))
    }

    @Test("Auto-claims eligible badge on launch and persists to storage")
    func autoClaimEligibleBadge() {
        let defaults = makeTemporaryUserDefaults()
        let manager = CommemorativeBadgeManager(userDefaults: defaults)

        #expect(manager.claimedBadges.isEmpty)
        #expect(!manager.isClaimed(CommemorativeBadgeCatalog.releaseKoyomi))
        #expect(manager.newlyClaimedBadge == nil)

        // Evaluate at a valid date
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let validDate = calendar.date(from: DateComponents(year: 2026, month: 11, day: 2, hour: 10, minute: 0))!

        let newlyClaimed = manager.checkAndClaimEligibleBadges(now: validDate)
        #expect(newlyClaimed.count == 1)
        #expect(newlyClaimed.first?.id == CommemorativeBadgeCatalog.releaseKoyomi.id)
        #expect(manager.newlyClaimedBadge?.id == CommemorativeBadgeCatalog.releaseKoyomi.id)
        #expect(manager.isClaimed(CommemorativeBadgeCatalog.releaseKoyomi))
        #expect(manager.claimedBadges.count == 1)

        // Check persistence in a new instance with the same UserDefaults
        let newManagerInstance = CommemorativeBadgeManager(userDefaults: defaults)
        #expect(newManagerInstance.isClaimed(CommemorativeBadgeCatalog.releaseKoyomi))
        #expect(newManagerInstance.claimedBadges.count == 1)

        // Subsequent check does not re-claim
        let recheckClaimed = newManagerInstance.checkAndClaimEligibleBadges(now: validDate)
        #expect(recheckClaimed.isEmpty)
        #expect(newManagerInstance.newlyClaimedBadge == nil)
    }

    @Test("Dismissing toast clears newlyClaimedBadge")
    func dismissToastClearsNewlyClaimedBadge() {
        let defaults = makeTemporaryUserDefaults()
        let manager = CommemorativeBadgeManager(userDefaults: defaults)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let validDate = calendar.date(from: DateComponents(year: 2026, month: 11, day: 2, hour: 10, minute: 0))!

        manager.checkAndClaimEligibleBadges(now: validDate)
        #expect(manager.newlyClaimedBadge != nil)

        manager.dismissNewlyClaimedToast()
        #expect(manager.newlyClaimedBadge == nil)
    }

    @Test("Badges use an inclusive start and exclusive end")
    func futureBadgesWithEndDates() {
        let startDate = Date(timeIntervalSince1970: 1000)
        let endDate = Date(timeIntervalSince1970: 2000)

        let customBadge = CommemorativeBadge(
            id: "future_event_badge",
            name: "Future Badge",
            subtitle: "Test Subtitle",
            assetName: "BadgeSumire",
            availableFrom: startDate,
            availableUntil: endDate
        )

        #expect(!customBadge.isAvailable(at: Date(timeIntervalSince1970: 500)))
        #expect(customBadge.isAvailable(at: Date(timeIntervalSince1970: 1000)))
        #expect(customBadge.isAvailable(at: Date(timeIntervalSince1970: 1500)))
        #expect(!customBadge.isAvailable(at: Date(timeIntervalSince1970: 2000)))
        #expect(!customBadge.isAvailable(at: Date(timeIntervalSince1970: 2001)))
    }

    @Test("Koyomi includes the whole last JST day but excludes the cutoff instant")
    func koyomiDeadlineBoundary() throws {
        let formatter = ISO8601DateFormatter()
        let start = try #require(formatter.date(from: "2026-11-01T00:00:00+09:00"))
        let cutoff = try #require(formatter.date(from: "2028-01-01T00:00:00+09:00"))
        #expect(cutoff == formatter.date(from: "2027-12-31T15:00:00Z"))
        let badge = CommemorativeBadgeCatalog.releaseKoyomi
        #expect(badge.availableFrom == start)
        #expect(badge.availableUntil == cutoff)
        #expect(!badge.isAvailable(at: start.addingTimeInterval(-0.001)))
        #expect(badge.isAvailable(at: start))
        #expect(badge.isAvailable(at: cutoff.addingTimeInterval(-0.001)))
        #expect(!badge.isAvailable(at: cutoff))
        #expect(!badge.isAvailable(at: cutoff.addingTimeInterval(0.001)))
        for date in [cutoff, cutoff.addingTimeInterval(86400)] {
            let manager = CommemorativeBadgeManager(userDefaults: makeTemporaryUserDefaults())
            #expect(manager.checkAndClaimEligibleBadges(now: date).isEmpty)
            #expect(manager.claimedBadges.isEmpty)
            #expect(manager.newlyClaimedBadge == nil)
        }
        let lastMoment = CommemorativeBadgeManager(userDefaults: makeTemporaryUserDefaults())
        #expect(lastMoment.checkAndClaimEligibleBadges(now: cutoff.addingTimeInterval(-0.001)).count == 1)
        #expect(lastMoment.newlyClaimedBadge?.id == badge.id)
    }

    @Test("Saved Koyomi badge survives the deadline, reload and rechecks without a new toast")
    func savedBadgeNeverExpires() {
        let defaults = makeTemporaryUserDefaults()
        let badge = CommemorativeBadgeCatalog.releaseKoyomi
        let manager = CommemorativeBadgeManager(userDefaults: defaults)
        #expect(manager.checkAndClaimEligibleBadges(now: badge.availableFrom).count == 1)
        manager.dismissNewlyClaimedToast()
        let reloaded = CommemorativeBadgeManager(userDefaults: defaults)
        let after = Date(timeIntervalSince1970: 2_000_000_000)
        #expect(reloaded.checkAndClaimEligibleBadges(now: after).isEmpty)
        #expect(reloaded.isClaimed(badge))
        #expect(reloaded.claimedBadges.map(\.id) == [badge.id])
        #expect(reloaded.newlyClaimedBadge == nil)
        #expect(defaults.stringArray(forKey: "commemorative_claimed_badge_ids") == [badge.id])

        // Existing installations keep the same persisted ID, without account migration.
        let existingDefaults = makeTemporaryUserDefaults()
        existingDefaults.set([badge.id], forKey: "commemorative_claimed_badge_ids")
        let existingUser = CommemorativeBadgeManager(userDefaults: existingDefaults)
        #expect(existingUser.checkAndClaimEligibleBadges(now: after).isEmpty)
        #expect(existingUser.claimedBadges == [badge])
    }

}
