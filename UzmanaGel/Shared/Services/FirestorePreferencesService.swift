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
        // Fallback or cached values from UserDefaults
        var push = UserDefaults.standard.bool(forKey: "notificationEnabled")
        var booking = UserDefaults.standard.bool(forKey: "reservationNotificationsEnabled")
        var promo = UserDefaults.standard.bool(forKey: "marketingNotificationsEnabled")
        var email = UserDefaults.standard.bool(forKey: "pref_emailNotifications")
        var sms = UserDefaults.standard.bool(forKey: "pref_smsNotifications")
        
        // If user is logged in, try fetching from Firestore
        if let uid = currentUserId {
            let doc = try await db.collection("users").document(uid).getDocument()
            if let prefs = doc.data()?["preferences"] as? [String: Any],
               let notifMap = prefs["notificationSettings"] as? [String: Any] {
                push = notifMap["pushNotificationsEnabled"] as? Bool ?? push
                email = notifMap["emailNotificationsEnabled"] as? Bool ?? email
                sms = notifMap["smsNotificationsEnabled"] as? Bool ?? sms
                booking = notifMap["bookingNotificationsEnabled"] as? Bool ?? booking
                promo = notifMap["promoNotificationsEnabled"] as? Bool ?? promo
                
                // Keep local defaults in sync
                UserDefaults.standard.set(push, forKey: "notificationEnabled")
                UserDefaults.standard.set(booking, forKey: "reservationNotificationsEnabled")
                UserDefaults.standard.set(promo, forKey: "marketingNotificationsEnabled")
                UserDefaults.standard.set(email, forKey: "pref_emailNotifications")
                UserDefaults.standard.set(sms, forKey: "pref_smsNotifications")
            }
        }
        
        return NotificationSettings(
            pushNotificationsEnabled: push,
            emailNotificationsEnabled: email,
            smsNotificationsEnabled: sms,
            bookingNotificationsEnabled: booking,
            promoNotificationsEnabled: promo
        )
    }
    
    func saveNotificationSettings(_ settings: NotificationSettings) async throws {
        // Update local UserDefaults
        UserDefaults.standard.set(settings.pushNotificationsEnabled, forKey: "notificationEnabled")
        UserDefaults.standard.set(settings.bookingNotificationsEnabled, forKey: "reservationNotificationsEnabled")
        UserDefaults.standard.set(settings.promoNotificationsEnabled, forKey: "marketingNotificationsEnabled")
        UserDefaults.standard.set(settings.emailNotificationsEnabled, forKey: "pref_emailNotifications")
        UserDefaults.standard.set(settings.smsNotificationsEnabled, forKey: "pref_smsNotifications")
        
        // Save to Firestore if logged in
        if let uid = currentUserId {
            let notifMap: [String: Any] = [
                "pushNotificationsEnabled": settings.pushNotificationsEnabled,
                "emailNotificationsEnabled": settings.emailNotificationsEnabled,
                "smsNotificationsEnabled": settings.smsNotificationsEnabled,
                "bookingNotificationsEnabled": settings.bookingNotificationsEnabled,
                "promoNotificationsEnabled": settings.promoNotificationsEnabled,
                "updatedAt": FieldValue.serverTimestamp()
            ]
            
            try await db.collection("users").document(uid).setData([
                "preferences": [
                    "notificationSettings": notifMap
                ]
            ], merge: true)
        }
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
