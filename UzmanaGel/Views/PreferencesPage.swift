//
//  PreferencesPage.swift
//  UzmanaGel
//

import SwiftUI
import UserNotifications

struct PreferencesPage: View {

    // MARK: - Notification Prefs
    @AppStorage("pref_push_enabled")    private var pushEnabled: Bool = true
    @AppStorage("pref_email_notif")     private var emailNotifEnabled: Bool = true
    @AppStorage("pref_sms_notif")       private var smsNotifEnabled: Bool = false
    @AppStorage("pref_notif_rezerv")    private var notifRezervEnabled: Bool = true
    @AppStorage("pref_notif_promo")     private var notifPromoEnabled: Bool = true
    @AppStorage("pref_notif_sistem")    private var notifSistemEnabled: Bool = true

    // MARK: - Appearance
    @AppStorage("pref_theme")           private var selectedTheme: String = "system"
    @AppStorage("pref_accent")          private var selectedAccent: String = "orange"

    // MARK: - Language
    @AppStorage("pref_language")        private var selectedLanguage: String = "tr"
    @ObservedObject private var langManager = LanguageManager.shared

    // MARK: - Privacy
    @AppStorage("pref_location_share")  private var locationShareEnabled: Bool = true
    @AppStorage("pref_profile_public")  private var profilePublic: Bool = true
    @AppStorage("pref_data_collection") private var dataCollectionEnabled: Bool = true

    // MARK: - Runtime States
    @State private var notifAuthStatus: UNAuthorizationStatus = .notDetermined
    @State private var showNotifDeniedAlert = false
    @State private var savedToast = false

    // Colors
    private let accentYellow = Color("TertiaryColor")
    private let bgColor      = Color("BackgroundColor")
    private let primaryColor = Color("PrimaryColor")

    private let themes: [(id: String, label: String, icon: String)] = [
        ("system", "Sistem",  "circle.lefthalf.filled"),
        ("light",  "Açık",    "sun.max.fill"),
        ("dark",   "Koyu",    "moon.fill")
    ]

