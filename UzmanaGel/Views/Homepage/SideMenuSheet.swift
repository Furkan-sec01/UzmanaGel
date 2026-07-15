//
//  SideMenuSheet.swift
//  UzmanaGel
//
//  Created by Abdullah B on 5.02.2026.
//

import SwiftUI

struct SideMenuSheet: View {

    @EnvironmentObject var session: SessionViewModel
    @StateObject private var vm = SideMenuViewModel()
    @ObservedObject private var langManager = LanguageManager.shared

    let onSignOut: () -> Void
    let onMessagesTap: () -> Void
    let onSettingsTap: () -> Void
    let onProfileTap: () -> Void
    let onHomeTap: () -> Void
    let onReservationsTap: () -> Void
    var body: some View {
        VStack(spacing: 0) {

            // Keep content away from sheet corners
                    Color("PrimaryColor")
                        .frame(height: 28)

            // Header
            VStack(alignment: .leading, spacing: 8) {

                        if let urlString = vm.user?.photoURL,
                           let url = URL(string: urlString) {

                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let img):
                                    img
                                        .resizable()
                                        .scaledToFit()

                                default:
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(.white.opacity(0.9))
                                }
                            }
                            .frame(width: 56, height: 56)
                            .clipShape(Circle())

                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 56, height: 56)
                                .foregroundColor(.white.opacity(0.9))
                        }

                        Text(vm.user?.displayName ?? "Kullanıcı".localized)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)

                        Text(vm.user?.email ?? "—")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .background(Color("PrimaryColor"))

            
            // Items
            VStack(spacing: 14) {
                Button {
                    onHomeTap()
                } label: {
                    menuRowContent("Ana Sayfa".localized, "house")
                }
                .buttonStyle(.plain)
                
                Button {
                    onProfileTap()
                } label: {
                    menuRowContent("Profilim".localized, "person")
                }
                .buttonStyle(.plain)

                Button {
                    onMessagesTap()
                } label: {
                    menuRowContent("Mesajlar".localized, "message")
                }
                .buttonStyle(.plain)
                
                Button {
                        onReservationsTap()
                } label: {
                    menuRowContent("Rezervasyonlarım", "calendar.badge.clock")
                }
                    .buttonStyle(.plain)

                Button {
                    onSettingsTap()
                } label: {
                    menuRowContent("Ayarlar".localized, "gearshape")
                }
                .buttonStyle(.plain)

                Divider().padding(.vertical, 6)

                Button {
                    onSignOut()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "power")
                        Text("Çıkış Yap".localized)
                        Spacer()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.red)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .onAppear {
            vm.load(uid: session.userId)
        }
    }

    @ViewBuilder
    private func menuRow(_ title: String, _ icon: String) -> some View {
        Button { } label: {
            menuRowContent(title, icon)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func menuRowContent(
        _ title: String,
        _ icon: String
    ) -> some View {

        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 21))
                .frame(width: 26)

            Text(title)

            Spacer()
        }
        .padding(.horizontal, 20)
        .frame(
            maxWidth: .infinity,
            minHeight: 52,
            alignment: .leading
        )
        .contentShape(Rectangle())
    }
}
