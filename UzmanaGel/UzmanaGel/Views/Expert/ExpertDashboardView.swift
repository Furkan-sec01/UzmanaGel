import SwiftUI

struct ExpertDashboardView: View {

    @EnvironmentObject var session: SessionViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BackgroundColor")
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer().frame(height: 20)

                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(Color("TertiaryColor"))

                    VStack(spacing: 8) {
                        Text("Uzman Paneli")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.primary)

                        Text("Başvurunuz inceleniyor")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }

                    VStack(spacing: 12) {
                        statusCard(
                            icon: "clock.badge.checkmark",
                            title: "Başvuru Durumu",
                            subtitle: "İnceleme aşamasında",
                            color: .orange
                        )

                        statusCard(
                            icon: "doc.text",
                            title: "Çalışma Detayları",
                            subtitle: "Onay sonrası doldurulacak",
                            color: Color("PrimaryColor")
                        )

                        statusCard(
                            icon: "creditcard",
                            title: "Banka Bilgileri",
                            subtitle: "Onay sonrası doldurulacak",
                            color: Color("PrimaryColor")
                        )

                        statusCard(
                            icon: "photo.on.rectangle.angled",
                            title: "Portföy",
                            subtitle: "Onay sonrası doldurulacak",
                            color: Color("PrimaryColor")
                        )
                    }
                    .padding(.horizontal, 24)

                    Spacer()

                    Button {
                        session.signOut()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 14))
                            Text("Çıkış Yap")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.red.opacity(0.08))
                        .cornerRadius(14)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 30)
                }
            }
        }
    }

    private func statusCard(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }
}

#Preview {
    ExpertDashboardView()
        .environmentObject(SessionViewModel())
}
