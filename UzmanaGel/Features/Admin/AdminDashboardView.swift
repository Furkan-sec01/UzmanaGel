import SwiftUI

struct AdminDashboardView: View {

    @EnvironmentObject private var session: SessionViewModel

    private let backgroundColor = Color("BackgroundColor")

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    headerCard

                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.grid.2x2.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color("PrimaryColor"))

                            Text("Yönetim Araçları")
                                .font(.title3.bold())
                                .foregroundStyle(.primary)
                        }
                        .padding(.horizontal, 4)

                        VStack(spacing: 14) {
                            NavigationLink {
                                AdminProviderApplicationsPage()
                            } label: {
                                moduleCard(
                                    title: "Uzman Başvuruları ve Belgeler",
                                    description: "Bekleyen uzman başvurularını ve doğrulama belgelerini incele.",
                                    systemImage: "person.badge.shield.checkmark.fill",
                                    badgeText: "Başvurular",
                                    gradientColors: [Color.blue, Color.cyan]
                                )
                            }
                            .buttonStyle(ModernPressableButtonStyle())

                            NavigationLink {
                                AdminProviderApplicationHistoryPage()
                            } label: {
                                moduleCard(
                                    title: "Uzman Başvuru Geçmişi",
                                    description: "Onay, ret ve eksik belge kararlarını görüntüle.",
                                    systemImage: "person.crop.circle.badge.clock",
                                    badgeText: "Geçmiş",
                                    gradientColors: [Color.indigo, Color.purple]
                                )
                            }
                            .buttonStyle(ModernPressableButtonStyle())

                            NavigationLink {
                                AdminReviewReportsPage()
                            } label: {
                                moduleCard(
                                    title: "Bildirilen Yorumlar",
                                    description: "Kullanıcıların bildirdiği yorumları incele.",
                                    systemImage: "exclamationmark.bubble.fill",
                                    badgeText: "Moderasyon",
                                    gradientColors: [Color.orange, Color.red]
                                )
                            }
                            .buttonStyle(ModernPressableButtonStyle())

                            NavigationLink {
                                AdminModerationHistoryPage()
                            } label: {
                                moduleCard(
                                    title: "Moderasyon Geçmişi",
                                    description: "Tamamlanan yorum moderasyon işlemlerini görüntüle.",
                                    systemImage: "clock.arrow.circlepath",
                                    badgeText: "Arşiv",
                                    gradientColors: [Color.purple, Color.pink]
                                )
                            }
                            .buttonStyle(ModernPressableButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 20)
            }
            .background(backgroundColor.ignoresSafeArea())
            .navigationTitle("Yönetim Paneli")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("PrimaryColor"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        session.signOut()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Çıkış Yap")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                    }
                }
            }
        }
    }

    private var headerCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 58, height: 58)

                Image(systemName: "shield.checkered")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("Admin Hesabı")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)

                    Text("YÖNETİCİ")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(Color("PrimaryColor"))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.white)
                        .clipShape(Capsule())
                }

                Text("Platform yönetimi ve moderasyon paneli")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
            }

            Spacer()
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color("PrimaryColor"), Color("PrimaryColor").opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color("PrimaryColor").opacity(0.25), radius: 12, x: 0, y: 6)
    }

    private func moduleCard(
        title: String,
        description: String,
        systemImage: String,
        badgeText: String,
        gradientColors: [Color]
    ) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                    .shadow(color: gradientColors[0].opacity(0.3), radius: 6, x: 0, y: 3)

                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Text(badgeText)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(gradientColors[0])
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(gradientColors[0].opacity(0.12))
                        .clipShape(Capsule())
                }

                Text(description)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.secondary.opacity(0.6))
        }
        .padding(16)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
}

struct ModernPressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

