import Foundation
import AuthenticationServices

@MainActor
final class AuthService: ObservableObject {
    @Published private(set) var isSignedIn: Bool
    @Published private(set) var displayName: String?
    @Published var lastError: String?

    private let userIDKey = "appleSignInUserID"

    init() {
        if let storedID = UserDefaults.standard.string(forKey: userIDKey), !storedID.isEmpty {
            isSignedIn = true
        } else {
            isSignedIn = false
        }
    }

    func handleAuthorization(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                UserDefaults.standard.set(credential.user, forKey: userIDKey)
                if let components = credential.fullName {
                    let formatter = PersonNameComponentsFormatter()
                    let formatted = formatter.string(from: components)
                    if !formatted.trimmingCharacters(in: .whitespaces).isEmpty {
                        displayName = formatted
                    }
                }
                isSignedIn = true
                lastError = nil
            }
        case .failure(let error):
            lastError = error.localizedDescription
            isSignedIn = false
        }
    }

    func signOut() {
        UserDefaults.standard.removeObject(forKey: userIDKey)
        isSignedIn = false
        displayName = nil
    }
}
