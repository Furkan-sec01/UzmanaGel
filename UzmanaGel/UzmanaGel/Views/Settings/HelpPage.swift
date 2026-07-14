//
//  HelpPage.swift
//  UzmanaGel
//
//  Created by Halil Keremoğlu on 9.07.2026.
//

import SwiftUI

struct HelpPage: View {

    var body: some View {
        List {
            Section("Sık Sorulan Sorular") {
                helpRow(
                    question: "Nasıl hizmet bulabilirim?",
                    answer: "Ana sayfadan hizmetleri inceleyebilir, arama ve filtreleme seçeneklerini kullanarak ihtiyacınıza uygun hizmetleri bulabilirsiniz."
                )

                helpRow(
                    question: "Bir hizmeti favorilere nasıl eklerim?",
                    answer: "Hizmet kartındaki veya hizmet detay sayfasındaki kalp ikonuna dokunarak hizmeti favorilerinize ekleyebilirsiniz."
                )

                helpRow(
                    question: "Rezervasyon nasıl oluşturulur?",
                    answer: "Hizmet detay sayfasına girip rezervasyon oluşturma butonuna dokunarak tarih ve not bilgisiyle rezervasyon talebi oluşturabilirsiniz."
                )

                helpRow(
                    question: "Rezervasyonumu nasıl iptal ederim?",
                    answer: "Rezervasyonlarım sayfasından aktif rezervasyonunuzu seçip iptal işlemini gerçekleştirebilirsiniz."
                )

                helpRow(
                    question: "Uzmanla nasıl mesajlaşırım?",
                    answer: "Hizmet detay sayfasından uzmanla mesajlaşma akışını başlatabilir, Mesajlar sayfasından mevcut konuşmalarınızı takip edebilirsiniz."
                )

                helpRow(
                    question: "Bildirim ayarlarımı nereden değiştirebilirim?",
                    answer: "Ayarlar sayfasındaki Bildirim Tercihleri bölümünden rezervasyon, mesaj, sistem ve kampanya bildirimlerini yönetebilirsiniz."
                )

                helpRow(
                    question: "Adres bilgilerimi nereden yönetebilirim?",
                    answer: "Profil sayfasındaki Adreslerim bölümünden kayıtlı adreslerinizi görüntüleyebilir ve düzenleyebilirsiniz."
                )

                helpRow(
                    question: "Profil bilgilerimi nasıl güncellerim?",
                    answer: "Profil sayfasındaki Düzenle veya Kullanıcı Bilgileri alanından ad, iletişim ve profil bilgilerinizi güncelleyebilirsiniz."
                )

                helpRow(
                    question: "Uzman olmak için ne yapmalıyım?",
                    answer: "Uzman başvuru sürecini tamamlayarak gerekli bilgileri ve doğrulamaları gönderebilirsiniz."
                )
            }

            Section("Destek") {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Sorun Bildirme", systemImage: "exclamationmark.bubble")
                        .font(.system(size: 15, weight: .semibold))

                    Text("Bir sorun yaşarsanız ekran görüntüsü, işlem adımı ve hesap bilgilerinizle birlikte destek ekibine iletmeniz sorunun daha hızlı incelenmesini sağlar.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Yardım")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func helpRow(
        question: String,
        answer: String
    ) -> some View {
        DisclosureGroup {
            Text(answer)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .padding(.top, 6)
        } label: {
            Text(question)
                .font(.system(size: 15, weight: .semibold))
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        HelpPage()
    }
}
