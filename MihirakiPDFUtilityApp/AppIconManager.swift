import Foundation
import Observation
import SwiftUI
#if os(iOS)
import UIKit
#endif

/// App icon options available for the application.
enum AppIconOption: String, CaseIterable, Identifiable, Sendable {
    case `default` = "default"
    case bronze = "AppIconBronze"
    case silver = "AppIconSilver"
    case gold = "AppIconGold"

    var id: String { rawValue }

    var displayName: LocalizedStringResource {
        switch self {
        case .default: "Default"
        case .bronze: "Bronze Supporter"
        case .silver: "Silver Supporter"
        case .gold: "Gold Supporter"
        }
    }

    var previewAssetName: String {
        switch self {
        case .default: "AppIconDefaultPreview"
        case .bronze: "AppIconBronzePreview"
        case .silver: "AppIconSilverPreview"
        case .gold: "AppIconGoldPreview"
        }
    }

    var alternateIconName: String? {
        switch self {
        case .default: nil
        case .bronze: "AppIconBronze"
        case .silver: "AppIconSilver"
        case .gold: "AppIconGold"
        }
    }

    var correspondingSupporterTier: TipManager.SupporterIcon? {
        switch self {
        case .default: nil
        case .bronze: .bronze
        case .silver: .silver
        case .gold: .gold
        }
    }
}

/// Manages selecting and querying alternate app icons.
@MainActor
@Observable
final class AppIconManager {
    static let shared = AppIconManager()

    private(set) var currentIcon: AppIconOption = .default
    private(set) var errorMessage: String?

    var supportsAlternateIcons: Bool {
        #if os(iOS)
        UIApplication.shared.supportsAlternateIcons
        #else
        false
        #endif
    }

    init() {
        refreshCurrentIcon()
    }

    func refreshCurrentIcon() {
        #if os(iOS)
        let current = UIApplication.shared.alternateIconName
        if let current, let option = AppIconOption(rawValue: current) {
            self.currentIcon = option
        } else {
            self.currentIcon = .default
        }
        #else
        self.currentIcon = .default
        #endif
    }

    func selectIcon(_ option: AppIconOption) async {
        #if os(iOS)
        guard supportsAlternateIcons else { return }
        do {
            try await UIApplication.shared.setAlternateIconName(option.alternateIconName)
            self.currentIcon = option
            self.errorMessage = nil
        } catch {
            self.errorMessage = error.localizedDescription
        }
        #else
        self.currentIcon = option
        #endif
    }
}
