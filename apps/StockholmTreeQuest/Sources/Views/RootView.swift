import SwiftUI

struct RootView: View {
    @EnvironmentObject private var treeStore: TreeStore
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var friendsService: FriendsService
    @EnvironmentObject private var localization: LocalizationProvider
    @EnvironmentObject private var authService: AuthService

    var body: some View {
        ZStack {
            AppTheme.gradient.ignoresSafeArea()
            NavigationStack {
                TabView {
                    DiscoveryView(treeStore: treeStore, locationManager: locationManager)
                        .tabItem {
                            Label(localization.string("tab.discover"), systemImage: "map")
                        }

                    FriendsView()
                        .environmentObject(friendsService)
                        .tabItem {
                            Label(localization.string("tab.friends"), systemImage: "person.3.fill")
                        }

                    ProfileView(viewModel: ProfileViewModel(treeStore: treeStore))
                        .tabItem {
                            Label(localization.string("tab.profile"), systemImage: "sparkles")
                        }
                }
                .tint(AppTheme.accent)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authService.isSignedIn)
        .onChange(of: authService.isSignedIn) { _, newValue in
            if newValue {
                GameCenterHelper.shared.authenticate { result in
                    Task { @MainActor in
                        switch result {
                        case .success:
                            await friendsService.refresh()
                        case .failure(let error):
                            friendsService.lastError = error.localizedDescription
                        }
                    }
                }
            } else {
                friendsService.clear()
            }
        }
        .task {
            guard authService.isSignedIn else { return }
            GameCenterHelper.shared.authenticate { result in
                Task { @MainActor in
                    switch result {
                    case .success:
                        await friendsService.refresh()
                    case .failure(let error):
                        friendsService.lastError = error.localizedDescription
                    }
                }
            }
        }
    }
}

#Preview {
    let treeStore = TreeStore()
    let locationManager = LocationManager()
    let friendsService = FriendsService(authenticationProvider: { true }, loader: { [] })
    let localization = LocalizationProvider()
    localization.update(language: .english)
    let authService = AuthService()
    authService.signOut()

    return RootView()
        .environmentObject(treeStore)
        .environmentObject(locationManager)
        .environmentObject(friendsService)
        .environmentObject(localization)
        .environmentObject(authService)
}
