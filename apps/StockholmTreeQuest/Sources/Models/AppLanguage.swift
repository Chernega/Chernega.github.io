import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case simplifiedChinese = "zh-Hans"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Español"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .simplifiedChinese: return "简体中文"
        }
    }

    var locale: Locale {
        Locale(identifier: rawValue)
    }

    static func resolve(from preferredIdentifiers: [String]) -> AppLanguage {
        let mapping: [(language: AppLanguage, prefixes: [String])] = [
            (.english, ["en"]),
            (.spanish, ["es"]),
            (.french, ["fr"]),
            (.german, ["de"]),
            (.simplifiedChinese, ["zh-hans", "zh"])
        ]

        for identifier in preferredIdentifiers {
            let lowercased = identifier.lowercased()
            if let match = mapping.first(where: { entry in
                entry.prefixes.contains { prefix in lowercased.hasPrefix(prefix) }
            })?.language {
                return match
            }
        }

        return .english
    }
}
