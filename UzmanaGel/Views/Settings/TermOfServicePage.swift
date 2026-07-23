//
//  TermOfServicePage.swift
//  UzmanaGel
//
//  Created by Halil Keremoğlu on 14.07.2026.
//

import SwiftUI

struct TermsOfServicePage: View {
    @ObservedObject private var langManager = LanguageManager.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                termsSection(
                    title: "1. Hizmetin Kullanımı".localized,
                    text: "UzmanaGel, kullanıcıların ihtiyaç duydukları hizmetler için uygun uzmanlarla iletişim kurmasını sağlayan bir platformdur. Kullanıcılar, uygulamayı doğru ve güncel bilgilerle kullanmakla sorumludur.".localized
                )

                termsSection(
                    title: "2. Uzman ve Kullanıcı Sorumlulukları".localized,
                    text: "Uzmanlar sundukları hizmet bilgilerini doğru şekilde paylaşmalıdır. Kullanıcılar oluşturdukları rezervasyon taleplerinde doğru iletişim ve ihtiyaç bilgisi vermelidir.".localized
                )

                termsSection(
                    title: "3. Rezervasyonlar".localized,
                    text: "Rezervasyon talepleri uygulama üzerinden oluşturulur. Rezervasyonun kesinleşmesi, ilgili uzmanın talebi değerlendirmesine bağlıdır. Kullanıcılar aktif rezervasyon taleplerini iptal edebilir.".localized
                )

                termsSection(
                    title: "4. Mesajlaşma".localized,
                    text: "Kullanıcılar ve uzmanlar, hizmet sürecini takip etmek için uygulama içi mesajlaşma özelliğini kullanabilir. Uygunsuz, yanıltıcı veya kötüye kullanım içeren mesajlardan kullanıcı sorumludur.".localized
                )

                termsSection(
                    title: "5. Gizlilik".localized,
                    text: "Kullanıcı verileri, uygulamanın hizmet sunabilmesi için gerekli olan kapsamda işlenir. Gizlilik ve KVKK detayları ilgili gizlilik sayfasında açıklanır.".localized
                )

                termsSection(
                    title: "6. Değişiklikler".localized,
                    text: "UzmanaGel, kullanım şartlarını uygulama geliştikçe güncelleyebilir. Güncel şartlar uygulama içinde kullanıcıya sunulur.".localized
                )
            }
            .padding(20)
        }
        .background(Color("BackgroundColor"))
        .navigationTitle("Kullanım Şartları".localized)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 44))
                .foregroundColor(Color("PrimaryColor"))

            Text("Kullanım Şartları".localized)
                .font(.title2)
                .fontWeight(.bold)

            Text("Bu sayfa, UzmanaGel uygulamasının temel kullanım kurallarını özetler.".localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func termsSection(
        title: String,
        text: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineSpacing(3)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}

#Preview {
    NavigationStack {
        TermsOfServicePage()
    }
}
