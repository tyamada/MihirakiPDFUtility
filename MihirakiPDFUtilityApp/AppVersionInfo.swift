import Foundation

struct AppVersionInfo: Equatable, Sendable {
    let appName: String
    let versionNumber: String
    let buildNumber: String
    let copyright: String
    let license: String

    static let defaultPrivacyPolicyURL = URL(string: "https://tyamada.github.io/MihirakiPDFUtility/privacy.html")!
    static let japanesePrivacyPolicyURL = URL(string: "https://tyamada.github.io/MihirakiPDFUtility/privacy_ja.html")!
    static let simplifiedChinesePrivacyPolicyURL = URL(string: "https://tyamada.github.io/MihirakiPDFUtility/privacy_zh_hans.html")!
    static let traditionalChinesePrivacyPolicyURL = URL(string: "https://tyamada.github.io/MihirakiPDFUtility/privacy_zh_hant.html")!

    /// Language-specific privacy policy URLs verified to exist on the public site.
    /// Languages whose dedicated pages are not available fall back to `defaultPrivacyPolicyURL`.
    static let localizedPrivacyPolicyURLs: [String: URL] = [
        "ja": japanesePrivacyPolicyURL,
        "zh-hans": simplifiedChinesePrivacyPolicyURL,
        "zh-hant": traditionalChinesePrivacyPolicyURL,
        "de": URL(string: "https://tyamada.github.io/MihirakiPDFUtility/privacy_de.html")!,
        "es": URL(string: "https://tyamada.github.io/MihirakiPDFUtility/privacy_es.html")!,
        "fil": URL(string: "https://tyamada.github.io/MihirakiPDFUtility/privacy_fil.html")!,
        "fr": URL(string: "https://tyamada.github.io/MihirakiPDFUtility/privacy_fr.html")!,
        "id": URL(string: "https://tyamada.github.io/MihirakiPDFUtility/privacy_id.html")!,
        "it": URL(string: "https://tyamada.github.io/MihirakiPDFUtility/privacy_it.html")!,
        "ko": URL(string: "https://tyamada.github.io/MihirakiPDFUtility/privacy_ko.html")!,
        "ne": URL(string: "https://tyamada.github.io/MihirakiPDFUtility/privacy_ne.html")!,
        "pt": URL(string: "https://tyamada.github.io/MihirakiPDFUtility/privacy_pt.html")!,
        "vi": URL(string: "https://tyamada.github.io/MihirakiPDFUtility/privacy_vi.html")!,
    ]

    /// Resolves the privacy policy URL for a single language identifier, preserving
    /// script distinction for Chinese (Simplified vs Traditional) and returning nil for unmapped languages.
    static func privacyPolicyURL(forLanguageIdentifier language: String) -> URL? {
        let locale = Locale(identifier: language)
        let lang = locale.language
        let code = (lang.languageCode?.identifier ?? language).lowercased()

        if code == "zh" {
            let script = lang.script?.identifier.lowercased()
            let region = (lang.region?.identifier ?? "").uppercased()
            let lowerLanguage = language.lowercased()

            if script == "hant" || lowerLanguage.contains("hant") || ["TW", "HK", "MO"].contains(region) || lowerLanguage.contains("-tw") || lowerLanguage.contains("-hk") || lowerLanguage.contains("-mo") {
                return traditionalChinesePrivacyPolicyURL
            } else {
                return simplifiedChinesePrivacyPolicyURL
            }
        }

        return localizedPrivacyPolicyURLs[code]
    }

    static func privacyPolicyURL(
        preferredLanguages: [String] = Bundle.main.preferredLocalizations.isEmpty
            ? Locale.preferredLanguages
            : Bundle.main.preferredLocalizations
    ) -> URL {
        for language in preferredLanguages {
            if let url = privacyPolicyURL(forLanguageIdentifier: language) {
                return url
            }
        }
        return defaultPrivacyPolicyURL
    }

    var privacyPolicyURL: URL {
        Self.privacyPolicyURL()
    }

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
        ) ?? "Mihiraki: PDF Utility"
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
