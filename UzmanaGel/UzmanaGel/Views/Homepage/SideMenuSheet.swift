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

    let onSignOut: () -> Void
    let onProfileTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {

            // Header
            VStack(alignment: .leading, spacing: 8) {

                // Foto (varsa)
                if let urlString = vm.user?.photoURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFill()
                        default:
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFill()
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 52))
                        .foregroundColor(.white.opacity(0.9))
                }

                Text(vm.user?.displayName ?? "Kullanıcı")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Text(vm.user?.email ?? "—")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.85))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(Color("PrimaryColor"))

            // Items
            VStack(spacing: 14) {
                menuRow("Ana Sayfa", "house")
                Button {
                    onProfileTap()
                } label: {
                    menuRowContent("Profilim", "person")
                }
                .buttonStyle(.plain)

                menuRow("Mesajlar", "message")
                menuRow("Ayarlar", "gearshape")

                Divider().padding(.vertical, 6)

                Button {
                    onSignOut()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "power")
                        Text("Çıkış Yap")
                        Spacer()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.red)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 16)

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
    private func menuRowContent(_ title: String, _ icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundColor(.secondary)
            Text(title).foregroundColor(.primary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
