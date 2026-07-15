//
//  TermOfServicePage.swift
//  UzmanaGel
//
//  Created by Halil Keremoğlu on 14.07.2026.
//

import SwiftUI

struct TermsOfServicePage: View {

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                termsSection(
                    title: "1. Hizmetin Kullanımı",
                    text: "UzmanaGel, kullanıcıların ihtiyaç duydukları hizmetler için uygun uzmanlarla iletişim kurmasını sağlayan bir platformdur. Kullanıcılar, uygulamayı doğru ve güncel bilgilerle kullanmakla sorumludur."
                )

                termsSection(
                    title: "2. Uzman ve Kullanıcı Sorumlulukları",
                    text: "Uzmanlar sundukları hizmet bilgilerini doğru şekilde paylaşmalıdır. Kullanıcılar oluşturdukları rezervasyon taleplerinde doğru iletişim ve ihtiyaç bilgisi vermelidir."
                )

                termsSection(
                    title: "3. Rezervasyonlar",
                    text: "Rezervasyon talepleri uygulama üzerinden oluşturulur. Rezervasyonun kesinleşmesi, ilgili uzmanın talebi değerlendirmesine bağlıdır. Kullanıcılar aktif rezervasyon taleplerini iptal edebilir."
                )

                termsSection(
                    title: "4. Mesajlaşma",
                    text: "Kullanıcılar ve uzmanlar, hizmet sürecini takip etmek için uygulama içi mesajlaşma özelliğini kullanabilir. Uygunsuz, yanıltıcı veya kötüye kullanım içeren mesajlardan kullanıcı sorumludur."
                )

                termsSection(
                    title: "5. Gizlilik",
                    text: "Kullanıcı verileri, uygulamanın hizmet sunabilmesi için gerekli olan kapsamda işlenir. Gizlilik ve KVKK detayları ilgili gizlilik sayfasında açıklanır."
                )

                termsSection(
                    title: "6. Değişiklikler",
                    text: "UzmanaGel, kullanım şartlarını uygulama geliştikçe güncelleyebilir. Güncel şartlar uygulama içinde kullanıcıya sunulur."
                )
            }
            .padding(20)
        }
        .background(Color("BackgroundColor"))
        .navigationTitle("Kullanım Şartları")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 44))
                .foregroundColor(Color("PrimaryColor"))

            Text("Kullanım Şartları")
                .font(.title2)
                .fontWeight(.bold)

            Text("Bu sayfa, UzmanaGel uygulamasının temel kullanım kurallarını özetler.")
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
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        TermsOfServicePage()
    }
}
