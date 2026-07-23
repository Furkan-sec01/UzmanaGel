//
//  SideMenuSheet.swift
//  UzmanaGel
//
//  Created by Halil Keremoğlu on 9.07.2026.
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
        ZStack {
            // Frosted / Clean surface background exactly like reference
            Color("BackgroundColor")
                .opacity(0.92)
                .background(Material.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 1. Full-Width Dark Navy Profile Banner
                topProfileBanner

                // 2. Clean Unboxed Navigation List
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 6) {
                        cleanNavRow(
                            title: "Ana Sayfa".localized,
                            icon: "house",
                            action: onHomeTap
                        )

                        cleanNavRow(
                            title: "Profilim".localized,
                            icon: "person",
                            action: onProfileTap
                        )

                        cleanNavRow(
                            title: "Mesajlar".localized,
                            icon: "bubble.left.and.text.bubble.right",
                            action: onMessagesTap
                        )

                        cleanNavRow(
                            title: "Rezervasyonlarım".localized,
                            icon: "calendar.badge.clock",
                            action: onReservationsTap
                        )

                        cleanNavRow(
                            title: "Ayarlar".localized,
                            icon: "gearshape",
                            action: onSettingsTap
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    Spacer(minLength: 28)

                    // 3. Clean Unboxed Log Out Row
                    Button {
                        onSignOut()
                    } label: {
                        HStack(spacing: 18) {
                            Image(systemName: "power")
                                .font(.system(size: 20, weight: .regular))
                                .foregroundColor(.red)
                                .frame(width: 26, alignment: .center)

                            Text("Çıkış Yap".localized)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.red)

                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(CleanRowButtonStyle())
                    .padding(.bottom, 24)
                }
            }
        }
        .onAppear {
            vm.load(uid: session.userId)
        }
    }

    // MARK: - Full-Width VIP Luxury Top Banner (Exact Reference Style & 142pt Height)
    private var topProfileBanner: some View {
        Button {
            onProfileTap()
        } label: {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    // Top: Avatar with VIP Gold Shield
                    ZStack(alignment: .bottomTrailing) {
                        if let urlString = vm.user?.photoURL,
                           let url = URL(string: urlString) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let img):
                                    img
                                        .resizable()
                                        .scaledToFill()
                                default:
                                    defaultAvatar
                                }
                            }
                            .frame(width: 68, height: 68)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
                            )
                            .shadow(color: Color.black.opacity(0.25), radius: 5, x: 0, y: 2)
                        } else {
                            defaultAvatar
                        }
                        
                        // Golden VIP Verification Badge
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.yellow)
                            .background(
                                Circle()
                                    .fill(Color("PrimaryColor"))
                                    .frame(width: 18, height: 18)
                            )
                            .offset(x: 3, y: 3)
                            .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                    }

                    // Bottom: User Name & Email
                    VStack(alignment: .leading, spacing: 3) {
                        Text(vm.user?.displayName ?? "Kullanıcı".localized)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                            .lineLimit(1)

                        Text(vm.user?.email ?? "—")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white.opacity(0.85))
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 8)

                // Right side: Sleek Frosted Glass Profile Navigation Icon (Petite 28x28)
                Circle()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.35), lineWidth: 0.8)
                    )
                    .shadow(color: Color.black.opacity(0.12), radius: 2, x: 0, y: 1)
            }
            .padding(.horizontal, 22)
            .padding(.top, 16)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 142)
            .background(
                ZStack {
                    LinearGradient(
                        colors: [
                            Color("PrimaryColor"),
                            Color("PrimaryColor").opacity(0.9),
                            Color("PrimaryColor").opacity(0.78)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    GeometryReader { geo in
                        Circle()
                            .fill(Color.white.opacity(0.07))
                            .frame(width: geo.size.width * 0.6, height: geo.size.width * 0.6)
                            .offset(x: geo.size.width * 0.55, y: -geo.size.width * 0.2)
                        
                        Circle()
                            .fill(Color.white.opacity(0.04))
                            .frame(width: geo.size.width * 0.4, height: geo.size.width * 0.4)
                            .offset(x: -geo.size.width * 0.1, y: geo.size.height * 0.5)
                    }
                    .clipped()
                }
            )
            .overlay(
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, Color.white.opacity(0.25), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)
                }
            )
        }
        .buttonStyle(.plain)
    }

    private var defaultAvatar: some View {
        Circle()
            .fill(Color.white.opacity(0.15))
            .frame(width: 68, height: 68)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white.opacity(0.9))
            )
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
            )
    }

    // MARK: - Clean Unboxed Navigation Row (Exact Reference Style)
    private func cleanNavRow(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            HStack(spacing: 18) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(.primary)
                    .frame(width: 26, alignment: .center)

                Text(title)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(CleanRowButtonStyle())
    }
}

// MARK: - Tactile Clean Button Style
struct CleanRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
