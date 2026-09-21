import Foundation

struct AppVersionInfo: Equatable, Sendable {
    let appName: String
    let versionNumber: String
    let buildNumber: String
    let copyright: String
    let license: String

    init(bundle: Bundle = .main) {
        self.init(infoDictionary: bundle.infoDictionary ?? [:])
    }

    init(infoDictionary: [String: Any]) {
        appName = Self.nonemptyString(
            for: "CFBundleDisplayName",
            in: infoDictionary
        ) ?? Self.nonemptyString(
            for: "CFBundleName",
            in: infoDictionary
        ) ?? "MihirakiPDFUtility"
        versionNumber = Self.nonemptyString(
            for: "CFBundleShortVersionString",
            in: infoDictionary
        ) ?? "-"
        buildNumber = Self.nonemptyString(
            for: "CFBundleVersion",
            in: infoDictionary
        ) ?? "-"
        copyright = Self.nonemptyString(
            for: "NSHumanReadableCopyright",
            in: infoDictionary
        ) ?? "-"
        license = "GNU Affero General Public License v3.0 only (AGPL-3.0-only)"
    }

    private static func nonemptyString(
        for key: String,
        in infoDictionary: [String: Any]
    ) -> String? {
        guard let value = infoDictionary[key] as? String,
              !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return value
    }
}
