//
//  ProviderResponseSheet.swift
//  UzmanaGel
//
//  Created by Antigravity on 22.07.2026.
//

import SwiftUI
import FirebaseFirestore

struct ProviderResponseSheet: View {
    let review: Review
    let onSubmit: (String) async -> Bool
    
    @Environment(\.dismiss) private var dismiss
    @State private var responseText: String = ""
    @State private var isSubmitting: Bool = false
    @State private var showPreview: Bool = false
    @State private var errorMessage: String? = nil
    
    private let characterLimit = 400
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Yorum Özeti Kartı
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(review.customerName)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color("Text"))
                            Spacer()
                            HStack(spacing: 2) {
                                ForEach(1...5, id: \.self) { s in
                                    Image(systemName: s <= Int(review.rating.rounded()) ? "star.fill" : "star")
                                        .font(.system(size: 12))
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        
                        Text(review.comment)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    }
                    .padding(14)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    
                    // Profesyonel Ton Önerisi Kutusu
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16))
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Profesyonel İpucu".localized)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color("Text"))
                            Text("Müşterilerinize nazik ve yapıcı bir dille yanıt vermek, profilinizin güvenilirliğini ve gelecekteki iş alma şansınızı büyük ölçüde artırır.".localized)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(14)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    
                    // Metin Alanı
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Yanıtınız".localized)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color("Text"))
                            Spacer()
                            Text("\(responseText.count)/\(characterLimit)")
                                .font(.system(size: 12))
                                .foregroundColor(responseText.count > characterLimit ? .red : .secondary)
                        }
                        
                        TextEditor(text: $responseText)
                            .font(.system(size: 14))
                            .frame(minHeight: 120)
                            .padding(8)
                            .background(Color("CardBackground"))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                            .onChange(of: responseText) { newValue in
                                if newValue.count > characterLimit {
                                    responseText = String(newValue.prefix(characterLimit))
                                }
                            }
                    }
                    
                    // Önizleme Butonu & Görünümü
                    if !responseText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button {
                            withAnimation { showPreview.toggle() }
                        } label: {
                            HStack {
                                Image(systemName: showPreview ? "eye.slash.fill" : "eye.fill")
                                Text(showPreview ? "Önizlemeyi Gizle".localized : "Müşterinin Göreceği Önizleme".localized)
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(Color("PrimaryColor"))
                        }
                        
                        if showPreview {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "arrow.turn.down.right")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Color("PrimaryColor"))
                                    Text("Sizin Yanıtınız / Uzman Yanıtı".localized)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Color("PrimaryColor"))
                                    Spacer()
                                    Text("Şimdi".localized)
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                Text(responseText)
                                    .font(.system(size: 13))
                                    .foregroundColor(Color("Text"))
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color("CardBackground"))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color("PrimaryColor").opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                    }
                    
                    // Gönder Butonu
                    Button {
                        Task {
                            isSubmitting = true
                            errorMessage = nil
                            let success = await onSubmit(responseText)
                            isSubmitting = false
                            if success {
                                dismiss()
                            } else {
                                errorMessage = "Yanıt gönderilemedi. Lütfen tekrar deneyin.".localized
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if isSubmitting {
                                ProgressView().tint(.white)
                            }
                            Text("Yanıtı Gönder".localized)
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(responseText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color("PrimaryColor"))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: Color("PrimaryColor").opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                    .disabled(responseText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                }
                .padding(20)
            }
            .navigationTitle("Yoruma Yanıt Yaz".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal".localized) { dismiss() }
                }
            }
        }
    }
}
