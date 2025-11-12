import SwiftUI

@main
struct StockholmTreeQuestApp: App {
    @StateObject private var treeStore = TreeStore()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var friendsService = FriendsService()
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
                .environment(\.locale, selectedLanguage.locale)
                .task {
                    await treeStore.load()
                    await friendsService.load()
                    locationManager.requestAuthorization()
                }
                .onChange(of: scenePhase) { _, newValue in
                    if newValue == .background {
                        Task { await treeStore.persist() }
                    }
                }
                .preferredColorScheme(.dark)
        }
    }
}
