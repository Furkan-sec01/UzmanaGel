import Foundation
import SwiftUI
import Combine

@MainActor
class PreferencesViewModel: ObservableObject {
    // Notification states
    @Published var pushNotificationsEnabled = false
    @Published var emailNotificationsEnabled = false
    @Published var smsNotificationsEnabled = false
    @Published var bookingNotificationsEnabled = false
    @Published var promoNotificationsEnabled = false
    
    // Theme and Language
    @Published var themeSelection: AppTheme = .system
    @Published var selectedLanguage: Language = .turkish
    @Published var showLanguageAlert = false
    
    // Privacy settings
    @Published var locationSharingEnabled = false
    @Published var profileVisibilityPublic = false
    @Published var dataCollectionConsent = false
    
    @Published var isLoading = false
    @Published var successMessage: String?
    
    private let preferencesService: PreferencesService
    
    init(preferencesService: PreferencesService = MockPreferencesService()) {
        self.preferencesService = preferencesService
    }
    
    func loadPreferences() async {
        isLoading = true
        do {
            let settings = try await preferencesService.fetchNotificationSettings()
            self.pushNotificationsEnabled = settings.pushNotificationsEnabled
            self.emailNotificationsEnabled = settings.emailNotificationsEnabled
            self.smsNotificationsEnabled = settings.smsNotificationsEnabled
            self.bookingNotificationsEnabled = settings.bookingNotificationsEnabled
            self.promoNotificationsEnabled = settings.promoNotificationsEnabled
            
            self.themeSelection = try await preferencesService.fetchTheme()
            self.selectedLanguage = try await preferencesService.fetchLanguage()
            
            let privacy = try await preferencesService.fetchPrivacySettings()
            self.locationSharingEnabled = privacy["locationSharing"] ?? true
            self.profileVisibilityPublic = privacy["profilePublic"] ?? true
            self.dataCollectionConsent = privacy["dataCollection"] ?? true
            
        } catch {
            // Error handling
        }
        isLoading = false
    }
    
    func savePreferences() async {
        isLoading = true
        do {
            let settings = NotificationSettings(
                pushNotificationsEnabled: pushNotificationsEnabled,
                emailNotificationsEnabled: emailNotificationsEnabled,
                smsNotificationsEnabled: smsNotificationsEnabled,
                bookingNotificationsEnabled: bookingNotificationsEnabled,
                promoNotificationsEnabled: promoNotificationsEnabled
            )
            try await preferencesService.saveNotificationSettings(settings)
            try await preferencesService.saveTheme(themeSelection)
            try await preferencesService.saveLanguage(selectedLanguage)
            
            let privacy = [
                "locationSharing": locationSharingEnabled,
                "profilePublic": profileVisibilityPublic,
                "dataCollection": dataCollectionConsent
            ]
            try await preferencesService.savePrivacySettings(privacy)
            
            applyTheme(themeSelection)
            
            successMessage = "Tercihleriniz kaydedildi."
        } catch {
            // Error handling
        }
        isLoading = false
    }
    
    func applyTheme(_ theme: AppTheme) {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let window = windowScene?.windows.first
        
        switch theme {
        case .light:
            window?.overrideUserInterfaceStyle = .light
        case .dark:
            window?.overrideUserInterfaceStyle = .dark
        case .system:
            window?.overrideUserInterfaceStyle = .unspecified
        }
    }
    
    func triggerLanguageAlert() {
        LanguageManager.shared.languageCode = selectedLanguage == .english ? "en" : "tr"
    }
}
