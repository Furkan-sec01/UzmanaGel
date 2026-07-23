//
//  HelpPage.swift
//  UzmanaGel
//
//  Created by Halil Keremoğlu on 9.07.2026.
//

import SwiftUI

struct HelpPage: View {
    @ObservedObject private var langManager = LanguageManager.shared

    var body: some View {
        ZStack {
            Color("BackgroundColor").ignoresSafeArea()
            
            List {
                Section("Sık Sorulan Sorular".localized) {
                    helpRow(
                        question: "Nasıl hizmet bulabilirim?".localized,
                        answer: "Ana sayfadan hizmetleri inceleyebilir, arama ve filtreleme seçeneklerini kullanarak ihtiyacınıza uygun hizmetleri bulabilirsiniz.".localized
                    )

                    helpRow(
                        question: "Bir hizmeti favorilere nasıl eklerim?".localized,
                        answer: "Hizmet kartındaki veya hizmet detay sayfasındaki kalp ikonuna dokunarak hizmeti favorilerinize ekleyebilirsiniz.".localized
                    )

                    helpRow(
                        question: "Rezervasyon nasıl oluşturulur?".localized,
                        answer: "Hizmet detay sayfasına girip rezervasyon oluşturma butonuna dokunarak tarih ve not bilgisiyle rezervasyon talebi oluşturabilirsiniz.".localized
                    )

                    helpRow(
                        question: "Rezervasyonumu nasıl iptal ederim?".localized,
                        answer: "Rezervasyonlarım sayfasından aktif rezervasyonunuzu seçip iptal işlemini gerçekleştirebilirsiniz.".localized
                    )

                    helpRow(
                        question: "Uzmanla nasıl mesajlaşırım?".localized,
                        answer: "Hizmet detay sayfasından uzmanla mesajlaşma akışını başlatabilir, Mesajlar sayfasından mevcut konuşmalarınızı takip edebilirsiniz.".localized
                    )

                    helpRow(
                        question: "Bildirim ayarlarımı nereden değiştirebilirim?".localized,
                        answer: "Ayarlar sayfasındaki Bildirim Tercihleri bölümünden rezervasyon, mesaj, sistem ve kampanya bildirimlerini yönetebilirsiniz.".localized
                    )

                    helpRow(
                        question: "Adres bilgilerimi nereden yönetebilirim?".localized,
                        answer: "Profil sayfasındaki Adreslerim bölümünden kayıtlı adreslerinizi görüntüleyebilir ve düzenleyebilirsiniz.".localized
                    )

                    helpRow(
                        question: "Profil bilgilerimi nasıl güncellerim?".localized,
                        answer: "Profil sayfasındaki Düzenle veya Kullanıcı Bilgileri alanından ad, iletişim ve profil bilgilerinizi güncelleyebilirsiniz.".localized
                    )

                    helpRow(
                        question: "Uzman olmak için ne yapmalıyım?".localized,
                        answer: "Uzman başvuru sürecini tamamlayarak gerekli bilgileri ve doğrulamaları gönderebilirsiniz.".localized
                    )
                }
                .listRowBackground(Color("CardBackground"))

                Section("Destek".localized) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Sorun Bildirme".localized, systemImage: "exclamationmark.bubble")
                            .font(.system(size: 15, weight: .semibold))

                        Text("Bir sorun yaşarsanız ekran görüntüsü, işlem adımı ve hesap bilgilerinizle birlikte destek ekibine iletmeniz sorunun daha hızlı incelenmesini sağlar.".localized)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color("CardBackground"))
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Yardım".localized)
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
