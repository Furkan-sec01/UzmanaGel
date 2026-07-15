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

    @State private var permissionStatusText = "Kontrol ediliyor..."
    @State private var showPermissionAlert = false

    var body: some View {
        List {
            Section {
                Toggle(isOn: $notificationEnabled) {
                    Label("Tüm Bildirimler", systemImage: "bell.fill")
                }
            } footer: {
                Text("Bu seçenek kapalıysa uygulama içindeki tüm bildirim tercihleri pasif kabul edilir.")
            }

            Section("İzin Durumu") {
                HStack {
                    Label("iOS Bildirim İzni", systemImage: "iphone.radiowaves.left.and.right")

                    Spacer()

                    Text(permissionStatusText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Button {
                    Task {
                        await loadNotificationPermissionStatus()
                    }
                } label: {
                    Label("İzni Yeniden Kontrol Et", systemImage: "arrow.clockwise")
                }
            }

            Section("Bildirim Türleri") {
                Toggle(isOn: $reservationNotificationsEnabled) {
                    Label("Rezervasyon Bildirimleri", systemImage: "calendar.badge.clock")
                }
                .disabled(!notificationEnabled)

                Toggle(isOn: $messageNotificationsEnabled) {
                    Label("Mesaj Bildirimleri", systemImage: "message.fill")
                }
                .disabled(!notificationEnabled)

                Toggle(isOn: $systemNotificationsEnabled) {
                    Label("Sistem Bildirimleri", systemImage: "exclamationmark.shield.fill")
                }
                .disabled(!notificationEnabled)

                Toggle(isOn: $marketingNotificationsEnabled) {
                    Label("Kampanya Bildirimleri", systemImage: "megaphone.fill")
                }
                .disabled(!notificationEnabled)
            }

            Section("Bilgi") {
                Text("Bu tercihler şu an cihazda saklanır. Push notification sistemi eklendiğinde Firebase bildirim akışıyla birlikte kullanılabilir.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Bildirim Tercihleri")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadNotificationPermissionStatus()
        }
        .onChange(of: notificationEnabled) { _, newValue in
            guard newValue else { return }

            Task {
                await requestNotificationPermissionIfNeeded()
            }
        }
        .alert("Bildirim İzni Kapalı", isPresented: $showPermissionAlert) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text("Bildirim izni daha önce kapatılmış. Tekrar açmak için iPhone Ayarları üzerinden UzmanaGel bildirim izinlerini açmanız gerekir.")
        }
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
                    permissionStatusText = granted ? "İzin verildi" : "İzin verilmedi"
                }
            } catch {
                await MainActor.run {
                    notificationEnabled = false
                    permissionStatusText = "İzin alınamadı"
                }
            }

        case .denied:
            await MainActor.run {
                notificationEnabled = false
                permissionStatusText = "İzin kapalı"
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
            return "Sorulmadı"
        case .denied:
            return "İzin kapalı"
        case .authorized:
            return "İzin verildi"
        case .provisional:
            return "Geçici izin"
        case .ephemeral:
            return "Geçici izin"
        @unknown default:
            return "Bilinmiyor"
        }
    }
}

#Preview {
    NavigationStack {
        NotificationPreferencesPage()
    }
}
