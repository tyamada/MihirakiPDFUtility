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
        #expect(badge.availableUntil == nil)

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
        #expect(badge.isAvailable(at: futureDate))
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

    @Test("Future badges with end dates respect availability window")
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
        #expect(customBadge.isAvailable(at: Date(timeIntervalSince1970: 2000)))
        #expect(!customBadge.isAvailable(at: Date(timeIntervalSince1970: 2001)))
    }
}
