import Foundation
import Observation
import SwiftUI

/// A commemorative badge awarded to users for milestones or special events.
public struct CommemorativeBadge: Identifiable, Sendable, Equatable, Hashable {
    public let id: String
    public let name: LocalizedStringResource
    public let subtitle: LocalizedStringResource
    public let assetName: String
    public let availableFrom: Date
    public let availableUntil: Date?

    public init(
        id: String,
        name: LocalizedStringResource,
        subtitle: LocalizedStringResource,
        assetName: String,
        availableFrom: Date,
        availableUntil: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.assetName = assetName
        self.availableFrom = availableFrom
        self.availableUntil = availableUntil
    }

    public static func == (lhs: CommemorativeBadge, rhs: CommemorativeBadge) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    /// Determines if this badge is eligible for automatic claiming at the specified date.
    public func isAvailable(at date: Date = Date()) -> Bool {
        if date < availableFrom { return false }
        if let availableUntil, date > availableUntil { return false }
        return true
    }
}

/// Catalog of all defined commemorative badges.
/// To add new commemorative badges in the future, simply define and add them to `allBadges`.
public enum CommemorativeBadgeCatalog {
    /// 2026-11-01 00:00:00 JST start date
    private static let koyomiStartDate: Date = {
        var components = DateComponents()
        components.year = 2026
        components.month = 11
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .gmt
        return calendar.date(from: components) ?? Date(timeIntervalSince1970: 1793458800)
    }()

    /// Official Release Commemorative Koyomi Badge
    public static let releaseKoyomi = CommemorativeBadge(
        id: "commemorative_badge_koyomi",
        name: "Release Commemorative Koyomi Badge",
        subtitle: "Official Tameshibu Koyomi Badge celebrating the release",
        assetName: "BadgeKoyomi",
        availableFrom: koyomiStartDate,
        availableUntil: nil
    )

    /// All badges available in the app.
    public static let allBadges: [CommemorativeBadge] = [
        releaseKoyomi
    ]

    public static func badge(withID id: String) -> CommemorativeBadge? {
        allBadges.first { $0.id == id }
    }
}

/// Manages claiming, persistence, and notification of commemorative badges without requiring in-app purchases.
@MainActor
@Observable
public final class CommemorativeBadgeManager {
    public private(set) var claimedBadgeIDs: Set<String>
    public private(set) var newlyClaimedBadge: CommemorativeBadge?

    private let userDefaults: UserDefaults
    private let storageKey = "commemorative_claimed_badge_ids"

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        let saved = userDefaults.stringArray(forKey: storageKey) ?? []
        self.claimedBadgeIDs = Set(saved)
    }

    /// List of commemorative badges that have already been claimed.
    public var claimedBadges: [CommemorativeBadge] {
        CommemorativeBadgeCatalog.allBadges.filter { claimedBadgeIDs.contains($0.id) }
    }

    public func isClaimed(_ badge: CommemorativeBadge) -> Bool {
        claimedBadgeIDs.contains(badge.id)
    }

    /// Automatically claims any eligible badges if not already claimed.
    /// Returns the list of newly claimed badges during this invocation.
    @discardableResult
    public func checkAndClaimEligibleBadges(now: Date = Date()) -> [CommemorativeBadge] {
        var newlyClaimed: [CommemorativeBadge] = []

        for badge in CommemorativeBadgeCatalog.allBadges {
            if !claimedBadgeIDs.contains(badge.id) && badge.isAvailable(at: now) {
                claimedBadgeIDs.insert(badge.id)
                newlyClaimed.append(badge)
            }
        }

        if !newlyClaimed.isEmpty {
            userDefaults.set(Array(claimedBadgeIDs).sorted(), forKey: storageKey)
            if let first = newlyClaimed.first {
                newlyClaimedBadge = first
            }
        }

        return newlyClaimed
    }

    public func dismissNewlyClaimedToast() {
        newlyClaimedBadge = nil
    }
}

/// Floating toast notification displayed when a commemorative badge is claimed.
public struct CommemorativeBadgeToastView: View {
    let badge: CommemorativeBadge
    let onDismiss: () -> Void

    public var body: some View {
        Button(action: onDismiss) {
            HStack(spacing: 12) {
                Image(badge.assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .clipShape(.rect(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Badge Claimed!")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                    Text(badge.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }

                Spacer(minLength: 8)

                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
                    .font(.title3)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Commemorative Badge Claimed: \(badge.name)"))
        .accessibilityHint(Text("Tap to dismiss notification"))
    }
}


/// Enlarged detail dialog for presenting a commemorative badge.
public struct CommemorativeBadgeDetailDialog: View {
    @Environment(\.dismiss) private var dismiss

    public let badge: CommemorativeBadge

    public init(badge: CommemorativeBadge) {
        self.badge = badge
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(badge.assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 240, maxHeight: 240)
                    .clipShape(.rect(cornerRadius: 32))
                    .shadow(color: .black.opacity(0.18), radius: 16, x: 0, y: 8)
                    .accessibilityLabel(badge.name)

                VStack(spacing: 8) {
                    Text(badge.name)
                        .font(.title2.weight(.bold))
                        .multilineTextAlignment(.center)

                    Text(badge.subtitle)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
#if os(iOS)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
#endif
        }
#if os(macOS)
        .frame(minWidth: 360, minHeight: 420)
#endif
    }
}
