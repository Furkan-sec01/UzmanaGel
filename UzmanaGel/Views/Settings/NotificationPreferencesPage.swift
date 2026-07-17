//
//  NotificationPreferencesPage.swift
//  UzmanaGel
//
//  Created by Halil Keremoğlu on 14.07.2026.
//

import SwiftUI
import UserNotifications

struct NotificationPreferencesPage: View {

    @AppStorage("notificationEnabled")
    private var notificationEnabled = true

    @AppStorage("reservationNotificationsEnabled")
    private var reservationNotificationsEnabled = true

    @AppStorage("messageNotificationsEnabled")
    private var messageNotificationsEnabled = true

    @AppStorage("systemNotificationsEnabled")
    private var systemNotificationsEnabled = true

    @AppStorage("marketingNotificationsEnabled")
    private var marketingNotificationsEnabled = false

    @State private var permissionStatusText = "Kontrol ediliyor...".localized
    @State private var showPermissionAlert = false
    
    private let preferencesService = FirestorePreferencesService()

    // Colors
    private let accentYellow = Color("TertiaryColor")
    private let bgColor      = Color("BackgroundColor")
    private let primaryColor = Color("PrimaryColor")

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    mainNotificationCard
                    permissionStatusCard
                    notificationTypesCard
                    infoCard
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Bildirim Tercihleri".localized)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadNotificationPermissionStatus()
            await loadNotificationPreferences()
        }
        .onChange(of: notificationEnabled) { _, newValue in
            if newValue {
                Task {
                    await requestNotificationPermissionIfNeeded()
                    await saveNotificationPreferences()
                }
            } else {
                Task {
                    await saveNotificationPreferences()
                }
            }
        }
        .onChange(of: reservationNotificationsEnabled) { _, _ in
            Task { await saveNotificationPreferences() }
        }
        .onChange(of: messageNotificationsEnabled) { _, _ in
            Task { await saveNotificationPreferences() }
        }
        .onChange(of: systemNotificationsEnabled) { _, _ in
            Task { await saveNotificationPreferences() }
        }
        .onChange(of: marketingNotificationsEnabled) { _, _ in
            Task { await saveNotificationPreferences() }
        }
        .alert("Bildirim İzni Kapalı".localized, isPresented: $showPermissionAlert) {
            Button("Tamam".localized, role: .cancel) {}
        } message: {
            Text("Bildirim izni daha önce kapatılmış. Tekrar açmak için iPhone Ayarları üzerinden UzmanaGel bildirim izinlerini açmanız gerekir.".localized)
        }
    }

    // MARK: - Cards

    private var mainNotificationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                iconBox("bell.fill", tint: .red)
                Text("Tüm Bildirimler".localized)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(primaryColor)
                Spacer()
                Toggle("", isOn: $notificationEnabled)
                    .tint(accentYellow)
                    .labelsHidden()
            }
            .padding(16)

            Divider().background(accentYellow.opacity(0.25))

            Text("Bu seçenek kapalıysa uygulama içindeki tüm bildirim tercihleri pasif kabul edilir.".localized)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
        }
        .background(Color.white.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accentYellow.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: accentYellow.opacity(0.1), radius: 8, x: 0, y: 3)
    }

    private var permissionStatusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "iphone.radiowaves.left.and.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.indigo)
                Text("İZİN DURUMU".localized)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(primaryColor)
            }
            .padding(.leading, 4)

            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    iconBox("lock.shield.fill", tint: .indigo)
                    Text("iOS Bildirim İzni".localized)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(primaryColor)
                    Spacer()
                    Text(permissionStatusText)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(accentYellow)
                }
                .padding(14)

                Divider().background(accentYellow.opacity(0.2))

                Button {
                    Task {
                        await loadNotificationPermissionStatus()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                        Text("İzni Yeniden Kontrol Et".localized)
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(accentYellow)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
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

    private var notificationTypesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.purple)
                Text("BİLDİRİM TÜRLERİ".localized)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(primaryColor)
            }
            .padding(.leading, 4)

            VStack(spacing: 0) {
                toggleRow("Rezervasyon Bildirimleri", icon: "calendar.badge.clock", tint: .purple, value: $reservationNotificationsEnabled)
                    .disabled(!notificationEnabled)
                Divider().background(accentYellow.opacity(0.2)).padding(.leading, 56)
                toggleRow("Mesaj Bildirimleri", icon: "message.fill", tint: .green, value: $messageNotificationsEnabled)
                    .disabled(!notificationEnabled)
                Divider().background(accentYellow.opacity(0.2)).padding(.leading, 56)
                toggleRow("Sistem Bildirimleri", icon: "exclamationmark.shield.fill", tint: .teal, value: $systemNotificationsEnabled)
                    .disabled(!notificationEnabled)
                Divider().background(accentYellow.opacity(0.2)).padding(.leading, 56)
                toggleRow("Kampanya Bildirimleri", icon: "megaphone.fill", tint: .orange, value: $marketingNotificationsEnabled)
                    .disabled(!notificationEnabled)
            }
            .background(Color.white.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(accentYellow.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: accentYellow.opacity(0.1), radius: 8, x: 0, y: 3)
            .opacity(notificationEnabled ? 1.0 : 0.6)
        }
    }

    private var infoCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(accentYellow)
                .font(.system(size: 18))
            Text("Bu tercihler şu an cihazda saklanır. Push notification sistemi eklendiğinde Firebase bildirim akışıyla birlikte kullanılabilir.".localized)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(14)
        .background(Color.white.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accentYellow.opacity(0.2), lineWidth: 1)
        )
    }

    private func iconBox(_ name: String, tint: Color) -> some View {
        Image(systemName: name)
            .font(.system(size: 14))
            .foregroundColor(tint)
            .frame(width: 32, height: 32)
            .background(tint.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
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

    private func loadNotificationPermissionStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()

        await MainActor.run {
            permissionStatusText = permissionText(for: settings.authorizationStatus)

            if settings.authorizationStatus == .denied {
                notificationEnabled = false
            }
        }
    }

    private func requestNotificationPermissionIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .notDetermined:
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])

                await MainActor.run {
                    notificationEnabled = granted
                    permissionStatusText = granted ? "İzin verildi".localized : "İzin verilmedi".localized
                }
            } catch {
                await MainActor.run {
                    notificationEnabled = false
                    permissionStatusText = "İzin alınamadı".localized
                }
            }

        case .denied:
            await MainActor.run {
                notificationEnabled = false
                permissionStatusText = "İzin kapalı".localized
                showPermissionAlert = true
            }

        case .authorized, .provisional, .ephemeral:
            await MainActor.run {
                permissionStatusText = permissionText(for: settings.authorizationStatus)
            }

        @unknown default:
            await MainActor.run {
                permissionStatusText = "Bilinmiyor"
            }
        }
    }

    private func permissionText(for status: UNAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            return "Sorulmadı".localized
        case .denied:
            return "İzin kapalı".localized
        case .authorized:
            return "İzin verildi".localized
        case .provisional:
            return "Geçici izin".localized
        case .ephemeral:
            return "Geçici izin".localized
        @unknown default:
            return "Bilinmiyor".localized
        }
    }
    
    private func loadNotificationPreferences() async {
        if let settings = try? await preferencesService.fetchNotificationSettings() {
            await MainActor.run {
                notificationEnabled = settings.pushNotificationsEnabled
                systemNotificationsEnabled = settings.emailNotificationsEnabled
                messageNotificationsEnabled = settings.smsNotificationsEnabled
                reservationNotificationsEnabled = settings.bookingNotificationsEnabled
                marketingNotificationsEnabled = settings.promoNotificationsEnabled
            }
        }
    }
    
    private func saveNotificationPreferences() async {
        let settings = NotificationSettings(
            pushNotificationsEnabled: notificationEnabled,
            emailNotificationsEnabled: systemNotificationsEnabled,
            smsNotificationsEnabled: messageNotificationsEnabled,
            bookingNotificationsEnabled: reservationNotificationsEnabled,
            promoNotificationsEnabled: marketingNotificationsEnabled
        )
        try? await preferencesService.saveNotificationSettings(settings)
    }
}

#Preview {
    NavigationStack {
        NotificationPreferencesPage()
    }
}