    private let languages = [("tr", "🇹🇷 Türkçe"), ("en", "🇬🇧 English")]

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    notificationSection
                    languageSection
                    privacySection
                    autoSaveNote
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Tercihler".localized)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkNotifAuthStatus()
            applyTheme()
            selectedAccent = "default"
        }
        .onChange(of: selectedTheme) { _, _ in applyTheme() }
        .alert("Bildirim İzni Gerekli".localized, isPresented: $showNotifDeniedAlert) {
            Button("Ayarlara Git".localized) {
                openSettings()
            }
            Button("Vazgeç".localized, role: .cancel) {
                pushEnabled = false
            }
        } message: {
            Text("Bildirim göndermek için lütfen Ayarlar > UzmanaGel > Bildirimler bölümünden izin verin.".localized)
        }
    }

    // MARK: - Notification Section
    private var notificationSection: some View {
        sectionCard(title: "BİLDİRİM AYARLARI", icon: "bell.badge.fill", iconColor: .red) {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    iconBox("bell.fill", tint: .red)
                    Text("Anlık Bildirimler (Push)".localized)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(primaryColor)
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { pushEnabled && notifAuthStatus == .authorized },
                        set: { newVal in
                            newVal ? requestNotifPermission() : (pushEnabled = false)
                            flashToast()
                        }
                    ))
                    .tint(accentYellow)
                    .labelsHidden()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)

                if notifAuthStatus == .denied {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                        Text("Bildirim izni reddedilmiş.".localized)
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                        Spacer()
                        Button("Ayarlara Git".localized) { openSettings() }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(accentYellow)
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 8)
                }

                Divider().background(accentYellow.opacity(0.2)).padding(.leading, 56)
                toggleRow("E-posta Bildirimleri", icon: "envelope.fill", tint: .blue, value: $emailNotifEnabled)
                Divider().background(accentYellow.opacity(0.2)).padding(.leading, 56)
                toggleRow("SMS Bildirimleri", icon: "message.fill", tint: .green, value: $smsNotifEnabled)

                if pushEnabled && notifAuthStatus == .authorized {
                    Divider().background(accentYellow.opacity(0.2)).padding(.leading, 56)
                    subHeader("Bildirim Türleri")
                    toggleRow("Rezervasyon Güncellemeleri", icon: "calendar.badge.clock", tint: .purple, value: $notifRezervEnabled)
                    Divider().background(accentYellow.opacity(0.2)).padding(.leading, 56)
                    toggleRow("Kampanya ve Tanıtımlar", icon: "tag.fill", tint: .orange, value: $notifPromoEnabled)
                    Divider().background(accentYellow.opacity(0.2)).padding(.leading, 56)
                    toggleRow("Sistem Bildirimleri", icon: "gear", tint: .teal, value: $notifSistemEnabled)
                }
            }
        }
    }

    // MARK: - Language Section
    private var languageSection: some View {
        sectionCard(title: "DİL SEÇİMİ", icon: "globe", iconColor: .teal) {
            VStack(spacing: 10) {
                ForEach(Array(languages.enumerated()), id: \.offset) { idx, lang in
                    let isSelected = selectedLanguage == lang.0
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            selectedLanguage = lang.0
                            LanguageManager.shared.languageCode = lang.0
                        }
                    } label: {
                        HStack(spacing: 14) {
                            iconBox(lang.0 == "tr" ? "flag.fill" : "globe", tint: lang.0 == "tr" ? .red : .blue)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(lang.1)
                                    .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                                    .foregroundColor(primaryColor)
                                
                                Text(lang.0 == "tr" ? "Varsayılan Uygulama Dili" : "Default Application Language")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if isSelected {
                                ZStack {
                                    Circle()
                                        .fill(accentYellow)
                                        .frame(width: 26, height: 26)
                                        .shadow(color: accentYellow.opacity(0.5), radius: 4, x: 0, y: 2)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .transition(.scale.combined(with: .opacity))
                            } else {
                                Circle()
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
                                    .frame(width: 24, height: 24)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            isSelected
                                ? LinearGradient(
                                    colors: [accentYellow.opacity(0.25), accentYellow.opacity(0.12)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [Color.gray.opacity(0.04), Color.gray.opacity(0.02)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(isSelected ? accentYellow : Color.gray.opacity(0.18), lineWidth: isSelected ? 2 : 1)
                        )
                        .shadow(color: isSelected ? accentYellow.opacity(0.25) : .clear, radius: 8, x: 0, y: 4)
                        .scaleEffect(isSelected ? 1.01 : 1.0)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
        }
    }

    // MARK: - Privacy Section
    private var privacySection: some View {
        sectionCard(title: "GİZLİLİK AYARLARI", icon: "lock.shield.fill", iconColor: .cyan) {
            VStack(spacing: 0) {
                toggleRow("Konum Paylaşımı", icon: "location.fill", tint: .cyan, value: $locationShareEnabled)
                Divider().background(accentYellow.opacity(0.2)).padding(.leading, 56)
                toggleRow("Profil Görünürlüğü (Herkese Açık)", icon: "person.2.fill", tint: .pink, value: $profilePublic)
                Divider().background(accentYellow.opacity(0.2)).padding(.leading, 56)
                toggleRow("Veri Toplama Onayı", icon: "chart.bar.fill", tint: .mint, value: $dataCollectionEnabled)
            }
        }
    }

    // MARK: - Auto Save Note
    private var autoSaveNote: some View {
        HStack(spacing: 8) {
            Image(systemName: savedToast ? "checkmark.circle.fill" : "info.circle.fill")
                .foregroundColor(savedToast ? .green : accentYellow)
                .font(.system(size: 14))
            Text(savedToast ? "Tercihler kaydedildi!".localized : "Tüm tercihler otomatik olarak kaydedilir.".localized)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(savedToast ? .green : .secondary)
        }
        .padding(.horizontal, 8)
        .animation(.easeInOut(duration: 0.3), value: savedToast)
    }

    // MARK: - Reusable Helpers

    private func iconBox(_ name: String, tint: Color) -> some View {
        Image(systemName: name)
            .font(.system(size: 14))
            .foregroundColor(tint)
            .frame(width: 32, height: 32)
            .background(tint.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func sectionCard<Content: View>(
        title: String, icon: String, iconColor: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(iconColor)
                Text(title.localized)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)
            }
            .padding(.leading, 4)

            VStack(spacing: 0) { content() }
                .background(Color("CardBackground"))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
        }
    }

    private func toggleRow(
        _ title: String, icon: String, tint: Color, value: Binding<Bool>
    ) -> some View {
        HStack(spacing: 12) {
            iconBox(icon, tint: tint)
            Text(title.localized)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
            Spacer()
            Toggle("", isOn: value)
                .tint(accentYellow)
                .labelsHidden()
                .onChange(of: value.wrappedValue) { _, _ in flashToast() }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func subHeader(_ text: String) -> some View {
        Text(text.localized)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 4)
    }

    // MARK: - Notification Permission
    private func checkNotifAuthStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notifAuthStatus = settings.authorizationStatus
                if settings.authorizationStatus == .denied {
                    self.pushEnabled = false
                }
            }
        }
    }

    private func requestNotifPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized, .provisional:
                    self.pushEnabled = true
                    self.notifAuthStatus = .authorized
                case .denied:
                    self.showNotifDeniedAlert = true
                case .notDetermined:
                    UNUserNotificationCenter.current()
                        .requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                            DispatchQueue.main.async {
                                self.pushEnabled = granted
                                self.notifAuthStatus = granted ? .authorized : .denied
                            }
                        }
                @unknown default: break
                }
            }
        }
    }

    private func applyTheme() {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first else { return }
        let style: UIUserInterfaceStyle
        switch selectedTheme {
        case "light": style = .light
        case "dark":  style = .dark
        default:      style = .unspecified
        }
        UIView.animate(withDuration: 0.3) {
            windowScene.windows.forEach { $0.overrideUserInterfaceStyle = style }
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func flashToast() {
        withAnimation { savedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation { savedToast = false }
        }
    }
}

#Preview {
    NavigationStack {
        PreferencesPage()
    }
}
