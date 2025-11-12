import SwiftUI

@main
struct StockholmTreeQuestApp: App {
    @StateObject private var treeStore = TreeStore()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var friendsService = FriendsService()
    @StateObject private var localizationProvider = LocalizationProvider()
    @StateObject private var authService = AuthService()
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
                .environment(\.locale, localizationProvider.language.locale)
                .task {
                    await treeStore.load()
                    locationManager.requestAuthorization()
                    localizationProvider.useSystemLanguage()
                }
                .onChange(of: scenePhase) { _, newValue in
                    if newValue == .background {
                        Task { await treeStore.persist() }
                    }
                }
                .onReceive(
                    NotificationCenter.default.publisher(for: NSLocale.currentLocaleDidChangeNotification),
                    perform: { _ in localizationProvider.useSystemLanguage() }
                )
                .preferredColorScheme(.dark)
        }
    }
}
