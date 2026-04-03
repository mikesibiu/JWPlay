import SwiftUI

@main
struct JWPlayApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AudioPlayer.shared)
        }
    }
}
