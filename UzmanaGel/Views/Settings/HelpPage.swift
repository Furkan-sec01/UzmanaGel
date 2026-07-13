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
                    answer: "Ana sayfadan hizmetleri inceleyebilir, arama ve filtreleme seçeneklerini kullanabilirsiniz."
                )

                helpRow(
                    question: "Favorilere nasıl eklerim?",
                    answer: "Bir hizmet kartındaki kalp ikonuna dokunarak hizmeti favorilerinize ekleyebilirsiniz."
                )

                helpRow(
                    question: "Uzman olmak için ne yapmalıyım?",
                    answer: "Uzman başvuru sürecini tamamlayarak gerekli bilgileri ve doğrulamaları gönderebilirsiniz."
                )
            }
        }
        .navigationTitle("Yardım")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func helpRow(
        question: String,
        answer: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(question)
                .font(.system(size: 15, weight: .semibold))

            Text(answer)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        HelpPage()
    }
}
