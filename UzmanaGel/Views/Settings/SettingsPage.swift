//
//  SettingsPage.swift
//  UzmanaGel
//
//  Created by Halil Keremoğlu on 9.07.2026.
//

import SwiftUI

struct SettingsPage: View {
        
    @AppStorage("notificationEnabled")
    private var notificationEnabled = true
    @ObservedObject private var langManager = LanguageManager.shared
    
    @AppStorage("selectedAppearance")
    private var selectedAppearance = "system"
    
    @AppStorage("pref_theme")
    private var savedTheme = "system"
    
    @AppStorage("pref_language")
    private var selectedLanguageCode = "tr"
    
    @State private var hasReadKVKK = false
    
    // Theme Colors
    private let bgColor = Color("BackgroundColor")
    private let cardColor = Color("CardBackground")
    private let primaryColor = Color("PrimaryColor")
    private let accentYellow = Color("TertiaryColor")
    
    private let languages = [("tr", "🇹🇷 Türkçe"), ("en", "🇬🇧 English")]
    
    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    appSection
                    privacySection
                    supportSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
        }
        .navigationTitle("Ayarlar".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - App Section
    private var appSection: some View {
        sectionCard(title: "Uygulama", icon: "gearshape.fill", iconColor: .blue) {
            VStack(spacing: 0) {
                // Notifications Toggle
                HStack(spacing: 12) {
                    iconBox("bell.fill", tint: .orange)
                    Text("Bildirimler".localized)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                    Toggle("", isOn: $notificationEnabled)
                        .tint(accentYellow)
                        .labelsHidden()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                
                customDivider()
                
                // Notification Preferences
                NavigationLink {
                    NotificationPreferencesPage()
                } label: {
                    navigationRowContent(
                        title: "Bildirim Tercihleri".localized,
                        icon: "bell.badge.fill",
                        tint: .red
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Privacy Section
    private var privacySection: some View {
        sectionCard(title: "Gizlilik", icon: "lock.shield.fill", iconColor: .purple) {
            VStack(spacing: 0) {
                NavigationLink {
                    Kvkk(hasRead: $hasReadKVKK, showsAcceptance: false)
                } label: {
                    navigationRowContent(
                        title: "KVKK ve Gizlilik".localized,
                        icon: "hand.raised.fill",
                        tint: .purple
                    )
                }
                .buttonStyle(.plain)
                
                customDivider()
                
                NavigationLink {
                    TermsOfServicePage()
                } label: {
                    navigationRowContent(
                        title: "Kullanım Şartları".localized,
                        icon: "doc.text.fill",
                        tint: .indigo
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Support Section
    private var supportSection: some View {
        sectionCard(title: "Destek", icon: "questionmark.circle.fill", iconColor: .green) {
            VStack(spacing: 0) {
                NavigationLink {
                    HelpPage()
                } label: {
                    navigationRowContent(
                        title: "Yardım".localized,
                        icon: "questionmark.circle.fill",
                        tint: .green
                    )
                }
                .buttonStyle(.plain)
                
                customDivider()
                
                NavigationLink {
                    AboutPage()
                } label: {
                    navigationRowContent(
                        title: "Hakkında".localized,
                        icon: "info.circle.fill",
                        tint: .teal
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Reusable Components & Helpers
    private func sectionCard<Content: View>(
        title: String,
        icon: String,
        iconColor: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(iconColor)
                Text(title.localized)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
            }
            .padding(.leading, 4)
            
            VStack(spacing: 0) {
                content()
            }
            .background(cardColor)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
        }
    }
    
    private func navigationRowContent(title: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            iconBox(icon, tint: tint)
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
    
    private func iconBox(_ name: String, tint: Color) -> some View {
        Image(systemName: name)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(tint)
            .frame(width: 34, height: 34)
            .background(tint.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
    
    private func customDivider() -> some View {
        Divider()
            .background(Color.primary.opacity(0.06))
            .padding(.leading, 62)
    }
    
    private func applyAppearance(_ mode: String) {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first else { return }
        let style: UIUserInterfaceStyle
        switch mode {
        case "light": style = .light
        case "dark":  style = .dark
        default:      style = .unspecified
        }
        UIView.animate(withDuration: 0.3) {
            windowScene.windows.forEach { $0.overrideUserInterfaceStyle = style }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsPage()
    }
}
