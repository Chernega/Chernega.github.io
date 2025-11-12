import GameKit
import UIKit

@MainActor
final class GameCenterHelper: NSObject, GKGameCenterControllerDelegate {
    static let shared = GameCenterHelper()

    private override init() {
        super.init()
    }

    func authenticate(completion: @escaping (Result<Void, Error>) -> Void) {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            if let error {
                Task { @MainActor in completion(.failure(error)) }
                return
            }

            if let viewController {
                Task { @MainActor [weak self] in
                    self?.present(viewController)
                }
            } else if GKLocalPlayer.local.isAuthenticated {
                Task { @MainActor in completion(.success(())) }
            } else {
                let cancellation = NSError(
                    domain: "GameCenter",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Authentication cancelled"]
                )
                Task { @MainActor in completion(.failure(cancellation)) }
            }
        }
    }

    func presentFriendsList() {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        let controller = GKGameCenterViewController(state: .localPlayerFriendsList)
        controller.gameCenterDelegate = self
        present(controller)
    }

    private func present(_ viewController: UIViewController) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return
        }

        var topController = root
        while let presented = topController.presentedViewController {
            topController = presented
        }

        topController.present(viewController, animated: true)
    }

    nonisolated func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        Task { @MainActor in
            gameCenterViewController.dismiss(animated: true)
        }
    }
}
