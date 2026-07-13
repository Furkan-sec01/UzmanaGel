
import SwiftUI
import FirebaseCore
import FirebaseAuth
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        application.registerForRemoteNotifications()
        return true
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Auth.auth().setAPNSToken(deviceToken, type: .sandbox)
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("APNs kayıt başarısız:", error.localizedDescription)
    }

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if Auth.auth().canHandleNotification(userInfo) {
            completionHandler(.noData)
            return
        }
        completionHandler(.noData)
    }
}

@main
struct UzmanaGelApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.scenePhase) private var scenePhase

    // Session & Theme
    @StateObject private var session      = SessionViewModel()
    @StateObject private var themeManager = AppThemeManager()

    @State private var showSplash = true
    @AppStorage("pref_theme") private var savedTheme: String = "system"

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()
                    .environmentObject(session)
                    .environmentObject(themeManager)
                    // Tüm SwiftUI interaktif kontrollere (Toggle, Button, vb.) renk uygular
                    .tint(themeManager.accentColor)

                if showSplash {
                    PreViewScreen()
                        .transition(.opacity)
                        .zIndex(999)
                }
            }
            .onAppear {
                applyTheme(savedTheme)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showSplash = false
                    }
                }
            }
            .onChange(of: savedTheme) { _, newTheme in
                applyTheme(newTheme)
            }
        }
    }

    private func applyTheme(_ theme: String) {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first else { return }
        let style: UIUserInterfaceStyle
        switch theme {
        case "light": style = .light
        case "dark":  style = .dark
        default:      style = .unspecified
        }
        windowScene.windows.forEach { $0.overrideUserInterfaceStyle = style }
    }
}

