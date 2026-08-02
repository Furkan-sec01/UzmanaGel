//
//  FirestorePreferencesService.swift
//  UzmanaGel
//
//  Created by Antigravity on 17.07.2026.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import SwiftUI


class FirestorePreferencesService: PreferencesService {
    private let db = Firestore.firestore()
    
    private var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
    
    // MARK: - Notification Settings
    func fetchNotificationSettings() async throws -> NotificationSettings {
        let defaults = UserDefaults.standard

        var push =
            defaults.object(forKey: "notificationEnabled")
            as? Bool ?? true

        var email =
            defaults.object(forKey: "pref_emailNotifications")
            as? Bool ?? true

        var sms =
            defaults.object(forKey: "pref_smsNotifications")
            as? Bool ?? false

        let hasLocalMessage =
            defaults.object(
                forKey: "messageNotificationsEnabled"
            ) != nil

        var message =
            defaults.object(
                forKey: "messageNotificationsEnabled"
            ) as? Bool ?? true

        let hasLocalSystem =
            defaults.object(
                forKey: "systemNotificationsEnabled"
            ) != nil

        var system =
            defaults.object(
                forKey: "systemNotificationsEnabled"
            ) as? Bool ?? true

        var booking =
            defaults.object(
                forKey: "reservationNotificationsEnabled"
            ) as? Bool ?? true

        let hasLocalMarketing =
            defaults.object(
                forKey: "marketingNotificationsEnabled"
            ) != nil

        var marketing =
            defaults.object(
                forKey: "marketingNotificationsEnabled"
            ) as? Bool ?? false

        if let uid = currentUserId {
            let document = try await db
                .collection("users")
                .document(uid)
                .getDocument()

            if let preferences =
                document.data()?["preferences"] as? [String: Any],
               let notificationMap =
                preferences["notificationSettings"]
                    as? [String: Any] {

                push =
                    notificationMap["pushNotificationsEnabled"]
                    as? Bool ?? push

                email =
                    notificationMap["emailNotificationsEnabled"]
                    as? Bool ?? email

                sms =
                    notificationMap["smsNotificationsEnabled"]
                    as? Bool ?? sms

                if let storedMessage =
                    notificationMap["messageNotificationsEnabled"]
                        as? Bool {
                    message = storedMessage
                } else if !hasLocalMessage {
                    message =
                        notificationMap["smsNotificationsEnabled"]
                        as? Bool ?? message
                }

                if let storedSystem =
                    notificationMap["systemNotificationsEnabled"]
                        as? Bool {
                    system = storedSystem
                } else if !hasLocalSystem {
                    system =
                        notificationMap["emailNotificationsEnabled"]
                        as? Bool ?? system
                }

                booking =
                    notificationMap["bookingNotificationsEnabled"]
                    as? Bool ?? booking

                if let storedMarketing =
                    notificationMap["marketingNotificationsEnabled"]
                        as? Bool {
                    marketing = storedMarketing
                } else if !hasLocalMarketing {
                    marketing =
                        notificationMap["promoNotificationsEnabled"]
                        as? Bool ?? marketing
                }
            }
        }

        defaults.set(push, forKey: "notificationEnabled")
        defaults.set(
            email,
            forKey: "pref_emailNotifications"
        )
        defaults.set(
            sms,
            forKey: "pref_smsNotifications"
        )
        defaults.set(
            message,
            forKey: "messageNotificationsEnabled"
        )
        defaults.set(
            system,
            forKey: "systemNotificationsEnabled"
        )
        defaults.set(
            booking,
            forKey: "reservationNotificationsEnabled"
        )
        defaults.set(
            marketing,
            forKey: "marketingNotificationsEnabled"
        )

        return NotificationSettings(
            pushNotificationsEnabled: push,
            emailNotificationsEnabled: email,
            smsNotificationsEnabled: sms,
            messageNotificationsEnabled: message,
            systemNotificationsEnabled: system,
            bookingNotificationsEnabled: booking,
            marketingNotificationsEnabled: marketing,
            promoNotificationsEnabled: marketing
        )
    }

