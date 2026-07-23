//
//  ReviewReportSheet.swift
//  UzmanaGel
//
//  Created by Antigravity on 22.07.2026.
//

import SwiftUI
import FirebaseFirestore

struct ReviewReportSheet: View {
    let review: Review
    let onSubmit: (ReviewReportCategory, String) async -> Bool
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: ReviewReportCategory = .inappropriate
    @State private var descriptionText: String = ""
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Yorumu Bildirme Nedeni".localized)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color("Text"))
                    
                    VStack(spacing: 10) {
                        ForEach(ReviewReportCategory.allCases) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                HStack {
                                    Text(category.displayName)
                                        .font(.system(size: 14))
                                        .foregroundColor(Color("Text"))
                                    Spacer()
                                    Image(systemName: selectedCategory == category ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 18))
                                        .foregroundColor(selectedCategory == category ? Color("PrimaryColor") : .secondary)
                                }
                                .padding(14)
                                .background(Color("CardBackground"))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(selectedCategory == category ? Color("PrimaryColor") : Color.secondary.opacity(0.2), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Açıklama (Opsiyonel)".localized)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color("Text"))
                        
                        TextEditor(text: $descriptionText)
                            .font(.system(size: 14))
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(Color("CardBackground"))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                    }
                    
                    Button {
                        Task {
                            isSubmitting = true
                            errorMessage = nil
                            let success = await onSubmit(selectedCategory, descriptionText)
                            isSubmitting = false
                            if success {
                                dismiss()
                            } else {
                                errorMessage = "Bildirim gönderilemedi. Lütfen tekrar deneyin.".localized
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if isSubmitting {
                                ProgressView().tint(.white)
                            }
                            Text("Bildirimi Gönder".localized)
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color("PrimaryColor"))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: Color("PrimaryColor").opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                    .disabled(isSubmitting)
                }
                .padding(20)
            }
            .navigationTitle("Yorumu Bildir".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal".localized) { dismiss() }
                }
            }
        }
    }
}
