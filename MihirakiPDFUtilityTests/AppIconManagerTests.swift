import Foundation
@testable import MihirakiPDFUtility
import Testing

@Suite("App Icon Manager Tests")
@MainActor
struct AppIconManagerTests {
    @Test("AppIconOption identifiers and asset mappings")
    func appIconOptionMappings() {
        #expect(AppIconOption.default.id == "default")
        #expect(AppIconOption.default.alternateIconName == nil)
        #expect(AppIconOption.default.previewAssetName == "AppIconDefaultPreview")
        #expect(AppIconOption.default.correspondingSupporterTier == nil)

        #expect(AppIconOption.bronze.id == "AppIconBronze")
        #expect(AppIconOption.bronze.alternateIconName == "AppIconBronze")
        #expect(AppIconOption.bronze.previewAssetName == "AppIconBronzePreview")
        #expect(AppIconOption.bronze.correspondingSupporterTier == .bronze)

        #expect(AppIconOption.silver.id == "AppIconSilver")
        #expect(AppIconOption.silver.alternateIconName == "AppIconSilver")
        #expect(AppIconOption.silver.previewAssetName == "AppIconSilverPreview")
        #expect(AppIconOption.silver.correspondingSupporterTier == .silver)

        #expect(AppIconOption.gold.id == "AppIconGold")
        #expect(AppIconOption.gold.alternateIconName == "AppIconGold")
        #expect(AppIconOption.gold.previewAssetName == "AppIconGoldPreview")
        #expect(AppIconOption.gold.correspondingSupporterTier == .gold)

        #expect(AppIconOption.allCases.count == 4)
    }

    @Test("AppIconManager initializes with default icon")
    func managerInitialization() {
        let manager = AppIconManager()
        #expect(manager.currentIcon == .default)
        #expect(manager.errorMessage == nil)
    }
}
