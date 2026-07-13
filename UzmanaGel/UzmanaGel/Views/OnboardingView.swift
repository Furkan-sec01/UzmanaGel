//
//  OnboardingView.swift
//  UzmanaGel
//
//  Created by Abdullah B on 03.02.2026.
//

import SwiftUI

struct OnboardingView: View {

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var page = 0

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 16) {

                Spacer().frame(height: 20)

                // Üst bar: Atla
                HStack {
                    Spacer()
                    Button {
                        hasSeenOnboarding = true
                    } label: {
                        Text("Atla")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color("TertiaryColor"))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)

                // Sayfalar
                TabView(selection: $page) {

                    // 1. sayfa
                    VStack(spacing: 14) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.blue)
                            .padding(.top, 20)

                        Text("Uzmana Gel’e Hoşgeldin")
                            .font(.system(size: 22, weight: .bold))
                            .multilineTextAlignment(.center)

                        Text("İhtiyacın olan hizmeti seç, güvenilir uzmanlarla hızlıca eşleş.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .tag(0)

                    // 2. sayfa
                    VStack(spacing: 14) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 64))
                            .foregroundColor(.orange)
                            .padding(.top, 20)

                        Text("Talep Oluştur, Teklifleri Gör")
                            .font(.system(size: 22, weight: .bold))
                            .multilineTextAlignment(.center)

                        Text("Kısa bir açıklama yaz, teklifleri karşılaştır ve en uygununu seç.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .tag(1)

                    // 3. sayfa
                    VStack(spacing: 14) {
                        Image(systemName: "message.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.green)
                            .padding(.top, 20)

                        Text("Kolay İletişim")
                            .font(.system(size: 22, weight: .bold))
                            .multilineTextAlignment(.center)

                        Text("Uzmanla mesajlaş, süreci takip et ve iş bitince değerlendirme yap.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(.easeInOut, value: page)

                Spacer()

                // Alt buton: İleri / Başla
                Button {
                    if page < 2 {
                        page += 1
                    } else {
                        hasSeenOnboarding = true
                    }
                } label: {
                    Text(page < 2 ? "İLERİ" : "BAŞLA")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color(.systemYellow))
                        .cornerRadius(14)
                        .shadow(radius: 6, y: 3)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
}
