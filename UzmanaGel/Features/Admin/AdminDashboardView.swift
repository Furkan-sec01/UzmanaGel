import SwiftUI

struct AdminDashboardView: View {

    @EnvironmentObject private var session: SessionViewModel
    @ObservedObject private var langManager = LanguageManager.shared

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

                            Text(langManager.translate("Yönetim Araçları"))
                                .font(.title3.bold())
                                .foregroundStyle(.primary)
                        }
                        .padding(.horizontal, 4)

                        VStack(spacing: 14) {
                            NavigationLink {
                                AdminProviderApplicationsPage()
                            } label: {
                                moduleCard(
                                    title: langManager.translate("Uzman Başvuruları ve Belgeler"),
                                    description: langManager.translate("Bekleyen uzman başvurularını ve doğrulama belgelerini incele."),
                                    systemImage: "person.badge.shield.checkmark.fill",
                                    badgeText: langManager.translate("Başvurular"),
                                    gradientColors: [Color.blue, Color.cyan]
                                )
                            }
                            .buttonStyle(ModernPressableButtonStyle())

                            NavigationLink {
                                AdminProviderApplicationHistoryPage()
                            } label: {
                                moduleCard(
                                    title: langManager.translate("Uzman Başvuru Geçmişi"),
                                    description: langManager.translate("Onay, ret ve eksik belge kararlarını görüntüle."),
                                    systemImage: "person.crop.circle.badge.clock",
                                    badgeText: langManager.translate("Geçmiş"),
                                    gradientColors: [Color.indigo, Color.purple]
                                )
                            }
                            .buttonStyle(ModernPressableButtonStyle())

                            NavigationLink {
                                AdminReviewReportsPage()
                            } label: {
                                moduleCard(
                                    title: langManager.translate("Bildirilen Yorumlar"),
                                    description: langManager.translate("Kullanıcıların bildirdiği yorumları incele."),
                                    systemImage: "exclamationmark.bubble.fill",
                                    badgeText: langManager.translate("Moderasyon"),
                                    gradientColors: [Color.orange, Color.red]
                                )
                            }
                            .buttonStyle(ModernPressableButtonStyle())

                            NavigationLink {
                                AdminModerationHistoryPage()
                            } label: {
                                moduleCard(
                                    title: langManager.translate("Moderasyon Geçmişi"),
                                    description: langManager.translate("Tamamlanan yorum moderasyon işlemlerini görüntüle."),
                                    systemImage: "clock.arrow.circlepath",
                                    badgeText: langManager.translate("Arşiv"),
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("PrimaryColor"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        langManager.languageCode = langManager.languageCode == "tr" ? "en" : "tr"
                    } label: {
                        Text(langManager.languageCode == "tr" ? "TR" : "EN")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color("PrimaryColor"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                ToolbarItem(placement: .principal) {
                    Text(langManager.translate("Yönetim Paneli"))
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .transaction { $0.animation = nil }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        session.signOut()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 12, weight: .bold))
                            Text(langManager.translate("Çıkış Yap"))
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(Color("PrimaryColor"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
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
                    Text(langManager.translate("Admin Hesabı"))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)

                    Text(langManager.translate("YÖNETİCİ"))
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(Color("PrimaryColor"))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.white)
                        .clipShape(Capsule())
                }

                Text(langManager.translate("Platform yönetimi ve moderasyon paneli"))
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

