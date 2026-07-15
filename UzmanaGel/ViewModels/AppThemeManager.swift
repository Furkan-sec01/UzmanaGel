//
//  AppThemeManager.swift
//  UzmanaGel
//

import SwiftUI
import Combine

class AppThemeManager: ObservableObject {

    // Bu key PreferencesPage'deki @AppStorage ile aynı olmalı
    static let accentStorageKey = "pref_accent"
    static let themeStorageKey  = "pref_theme"

    @Published var accentColor: Color = Color("PrimaryColor")

    // UserDefaults doğrudan gözlemliyoruz — @AppStorage başka bir view'dan
    // değişince biz de güncelleneceğiz.
    private var cancellable: AnyCancellable?

    init() {
        // İlk yükleme
        let savedKey = UserDefaults.standard.string(forKey: Self.accentStorageKey) ?? "default"
        self.accentColor = Self.color(for: savedKey)

        // UserDefaults değişince güncelle (PreferencesPage'deki @AppStorage yazdığında)
        cancellable = NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                let key = UserDefaults.standard.string(forKey: Self.accentStorageKey) ?? "default"
                let newColor = Self.color(for: key)
                if self?.accentColor != newColor {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        self?.accentColor = newColor
                    }
                }
            }
    }

    static func color(for key: String) -> Color {
        switch key {
        case "blue":   return .blue
        case "green":  return Color(red: 0.18, green: 0.72, blue: 0.32)
        case "purple": return .purple
        case "teal":   return .teal
        case "pink":   return .pink
        case "orange": return .orange
        default:       return Color("PrimaryColor")
        }
    }
}
