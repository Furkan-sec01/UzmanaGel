//
//  PreferencesView.swift
//  UzmanaGel
//

import SwiftUI

struct PreferencesView: View {
    @StateObject private var viewModel = PreferencesViewModel()
    @ObservedObject private var langManager = LanguageManager.shared

    private let accentYellow = Color("TertiaryColor")
    private let bgColor      = Color("BackgroundColor")
    private let primaryColor = Color("PrimaryColor")

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            if viewModel.isLoading {
                LoadingView(message: "Tercihleriniz yükleniyor...".localized)
            } else {
                ScrollView {
                    VStack(spacing: 22) {
                        notificationSection
                        appearanceSection
                        languageSection
                        privacySection
                        saveButtonSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
            }

            if let success = viewModel.successMessage {
                toastOverlay(message: success.localized)
            }
        }
        .navigationTitle("Tercihler".localized)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadPreferences()
        }
    }

    // MARK: - 1. Notification Settings Section
    private var notificationSection: some View {
        sectionCard(title: "Bildirim Ayarları", icon: "bell.badge.fill", iconColor: .red) {
            VStack(spacing: 0) {
                toggleRow("Anlık Bildirimler (Push)", icon: "bell.fill", tint: .red, value: $viewModel.pushNotificationsEnabled)
                Divider().background(accentYellow.opacity(0.2)).padding(.leading, 56)
                toggleRow("E-posta Bildirimleri", icon: "envelope.fill", tint: .blue, value: $viewModel.emailNotificationsEnabled)
                Divider().background(accentYellow.opacity(0.2)).padding(.leading, 56)
                toggleRow("SMS Bildirimleri", icon: "message.fill", tint: .green, value: $viewModel.smsNotificationsEnabled)
                Divider().background(accentYellow.opacity(0.2)).padding(.leading, 56)
                toggleRow("Rezervasyon Güncellemeleri", icon: "calendar.badge.clock", tint: .purple, value: $viewModel.bookingNotificationsEnabled)
                Divider().background(accentYellow.opacity(0.2)).padding(.leading, 56)
                toggleRow("Kampanya ve Tanıtımlar", icon: "tag.fill", tint: .orange, value: $viewModel.promoNotificationsEnabled)
            }
        }
    }

    // MARK: - 2. Appearance Section
    private var appearanceSection: some View {
        sectionCard(title: "Görünüm Ayarları", icon: "paintbrush.fill", iconColor: .indigo) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    iconBox("moon.stars.fill", tint: .indigo)
                    Text("Uygulama Teması".localized)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(primaryColor)
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)

                HStack(spacing: 10) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        let isSelected = viewModel.themeSelection == theme
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.themeSelection = theme
                            }
                            viewModel.applyTheme(theme)
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: themeIcon(for: theme))
                                    .font(.system(size: 20, weight: isSelected ? .bold : .regular))
                                    .foregroundColor(isSelected ? .white : primaryColor)
                                Text(theme.rawValue.localized)
                                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                    .foregroundColor(isSelected ? .white : primaryColor)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                isSelected
                                    ? accentYellow
                                    : Color.gray.opacity(0.08)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: isSelected ? accentYellow.opacity(0.35) : .clear, radius: 6, x: 0, y: 3)
                            .scaleEffect(isSelected ? 1.03 : 1.0)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
        }
    }

    // MARK: - 3. Language Section
    private var languageSection: some View {
        sectionCard(title: "Dil Ayarları", icon: "globe", iconColor: .teal) {
            VStack(spacing: 10) {
                ForEach(Array(Language.allCases.enumerated()), id: \.element) { idx, lang in
                    let isSelected = viewModel.selectedLanguage == lang
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            viewModel.selectedLanguage = lang
                            viewModel.triggerLanguageAlert()
                        }
                    } label: {
                        HStack(spacing: 14) {
                            iconBox(langIcon(for: lang), tint: langTint(for: lang))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(lang.displayName)
                                    .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                                    .foregroundColor(primaryColor)
                                
                                Text(lang == .turkish ? "Varsayılan Uygulama Dili" : "Default Application Language")
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

    // MARK: - 4. Privacy Settings Section
    private var privacySection: some View {
        sectionCard(title: "Gizlilik Ayarları", icon: "lock.shield.fill", iconColor: .cyan) {
            VStack(spacing: 0) {
                toggleRow("Konum Paylaşımı", icon: "location.fill", tint: .cyan, value: $viewModel.locationSharingEnabled)
                Divider().background(accentYellow.opacity(0.2)).padding(.leading, 56)
                toggleRow("Profil Görünürlüğü (Herkese Açık)", icon: "person.2.fill", tint: .pink, value: $viewModel.profileVisibilityPublic)
                Divider().background(accentYellow.opacity(0.2)).padding(.leading, 56)
                toggleRow("Kullanım Verisi Analiz İzni", icon: "chart.bar.fill", tint: .mint, value: $viewModel.dataCollectionConsent)
            }
        }
    }

    // MARK: - Save Button Section
    private var saveButtonSection: some View {
        Button {
            Task {
                await viewModel.savePreferences()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                Text("Ayarları Kaydet".localized)
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                LinearGradient(
                    colors: [accentYellow, accentYellow.opacity(0.85)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: accentYellow.opacity(0.4), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
    }

    // MARK: - Toast Overlay
    @ViewBuilder
    private func toastOverlay(message: String) -> some View {
        VStack {
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(accentYellow)
                Text(message)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(primaryColor)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.white)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(accentYellow, lineWidth: 2)
            )
            .shadow(color: accentYellow.opacity(0.25), radius: 10, x: 0, y: 5)
            .padding(.bottom, 32)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        viewModel.successMessage = nil
                    }
                }
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.successMessage)
    }

    // MARK: - Reusable UI Helpers

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
                    .foregroundColor(primaryColor)
            }
            .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(Color.white.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(accentYellow.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: accentYellow.opacity(0.1), radius: 8, x: 0, y: 3)
        }
    }

    private func toggleRow(_ title: String, icon: String, tint: Color, value: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            iconBox(icon, tint: tint)
            Text(title.localized)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(primaryColor)
            Spacer()
            Toggle("", isOn: value)
                .tint(accentYellow)
                .labelsHidden()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func themeIcon(for theme: AppTheme) -> String {
        switch theme {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }

    private func langIcon(for lang: Language) -> String {
        switch lang {
        case .turkish: return "flag.fill"
        case .english: return "globe"
        }
    }

    private func langTint(for lang: Language) -> Color {
        switch lang {
        case .turkish: return .red
        case .english: return .blue
        }
    }
}

#Preview {
    NavigationStack {
        PreferencesView()
    }
}
