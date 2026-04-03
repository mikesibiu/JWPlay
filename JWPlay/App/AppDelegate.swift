import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        CacheService.shared.clearIfVersionChanged()
        // AudioPlayer.shared initialises the AVAudioSession in its own init —
        // touching the singleton here ensures it's ready before any playback request.
        _ = AudioPlayer.shared
        return true
    }
}
// Note: No SceneDelegate class here. SwiftUI's @main App protocol manages the
// UIWindowScene automatically. Registering a custom UISceneDelegateClassName for
// UIWindowSceneSessionRoleApplication would override SwiftUI's window management
// and cause a black screen — do not add one.
