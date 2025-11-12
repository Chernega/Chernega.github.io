import Foundation

@MainActor
final class LocalizationProvider: ObservableObject {
    @Published private(set) var language: AppLanguage

    private var bundle: Bundle
    private let englishBundle: Bundle

    init() {
        let resolved = AppLanguage.resolve(from: Locale.preferredLanguages)
        let english = LocalizationProvider.loadBundle(for: .english) ?? .main
        self.englishBundle = english
        self.bundle = LocalizationProvider.loadBundle(for: resolved) ?? english
        self.language = resolved
    }

    func update(language: AppLanguage) {
        self.language = language
        bundle = LocalizationProvider.loadBundle(for: language) ?? englishBundle
    }

    func useSystemLanguage() {
        let resolved = AppLanguage.resolve(from: Locale.preferredLanguages)
        update(language: resolved)
    }

    func string(_ key: String) -> String {
        let localized = bundle.localizedString(forKey: key, value: nil, table: nil)
        if localized == key && language != .english {
            return englishBundle.localizedString(forKey: key, value: key, table: nil)
        }
        return localized
    }

    private static func loadBundle(for language: AppLanguage) -> Bundle? {
        let searchDirectories: [String?] = ["Localization", nil]

        for directory in searchDirectories {
            if let url = Bundle.main.url(forResource: language.rawValue, withExtension: "lproj", subdirectory: directory),
               let bundle = Bundle(url: url) {
                return bundle
            }
        }

        return nil
    }
}
