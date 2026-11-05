import Foundation

struct SamplePDFCatalog: Decodable, Equatable, Sendable {
    let schemaVersion: Int
    let license: SamplePDFLicense
    let samples: [SamplePDF]
}

struct SamplePDFLicense: Decodable, Equatable, Sendable {
    let identifier: String
    let name: String
    let creator: String
    let url: URL
}

struct SamplePDFLanguage: Equatable, Sendable, Identifiable {
    var id: String { code }
    let code: String
    let nativeName: String
    let englishName: String

    var displayName: String {
        nativeName == englishName ? nativeName : "\(nativeName) (\(englishName))"
    }
}

enum SamplePDFLanguages {
    static let entries: [SamplePDFLanguage] = [
        SamplePDFLanguage(code: "en", nativeName: "English", englishName: "English"),
        SamplePDFLanguage(code: "ja", nativeName: "日本語", englishName: "Japanese"),
        SamplePDFLanguage(code: "ko", nativeName: "한국어", englishName: "Korean"),
        SamplePDFLanguage(code: "zh_cn", nativeName: "简体中文", englishName: "Chinese (Simplified)"),
        SamplePDFLanguage(code: "zh_tw", nativeName: "繁體中文（台灣）", englishName: "Chinese (Traditional, Taiwan)"),
        SamplePDFLanguage(code: "de", nativeName: "Deutsch", englishName: "German"),
        SamplePDFLanguage(code: "fr", nativeName: "Français", englishName: "French"),
        SamplePDFLanguage(code: "es", nativeName: "Español (España)", englishName: "Spanish (Spain)"),
        SamplePDFLanguage(code: "es_419", nativeName: "Español (Latinoamérica)", englishName: "Spanish (Latin America)"),
        SamplePDFLanguage(code: "it", nativeName: "Italiano", englishName: "Italian"),
        SamplePDFLanguage(code: "pt", nativeName: "Português (Brasil)", englishName: "Portuguese (Brazil)"),
        SamplePDFLanguage(code: "pt_pt", nativeName: "Português (Portugal)", englishName: "Portuguese (Portugal)"),
        SamplePDFLanguage(code: "zh_hk", nativeName: "繁體中文（香港書面語）", englishName: "Chinese (Traditional, Hong Kong written standard)"),
        SamplePDFLanguage(code: "vi", nativeName: "Tiếng Việt", englishName: "Vietnamese"),
        SamplePDFLanguage(code: "id", nativeName: "Bahasa Indonesia", englishName: "Indonesian"),
        SamplePDFLanguage(code: "fil", nativeName: "Filipino", englishName: "Filipino"),
        SamplePDFLanguage(code: "ne", nativeName: "नेपाली", englishName: "Nepali")
    ].sorted { $0.englishName < $1.englishName }

    static func defaultCode(for preferredLanguages: [String]) -> String {
        for lang in preferredLanguages {
            let lower = lang.replacingOccurrences(of: "-", with: "_").lowercased()
            if lower.hasPrefix("zh") {
                if lower.contains("hk") || lower.contains("mo") {
                    return "zh_hk"
                }
                if lower.contains("tw") || lower.contains("hant") {
                    return "zh_tw"
                }
                return "zh_cn"
            }
            if lower.hasPrefix("es") {
                let latinAmericaRegions = ["419", "ar", "bo", "br", "bz", "cl", "co", "cr", "cu", "do", "ec", "gt", "hn", "mx", "ni", "pa", "pe", "pr", "py", "sv", "uy", "ve"]
                if latinAmericaRegions.contains(where: { lower.contains($0) }) {
                    return "es_419"
                }
                return "es"
            }
            if lower.hasPrefix("pt") {
                if lower.contains("pt") && !lower.contains("br") {
                    return "pt_pt"
                }
                return "pt"
            }
            if lower.hasPrefix("tl") || lower.hasPrefix("fil") {
                return "fil"
            }
            if lower.hasPrefix("in") || lower.hasPrefix("id") {
                return "id"
            }
            let base = lower.split(separator: "_").first.map(String.init) ?? lower
            if let match = entries.first(where: { $0.code == base }) {
                return match.code
            }
        }
        return "en"
    }

    static func englishName(for code: String) -> String {
        entries.first(where: { $0.code == code })?.englishName ?? code
    }

    static func displayName(for code: String) -> String {
        entries.first(where: { $0.code == code })?.displayName ?? code
    }
}

enum SamplePDFSortOrder: String, CaseIterable, Identifiable {
    case latestFirst
    case episode1First

    var id: String { rawValue }

    func sort(samples: [SamplePDF]) -> [SamplePDF] {
        samples.sorted { lhs, rhs in
            if lhs.episode != rhs.episode {
                switch self {
                case .latestFirst:
                    return lhs.episode > rhs.episode
                case .episode1First:
                    return lhs.episode < rhs.episode
                }
            }
            return SamplePDFLanguages.englishName(for: lhs.languageCode) < SamplePDFLanguages.englishName(for: rhs.languageCode)
        }
    }
}

struct SamplePDF: Decodable, Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let languageCode: String
    let fileName: String
    let downloadURL: URL
    let byteSize: Int64
    let sha256: String
    let episode: Int
    let pages: Int?

    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: byteSize, countStyle: .file)
    }

    func languageDisplayName(locale: Locale? = nil) -> String {
        SamplePDFLanguages.displayName(for: languageCode)
    }
}

enum SamplePDFLanguageFilter {
    static func availableLanguageCodes(in samples: [SamplePDF]) -> [String] {
        let codes = Set(samples.map(\.languageCode))
        return SamplePDFLanguages.entries.map(\.code).filter { codes.contains($0) }
    }

    static func initialLanguageCode(
        preferredLanguages: [String],
        availableLanguageCodes: [String]
    ) -> String? {
        let defaultCode = SamplePDFLanguages.defaultCode(for: preferredLanguages)
        if availableLanguageCodes.contains(defaultCode) {
            return defaultCode
        }
        if availableLanguageCodes.contains("en") {
            return "en"
        }
        return availableLanguageCodes.first
    }
}

enum SamplePDFDownloadState: Equatable {
    case notDownloaded
    case downloading
    case downloaded
    case deleting
}
