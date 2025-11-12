import SwiftUI

struct RootView: View {
    @EnvironmentObject private var treeStore: TreeStore
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var friendsService: FriendsService
    @AppStorage("selectedLanguage") private var selectedLanguage: AppLanguage = .english

    var body: some View {
        NavigationStack {
            TabView {
                DiscoveryView(treeStore: treeStore, locationManager: locationManager)
                    .tabItem {
                        Label(NSLocalizedString("tab.discover", comment: ""), systemImage: "map")
                    }

                FriendsView()
                    .environmentObject(friendsService)
                    .tabItem {
                        Label(NSLocalizedString("tab.friends", comment: ""), systemImage: "person.3.fill")
                    }

                ProfileView(viewModel: ProfileViewModel(treeStore: treeStore), selectedLanguage: $selectedLanguage)
                    .tabItem {
                        Label(NSLocalizedString("tab.profile", comment: ""), systemImage: "sparkles")
                    }
            }
            .tint(AppTheme.accent)
            .background(AppTheme.gradient.ignoresSafeArea())
        }
    }
}

#Preview {
    RootView()
        .environmentObject(TreeStore())
        .environmentObject(LocationManager())
        .environmentObject(FriendsService())
}
