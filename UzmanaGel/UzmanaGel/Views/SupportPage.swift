//
//  SupportPage.swift
//  UzmanaGel
//

import SwiftUI
import StoreKit

struct SupportPage: View {

    @State private var expandedFAQ: String? = nil
    @State private var reportText: String = ""
    @State private var showReportSheet = false
    @State private var showReportSent = false

    private let faqs: [(id: String, q: String, a: String)] = [
        ("f1",
         "Siparişimi nasıl iptal edebilirim?",
         "Sipariş detay ekranına giderek 'Siparişi İptal Et' seçeneğine tıklayabilirsiniz. İptal işlemi hizmet başlamadan önce gerçekleştirilmelidir."),
        ("f2",
         "Ödeme iadesi ne kadar sürer?",
         "İptal edilen siparişlerin iadesi 3-7 iş günü içinde kredi kartınıza yansır. Banka işlem sürelerine göre bu süre değişebilir."),
        ("f3",
         "Uzman profil değerlendirmesi nasıl yapılır?",
         "Tamamlanan hizmetlerden sonra sipariş geçmişinizden 'Değerlendir' butonuna tıklayarak yıldız puanı ve yorum bırakabilirsiniz."),
        ("f4",
         "Şifremi unuttum, ne yapmalıyım?",
         "Giriş ekranındaki 'Şifremi Unuttum' bağlantısına tıklayarak e-posta adresinize sıfırlama linki gönderebilirsiniz."),
        ("f5",
         "Fatura bilgilerimi nasıl güncellerim?",
         "Profil > Hesap Ayarları > Kullanıcı Bilgileri ekranından fatura adresinizi ve bilgilerinizi güncelleyebilirsiniz."),
        ("f6",
         "Uygulamaya nasıl üye olurum?",
         "Ana ekranda 'Kayıt Ol' butonuna tıklayarak e-posta veya telefon numaranızla hızlıca üye olabilirsiniz."),
    ]

    private let appVersion: String = {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }()

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                faqSection
                contactSection
                appInfoSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(Color("BackgroundColor"))
        .navigationTitle("Destek")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showReportSheet) {
            reportSheet
        }
        .overlay(alignment: .top) {
            if showReportSent {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    Text("Raporunuz iletildi, teşekkürler!")
                        .font(.system(size: 13, weight: .semibold))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(Color("CardBackground"))
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.12), radius: 10)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - FAQ Section
    private var faqSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 11))
                    .foregroundColor(Color("PrimaryColor"))
                Text("SIK SORULAN SORULAR")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 0) {
                ForEach(Array(faqs.enumerated()), id: \.element.id) { idx, faq in
                    if idx > 0 { Divider().padding(.leading, 14) }
                    faqRow(faq)
                }
            }
            .background(Color("CardBackground"))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        }
    }

    private func faqRow(_ faq: (id: String, q: String, a: String)) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.35)) {
                    expandedFAQ = expandedFAQ == faq.id ? nil : faq.id
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color("PrimaryColor"))
                        .rotationEffect(.degrees(expandedFAQ == faq.id ? 90 : 0))
                        .animation(.spring(response: 0.35), value: expandedFAQ)

                    Text(faq.q)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color("Text"))
                        .multilineTextAlignment(.leading)

                    Spacer()
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            if expandedFAQ == faq.id {
                Text(faq.a)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Contact Section
    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "headphones")
                    .font(.system(size: 11))
                    .foregroundColor(Color("PrimaryColor"))
                Text("YARDIM & İLETİŞİM")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 0) {
                // Live chat
                contactRow(
                    icon: "message.fill",
                    tint: Color("PrimaryColor"),
                    title: "Canlı Destek",
                    subtitle: "Ortalama yanıt: 2 dakika"
                ) {
                    // Open chat
                }

                Divider().padding(.leading, 56)

                // Report bug
                contactRow(
                    icon: "exclamationmark.bubble.fill",
                    tint: .orange,
                    title: "Hata Bildir",
                    subtitle: "Teknik sorunları bildirin"
                ) {
                    showReportSheet = true
                }

                Divider().padding(.leading, 56)

                // Rate app
                contactRow(
                    icon: "star.fill",
                    tint: .yellow,
                    title: "Uygulamayı Değerlendir",
                    subtitle: "App Store'da puan verin"
                ) {
                    if let scene = UIApplication.shared.connectedScenes
                        .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                        SKStoreReviewController.requestReview(in: scene)
                    }
                }

                Divider().padding(.leading, 56)

                // Privacy
                contactRow(
                    icon: "doc.text.fill",
                    tint: .indigo,
                    title: "Gizlilik Politikası",
                    subtitle: "KVKK ve kullanım şartları"
                ) {
                    if let url = URL(string: "https://uzmanagel.com/privacy") {
                        UIApplication.shared.open(url)
                    }
                }
            }
            .background(Color("CardBackground"))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        }
    }

    private func contactRow(icon: String, tint: Color, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(tint)
                    .frame(width: 32, height: 32)
                    .background(tint.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color("Text"))
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(14)
        }
        .buttonStyle(.plain)
    }

    // MARK: - App Info
    private var appInfoSection: some View {
        VStack(spacing: 14) {
            VStack(spacing: 4) {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color("PrimaryColor").opacity(0.6))
                Text("UzmanaGel")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color("Text"))
                Text("Sürüm \(appVersion)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Text("© 2026 UzmanaGel. Tüm hakları saklıdır.")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.7))
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color("CardBackground"))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.04), radius: 6)
        }
    }

    // MARK: - Report Sheet
    private var reportSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Sorunu kısaca açıklayın:")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextEditor(text: $reportText)
                    .frame(minHeight: 140)
                    .padding(10)
                    .background(Color("CardBackground"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.2)))

                Button {
                    showReportSheet = false
                    reportText = ""
                    withAnimation { showReportSent = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation { showReportSent = false }
                    }
                } label: {
                    Text("GÖNDER")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(reportText.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? Color.gray.opacity(0.4)
                                    : Color("PrimaryColor"))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .disabled(reportText.trimmingCharacters(in: .whitespaces).isEmpty)

                Spacer()
            }
            .padding(20)
            .background(Color("BackgroundColor"))
            .navigationTitle("Hata Bildir")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { showReportSheet = false }
                }
            }
        }
    }
}

#Preview {
    NavigationStack { SupportPage() }
}
