import Foundation

struct AppVersionInfo: Equatable, Sendable {
    let appName: String
    let versionNumber: String
    let buildNumber: String
    let copyright: String
    let license: String

    init(bundle: Bundle = .main) {
        var infoDictionary = bundle.infoDictionary ?? [:]
        if let localizedInfoDictionary = bundle.localizedInfoDictionary {
            infoDictionary.merge(localizedInfoDictionary) { _, localizedValue in localizedValue }
        }
        self.init(infoDictionary: infoDictionary)
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
        license = "MIT License"
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