    func saveNotificationSettings(
        _ settings: NotificationSettings
    ) async throws {
        let defaults = UserDefaults.standard

        defaults.set(
            settings.pushNotificationsEnabled,
            forKey: "notificationEnabled"
        )
        defaults.set(
            settings.emailNotificationsEnabled,
            forKey: "pref_emailNotifications"
        )
        defaults.set(
            settings.smsNotificationsEnabled,
            forKey: "pref_smsNotifications"
        )
        defaults.set(
            settings.messageNotificationsEnabled,
            forKey: "messageNotificationsEnabled"
        )
        defaults.set(
            settings.systemNotificationsEnabled,
            forKey: "systemNotificationsEnabled"
        )
        defaults.set(
            settings.bookingNotificationsEnabled,
            forKey: "reservationNotificationsEnabled"
        )
        defaults.set(
            settings.marketingNotificationsEnabled,
            forKey: "marketingNotificationsEnabled"
        )

        guard let uid = currentUserId else {
            return
        }

        let notificationMap: [String: Any] = [
            "pushNotificationsEnabled":
                settings.pushNotificationsEnabled,
            "emailNotificationsEnabled":
                settings.emailNotificationsEnabled,
            "smsNotificationsEnabled":
                settings.smsNotificationsEnabled,
            "messageNotificationsEnabled":
                settings.messageNotificationsEnabled,
            "systemNotificationsEnabled":
                settings.systemNotificationsEnabled,
            "bookingNotificationsEnabled":
                settings.bookingNotificationsEnabled,
            "marketingNotificationsEnabled":
                settings.marketingNotificationsEnabled,

            // Keep the old field during migration
            "promoNotificationsEnabled":
                settings.marketingNotificationsEnabled,
            "updatedAt": FieldValue.serverTimestamp()
        ]

        try await db
            .collection("users")
            .document(uid)
            .setData(
                [
                    "preferences": [
                        "notificationSettings":
                            notificationMap
                    ]
                ],
                merge: true
            )
    }

    // MARK: - Theme
    func fetchTheme() async throws -> AppTheme {
        let savedThemeRaw = UserDefaults.standard.string(forKey: "app_theme") ?? AppTheme.system.rawValue
        var theme = AppTheme(rawValue: savedThemeRaw) ?? .system
        
        if let uid = currentUserId {
            let doc = try await db.collection("users").document(uid).getDocument()
            if let prefs = doc.data()?["preferences"] as? [String: Any],
               let themeStr = prefs["theme"] as? String,
               let parsedTheme = AppTheme(rawValue: themeStr) {
                theme = parsedTheme
                UserDefaults.standard.set(theme.rawValue, forKey: "app_theme")
            }
        }
        return theme
    }
    
    func saveTheme(_ theme: AppTheme) async throws {
        UserDefaults.standard.set(theme.rawValue, forKey: "app_theme")
        
        if let uid = currentUserId {
            try await db.collection("users").document(uid).setData([
                "preferences": [
                    "theme": theme.rawValue
                ]
            ], merge: true)
        }
    }
    
    // MARK: - Language
    func fetchLanguage() async throws -> Language {
        let currentCode = LanguageManager.shared.languageCode
        var lang: Language = currentCode == "en" ? .english : .turkish
        
        if let uid = currentUserId {
            let doc = try await db.collection("users").document(uid).getDocument()
            if let prefs = doc.data()?["preferences"] as? [String: Any],
               let langCode = prefs["language"] as? String {
                lang = langCode == "en" ? .english : .turkish
                DispatchQueue.main.async {
                    LanguageManager.shared.languageCode = lang == .english ? "en" : "tr"
                }
            }
        }
        return lang
    }
    
    func saveLanguage(_ language: Language) async throws {
        let code = language == .english ? "en" : "tr"
        DispatchQueue.main.async {
            LanguageManager.shared.languageCode = code
        }
        
        if let uid = currentUserId {
            try await db.collection("users").document(uid).setData([
                "preferences": [
                    "language": code
                ]
            ], merge: true)
        }
    }
    
    // MARK: - Privacy Settings
    func fetchPrivacySettings() async throws -> [String: Bool] {
        var privacy = [
            "locationSharing": UserDefaults.standard.object(forKey: "pref_locationSharing") as? Bool ?? true,
            "profilePublic": UserDefaults.standard.object(forKey: "pref_profilePublic") as? Bool ?? true,
            "dataCollection": UserDefaults.standard.object(forKey: "pref_dataCollection") as? Bool ?? true
        ]
        
        if let uid = currentUserId {
            let doc = try await db.collection("users").document(uid).getDocument()
            if let prefs = doc.data()?["preferences"] as? [String: Any],
               let privacyMap = prefs["privacy"] as? [String: Bool] {
                if let loc = privacyMap["locationSharing"] { privacy["locationSharing"] = loc }
                if let pub = privacyMap["profilePublic"] { privacy["profilePublic"] = pub }
                if let data = privacyMap["dataCollection"] { privacy["dataCollection"] = data }
                
                UserDefaults.standard.set(privacy["locationSharing"], forKey: "pref_locationSharing")
                UserDefaults.standard.set(privacy["profilePublic"], forKey: "pref_profilePublic")
                UserDefaults.standard.set(privacy["dataCollection"], forKey: "pref_dataCollection")
            }
        }
        
        return privacy
    }
    
    func savePrivacySettings(_ settings: [String: Bool]) async throws {
        if let loc = settings["locationSharing"] { UserDefaults.standard.set(loc, forKey: "pref_locationSharing") }
        if let pub = settings["profilePublic"] { UserDefaults.standard.set(pub, forKey: "pref_profilePublic") }
        if let data = settings["dataCollection"] { UserDefaults.standard.set(data, forKey: "pref_dataCollection") }
        
        if let uid = currentUserId {
            try await db.collection("users").document(uid).setData([
                "preferences": [
                    "privacy": settings
                ]
            ], merge: true)
        }
    }
}
