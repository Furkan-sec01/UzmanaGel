import SwiftUI

struct AdminDashboardView: View {

    @EnvironmentObject private var session: SessionViewModel

    private let backgroundColor = Color("BackgroundColor")
    private let cardColor = Color("CardBackground")

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerCard

                    Text("Yönetim Araçları")
                        .font(.title3.bold())

                    NavigationLink {
                        AdminReviewReportsPage()
                    } label: {
                        moduleCard(
                            title: "Bildirilen Yorumlar",
                            description: "Kullanıcıların bildirdiği yorumları incele.",
                            systemImage: "exclamationmark.bubble.fill",
                            iconColor: .orange
                        )
                    }
                    .buttonStyle(.plain)

                    futureModulesSection
                }
                .padding(16)
            }
            .background(backgroundColor.ignoresSafeArea())
            .navigationTitle("Yönetim Paneli")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        session.signOut()
                    } label: {
                        Label(
                            "Çıkış Yap",
                            systemImage: "rectangle.portrait.and.arrow.right"
                        )
                    }
                }
            }
        }
    }

    private var headerCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.blue)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 16,
                        style: .continuous
                    )
                )

            VStack(alignment: .leading, spacing: 5) {
                Text("Admin Hesabı")
                    .font(.headline)

                Text(
                    "Platform yönetimi ve moderasyon işlemleri"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(cardColor)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
            .stroke(Color.primary.opacity(0.08))
        }
    }

    private func moduleCard(
        title: String,
        description: String,
        systemImage: String,
        iconColor: Color
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 48, height: 48)
                .background(iconColor.opacity(0.14))
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 14,
                        style: .continuous
                    )
                )

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(cardColor)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
            .stroke(Color.primary.opacity(0.08))
        }
    }

    private var futureModulesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sonraki Yönetim Modülleri")
                .font(.title3.bold())

            futureModuleRow(
                title: "Uzman Başvuruları",
                systemImage: "person.badge.clock"
            )

            futureModuleRow(
                title: "Doğrulama Belgeleri",
                systemImage: "doc.text.magnifyingglass"
            )

            futureModuleRow(
                title: "İlan Moderasyonu",
                systemImage: "rectangle.stack.badge.person.crop"
            )

            futureModuleRow(
                title: "Kullanıcı Yönetimi",
                systemImage: "person.2.fill"
            )
        }
    }

    private func futureModuleRow(
        title: String,
        systemImage: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .frame(width: 32)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.subheadline.weight(.medium))

            Spacer()

            Text("Yakında")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(cardColor.opacity(0.7))
        .clipShape(
            RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
            )
        )
    }
}
