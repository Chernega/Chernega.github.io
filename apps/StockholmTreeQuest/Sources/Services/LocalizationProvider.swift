import Foundation

@MainActor
final class LocalizationProvider: ObservableObject {
    @Published private(set) var language: AppLanguage = .english

    private var bundle: Bundle = .main

    func update(language: AppLanguage) {
        self.language = language
        if let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
           let localizedBundle = Bundle(path: path) {
            bundle = localizedBundle
        } else {
            bundle = .main
        }
    }

    func string(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}
