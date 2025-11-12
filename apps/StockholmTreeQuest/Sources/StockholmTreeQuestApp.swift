import SwiftUI

@main
struct StockholmTreeQuestApp: App {
    @StateObject private var treeStore = TreeStore()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var friendsService = FriendsService()
    @StateObject private var localizationProvider = LocalizationProvider()
    @StateObject private var authService = AuthService()
    @AppStorage("selectedLanguage") private var selectedLanguage: AppLanguage = .english
    @Environment(\.scenePhase) private var scenePhase

    init() {
        AppTheme.configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(treeStore)
                .environmentObject(locationManager)
                .environmentObject(friendsService)
                .environmentObject(localizationProvider)
                .environmentObject(authService)
                .environment(\.locale, selectedLanguage.locale)
                .task {
                    await treeStore.load()
                    locationManager.requestAuthorization()
                    localizationProvider.update(language: selectedLanguage)
                }
                .onChange(of: scenePhase) { _, newValue in
                    if newValue == .background {
                        Task { await treeStore.persist() }
                    }
                }
                .onChange(of: selectedLanguage) { _, newValue in
                    localizationProvider.update(language: newValue)
                }
                .preferredColorScheme(.dark)
        }
    }
}
