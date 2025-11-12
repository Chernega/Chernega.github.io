import SwiftUI
import AuthenticationServices

struct RootView: View {
    @EnvironmentObject private var treeStore: TreeStore
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var friendsService: FriendsService
    @EnvironmentObject private var localization: LocalizationProvider
    @EnvironmentObject private var authService: AuthService
    @AppStorage("selectedLanguage") private var selectedLanguage: AppLanguage = .english

    var body: some View {
        Group {
            if authService.isSignedIn {
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

                        ProfileView(viewModel: ProfileViewModel(treeStore: treeStore), selectedLanguage: $selectedLanguage)
                            .tabItem {
                                Label(localization.string("tab.profile"), systemImage: "sparkles")
                            }
                    }
                    .tint(AppTheme.accent)
                    .background(AppTheme.gradient.ignoresSafeArea())
                }
            } else {
                SignInWithAppleScreen(localization: localization) { result in
                    authService.handleAuthorization(result: result)
                }
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

private struct SignInWithAppleScreen: View {
    let localization: LocalizationProvider
    let completion: (Result<ASAuthorization, Error>) -> Void

    var body: some View {
        ZStack {
            AppTheme.gradient.ignoresSafeArea()

            VStack(spacing: 32) {
                VStack(spacing: 12) {
                    Text(localization.string("auth.welcome.title"))
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    Text(localization.string("auth.welcome.subtitle"))
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                SignInWithAppleButton(
                    .signIn,
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: completion
                )
                .signInWithAppleButtonStyle(.white)
                .frame(height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 32)

                Text(localization.string("auth.privacy"))
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
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
