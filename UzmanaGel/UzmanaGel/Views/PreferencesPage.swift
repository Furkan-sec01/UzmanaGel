//
//  PreferencesPage.swift
//  UzmanaGel
//

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

    // MARK: - Privacy
    @AppStorage("pref_location_share")  private var locationShareEnabled: Bool = true
    @AppStorage("pref_profile_public")  private var profilePublic: Bool = true
    @AppStorage("pref_data_collection") private var dataCollectionEnabled: Bool = true

    // MARK: - Runtime States
    @State private var notifAuthStatus: UNAuthorizationStatus = .notDetermined
    @State private var showNotifDeniedAlert = false
    @State private var savedToast = false

    // Renk paleti — AppThemeManager ile senkronize key'ler
    private let accents: [(id: String, color: Color, label: String)] = [
        ("orange", .orange,                                     "Turuncu"),
        ("blue",   .blue,                                       "Mavi"),
        ("green",  Color(red: 0.18, green: 0.72, blue: 0.32),  "Yeşil"),
        ("purple", .purple,                                     "Mor"),
        ("teal",   .teal,                                       "Teal"),
        ("pink",   .pink,                                       "Pembe")
    ]

    private let themes: [(id: String, label: String, icon: String)] = [
        ("system", "Sistem",  "circle.lefthalf.filled"),
        ("light",  "Açık",    "sun.max.fill"),
        ("dark",   "Koyu",    "moon.fill")
    ]

    private let languages = [("tr", "🇹🇷 Türkçe"), ("en", "🇬🇧 English")]

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                notificationSection
                appearanceSection
                languageSection
                privacySection
                autoSaveNote
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(Color("BackgroundColor"))
        .navigationTitle("Tercihler")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkNotifAuthStatus()
            applyTheme()
        }
        .onChange(of: selectedTheme) { _, _ in applyTheme() }
        .alert("Bildirim İzni Gerekli", isPresented: $showNotifDeniedAlert) {
            Button("Ayarlara Git") {
                openSettings()
            }
            Button("Vazgeç", role: .cancel) {
                pushEnabled = false
            }
        } message: {
            Text("Bildirim göndermek için lütfen Ayarlar > UzmanaGel > Bildirimler bölümünden izin verin.")
        }
    }

    // MARK: - Notification Section
    private var notificationSection: some View {
        sectionCard(title: "BİLDİRİM AYARLARI", icon: "bell.badge") {
            VStack(spacing: 0) {
                // Push — sistem izniyle senkronize
                HStack(spacing: 12) {
                    iconBox("bell.fill", tint: Color("PrimaryColor"))
                    Text("Anlık Bildirimler (Push)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color("Text"))
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { pushEnabled && notifAuthStatus == .authorized },
                        set: { newVal in
                            newVal ? requestNotifPermission() : (pushEnabled = false)
                            flashToast()
                        }
                    ))
                    .tint(Color("PrimaryColor"))
                    .labelsHidden()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)

                // İzin reddedilmişse uyarı
                if notifAuthStatus == .denied {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                        Text("Bildirim izni reddedilmiş.")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                        Spacer()
                        Button("Ayarlara Git") { openSettings() }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color("PrimaryColor"))
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 8)
                }

                Divider().padding(.leading, 56)
                toggleRow("E-posta Bildirimleri", icon: "envelope.fill", tint: .blue, value: $emailNotifEnabled)
                Divider().padding(.leading, 56)
                toggleRow("SMS Bildirimleri", icon: "message.fill", tint: .green, value: $smsNotifEnabled)

                if pushEnabled && notifAuthStatus == .authorized {
                    Divider().padding(.leading, 56)
                    subHeader("Bildirim Türleri")
                    toggleRow("Rezervasyon", icon: "calendar.badge.clock", tint: .indigo, value: $notifRezervEnabled)
                    Divider().padding(.leading, 56)
                    toggleRow("Kampanya & Promosyon", icon: "tag.fill", tint: .orange, value: $notifPromoEnabled)
                    Divider().padding(.leading, 56)
                    toggleRow("Sistem Bildirimleri", icon: "gear", tint: .gray, value: $notifSistemEnabled)
                }
            }
        }
    }

    // MARK: - Appearance Section
    private var appearanceSection: some View {
        sectionCard(title: "GÖRÜNÜM AYARLARI", icon: "paintbrush.fill") {
            VStack(spacing: 0) {

                // ── Tema ──
                VStack(alignment: .leading, spacing: 10) {
                    Label("Tema", systemImage: "moon.stars.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.top, 14)

                    HStack(spacing: 8) {
                        ForEach(themes, id: \.id) { theme in
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedTheme = theme.id
                                }
                                flashToast()
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: theme.icon)
                                        .font(.system(size: 22))
                                        .foregroundColor(selectedTheme == theme.id
                                                         ? Color("PrimaryColor") : .secondary)
                                    Text(theme.label)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(selectedTheme == theme.id
                                                         ? Color("PrimaryColor") : .secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    selectedTheme == theme.id
                                    ? Color("PrimaryColor").opacity(0.12)
                                    : Color(.tertiarySystemBackground)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedTheme == theme.id
                                                ? Color("PrimaryColor") : Color.clear, lineWidth: 2)
                                )
                                .scaleEffect(selectedTheme == theme.id ? 1.03 : 1.0)
                                .animation(.spring(response: 0.3), value: selectedTheme)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
                }

                Divider().padding(.horizontal, 16)

                // ── Renk Vurgusu ──
                VStack(alignment: .leading, spacing: 12) {
                    Label("Renk Vurgusu", systemImage: "paintpalette.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.top, 14)

                    HStack(spacing: 18) {
                        ForEach(accents, id: \.id) { accent in
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                                    selectedAccent = accent.id
                                }
                                flashToast()
                            } label: {
                                VStack(spacing: 6) {
                                    ZStack {
                                        Circle()
                                            .fill(accent.color)
                                            .frame(width: 36, height: 36)
                                            .shadow(
                                                color: accent.color.opacity(selectedAccent == accent.id ? 0.6 : 0),
                                                radius: 8
                                            )

                                        if selectedAccent == accent.id {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundColor(.white)
                                                .transition(.scale.combined(with: .opacity))
                                        }
                                    }
                                    .scaleEffect(selectedAccent == accent.id ? 1.18 : 1.0)
                                    .animation(.spring(response: 0.3), value: selectedAccent)

                                    Text(accent.label)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(selectedAccent == accent.id
                                                         ? accent.color : .secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }

                // Canlı önizleme
                accentPreviewRow
            }
        }
    }

    // Renk değişikliğinin anında görüldüğü önizleme şeridi
    private var accentPreviewRow: some View {
        let currentColor = accents.first(where: { $0.id == selectedAccent })?.color ?? .orange

        return VStack(spacing: 0) {
            Divider().padding(.horizontal, 16)

            HStack(spacing: 14) {
                Label("Önizleme", systemImage: "eye.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)

                Spacer()

                // Toggle örneği
                Toggle("", isOn: .constant(true))
                    .tint(currentColor)
                    .labelsHidden()
                    .disabled(true)

                // Buton örneği
                Text("Tamam")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(currentColor)
                    .clipShape(Capsule())

                // Kapsül örneği
                Circle()
                    .fill(currentColor)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.tertiarySystemBackground).opacity(0.6))
            .animation(.easeInOut(duration: 0.25), value: selectedAccent)
        }
    }

    // MARK: - Language Section
    private var languageSection: some View {
        sectionCard(title: "DİL SEÇİMİ", icon: "globe") {
            VStack(spacing: 0) {
                ForEach(Array(languages.enumerated()), id: \.offset) { idx, lang in
                    if idx > 0 { Divider().padding(.leading, 20) }

                    Button {
                        selectedLanguage = lang.0
                        // iOS per-app dil değişikliği için Ayarlar'a yönlendir
                        openAppLanguageSettings()
                    } label: {
                        HStack(spacing: 12) {
                            Text(lang.1)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color("Text"))

                            Spacer()

                            if selectedLanguage == lang.0 {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color("PrimaryColor"))
                                    .font(.system(size: 18))
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(14)
                        .background(selectedLanguage == lang.0
                                    ? Color("PrimaryColor").opacity(0.05) : Color.clear)
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(response: 0.3), value: selectedLanguage)
                }

                Divider().padding(.horizontal, 16)

                // Bilgi notu
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color("PrimaryColor"))
                        .padding(.top, 1)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dil Değiştirme Hakkında")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color("Text"))

                        Text("iOS, dil değişikliğini uygulama ayarlarından yapar. Seçiminize bastığınızda sizi Ayarlar'a yönlendireceğiz. Dil değişikliği sonrası uygulamayı yeniden başlatın.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)

                Button {
                    openAppLanguageSettings()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "gear")
                            .font(.system(size: 13))
                        Text("iOS Ayarlarında Dili Değiştir")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color("PrimaryColor"))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Privacy Section
    private var privacySection: some View {
        sectionCard(title: "GİZLİLİK AYARLARI", icon: "lock.shield.fill") {
            VStack(spacing: 0) {
                toggleRow("Konum Paylaşımı",       icon: "location.fill",  tint: .blue,   value: $locationShareEnabled)
                Divider().padding(.leading, 56)
                toggleRow("Profilim Herkese Açık",  icon: "person.2.fill",  tint: .indigo, value: $profilePublic)
                Divider().padding(.leading, 56)
                toggleRow("Veri Toplama Onayı",     icon: "chart.bar.fill", tint: .purple, value: $dataCollectionEnabled)
            }
        }
    }

    // MARK: - Auto Save Note
    private var autoSaveNote: some View {
        HStack(spacing: 8) {
            Image(systemName: savedToast ? "checkmark.circle.fill" : "info.circle.fill")
                .foregroundColor(savedToast ? .green : .secondary)
                .font(.system(size: 14))
            Text(savedToast ? "Tercihler kaydedildi!" : "Tüm tercihler otomatik olarak kaydedilir.")
                .font(.system(size: 12))
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
            .frame(width: 28, height: 28)
            .background(tint.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 7))
    }

    private func sectionCard<Content: View>(
        title: String, icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(Color("PrimaryColor"))
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            VStack(spacing: 0) { content() }
                .background(Color("CardBackground"))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        }
    }

    private func toggleRow(
        _ title: String, icon: String, tint: Color, value: Binding<Bool>
    ) -> some View {
        HStack(spacing: 12) {
            iconBox(icon, tint: tint)
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color("Text"))
            Spacer()
            Toggle("", isOn: value)
                .tint(Color("PrimaryColor"))
                .labelsHidden()
                .onChange(of: value.wrappedValue) { _, _ in flashToast() }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func subHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, 2)
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

    // MARK: - Theme
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

    // MARK: - Language → iOS Settings
    /// iOS 13+ per-app dil ayarı için Ayarlar sayfasına yönlendirir.
    private func openAppLanguageSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Toast
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
