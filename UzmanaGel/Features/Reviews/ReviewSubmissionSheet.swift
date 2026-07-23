//
//  ReviewSubmissionSheet.swift
//  UzmanaGel
//
//  Created by Antigravity on 22.07.2026.
//

import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

struct ReviewSubmissionSheet: View {
    let bookingId: String
    var serviceId: String? = nil
    var serviceTitle: String? = nil
    let providerId: String
    let providerName: String
    let customerId: String
    let customerName: String
    let onSubmitted: ((Double) -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    
    // Form State
    @State private var overallRating: Int = 5
    @State private var categoryRatings: [String: Double] = [
        ReviewCategory.professionalism.rawValue: 5.0,
        ReviewCategory.cleanliness.rawValue: 5.0,
        ReviewCategory.communication.rawValue: 5.0,
        ReviewCategory.punctuality.rawValue: 5.0,
        ReviewCategory.valueForMoney.rawValue: 5.0
    ]
    @State private var commentText: String = ""
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    
    @State private var isSubmitting = false
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert = false
    
    private let characterLimit = 500
    private let reviewRepository = ReviewRepository()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("BackgroundColor").ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // Uzman Başlığı & Genel Yıldız
                        headerRatingSection
                        
                        // Kategori Puanları (Yıldız / Slider)
                        categoryRatingsSection
                        
                        // Yazılı Yorum (TextEditor + Karakter sayacı + Placeholder)
                        writtenReviewSection
                        
                        // Fotoğraf Yükleme (PhotosPicker + Grid)
                        photosUploadSection
                        
                        // Hata mesajı
                        if let error = errorMessage {
                            Text(error)
                                .font(.system(size: 13))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        
                        // Gönder Butonu
                        submitButton
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Hizmeti Değerlendir".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal".localized) { dismiss() }
                        .disabled(isSubmitting)
                }
            }
            .alert("Değerlendirme Hatası".localized, isPresented: $showErrorAlert) {
                Button("Tamam".localized, role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Yorum gönderilirken bir sorun oluştu.")
            }
        }
    }
    
    // MARK: - Header & Overall Rating
    private var headerRatingSection: some View {
        VStack(spacing: 12) {
            Text(String(format: "%@ aldığınız hizmeti değerlendirin".localized, providerName))
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color("Text"))
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                            overallRating = star
                        }
                    } label: {
                        Image(systemName: star <= overallRating ? "star.fill" : "star")
                            .font(.system(size: 32))
                            .foregroundColor(.orange)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Text(ratingDescription(overallRating))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.orange)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
    
    private func ratingDescription(_ rating: Int) -> String {
        switch rating {
        case 5: return "Mükemmel!".localized
        case 4: return "Çok İyi".localized
        case 3: return "Ortalama".localized
        case 2: return "Geliştirilmeli".localized
        default: return "Kötü".localized
        }
    }
    
    // MARK: - Category Ratings Section
    private var categoryRatingsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Detaylı Puanlama".localized)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color("Text"))
            
            VStack(spacing: 16) {
                ForEach(ReviewCategory.allCases) { category in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(category.displayName)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color("Text"))
                            Spacer()
                            let val = categoryRatings[category.rawValue] ?? Double(overallRating)
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.orange)
                                Text(String(format: "%.0f", val))
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color("Text"))
                            }
                        }
                        
                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { star in
                                Button {
                                    withAnimation { categoryRatings[category.rawValue] = Double(star) }
                                } label: {
                                    let currentVal = Int(categoryRatings[category.rawValue] ?? Double(overallRating))
                                    Image(systemName: star <= currentVal ? "star.fill" : "star")
                                        .font(.system(size: 20))
                                        .foregroundColor(star <= currentVal ? .orange : .secondary.opacity(0.3))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(Color("CardBackground"))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
        }
    }
    
    // MARK: - Written Review Section
    private var writtenReviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Deneyiminiz (Opsiyonel)".localized)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color("Text"))
                Spacer()
                Text("\(commentText.count)/\(characterLimit)")
                    .font(.system(size: 12))
                    .foregroundColor(commentText.count > characterLimit ? .red : .secondary)
            }
            
            ZStack(alignment: .topLeading) {
                if commentText.isEmpty {
                    Text("Hizmet kalitesi, ustanın iletişimi ve zamanlaması hakkında deneyimlerinizi paylaşın...".localized)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary.opacity(0.6))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 14)
                }
                
                TextEditor(text: $commentText)
                    .font(.system(size: 14))
                    .frame(minHeight: 120)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(Color("CardBackground"))
                    .onChange(of: commentText) { newValue in
                        if newValue.count > characterLimit {
                            commentText = String(newValue.prefix(characterLimit))
                        }
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.03), radius: 6, x: 0, y: 2)
        }
    }
    
    // MARK: - Photos Upload Section
    private var photosUploadSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Fotoğraf Ekle (Opsiyonel)".localized)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color("Text"))
                Spacer()
                PhotosPicker(selection: $selectedItems, maxSelectionCount: 5, matching: .images) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Fotoğraf Seç".localized)
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color("PrimaryColor"))
                }
            }
            
            if !selectedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(selectedImages.enumerated()), id: \.offset) { idx, img in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 90, height: 90)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                
                                Button {
                                    selectedImages.remove(at: idx)
                                    if idx < selectedItems.count {
                                        selectedItems.remove(at: idx)
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(.white)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                }
                                .offset(x: 6, y: -6)
                            }
                            .padding(6)
                        }
                    }
                }
            }
        }
        .onChange(of: selectedItems) { newItems in
            Task {
                var loaded: [UIImage] = []
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        loaded.append(uiImage)
                    }
                }
                selectedImages = loaded
            }
        }
    }
    
    // MARK: - Submit Button
    private var submitButton: some View {
        Button {
            Task { await submitReview() }
        } label: {
            HStack(spacing: 8) {
                if isSubmitting {
                    ProgressView().tint(.white)
                }
                Text("Değerlendirmeyi Gönder".localized)
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color("PrimaryColor"))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color("PrimaryColor").opacity(0.35), radius: 10, x: 0, y: 5)
        }
        .disabled(isSubmitting)
    }
    
    // MARK: - Submission Action
    private func submitReview() async {
        guard !isSubmitting else { return }
        isSubmitting = true
        errorMessage = nil
        
        do {
            // Client-side spam / content moderation validation
            if commentText.contains("http://") || commentText.contains("https://") {
                throw NSError(domain: "Spam", code: 400, userInfo: [NSLocalizedDescriptionKey: "Yorumlarda link paylaşılmasına izin verilmemektedir.".localized])
            }
            
            // Fotoğrafları Storage'a yükle (veya base64/URL)
            var photoURLs: [String] = []
            if !selectedImages.isEmpty {
                photoURLs = try await uploadPhotos(images: selectedImages)
            }
            
            let currentUid = Auth.auth().currentUser?.uid ?? customerId
            let finalCustomerName = customerName.isEmpty ? "Müşteri" : customerName
            
            let review = Review(
                bookingId: bookingId,
                reservationId: bookingId.isEmpty ? nil : bookingId,
                serviceId: serviceId,
                serviceTitle: serviceTitle,
                customerId: currentUid,
                providerId: providerId,
                rating: Double(overallRating),
                comment: commentText.trimmingCharacters(in: .whitespacesAndNewlines),
                categoryRatings: categoryRatings,
                photos: photoURLs,
                helpfulCount: 0,
                helpfulUsers: [],
                customerName: finalCustomerName,
                isVerifiedBooking: !bookingId.isEmpty
            )
            
            try await reviewRepository.submitReview(review: review)
            isSubmitting = false
            onSubmitted?(Double(overallRating))
            dismiss()
        } catch {
            isSubmitting = false
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
    
    private func uploadPhotos(images: [UIImage]) async throws -> [String] {
        let uploadService = StorageUploadService()
        let currentUid = Auth.auth().currentUser?.uid ?? customerId
        var urls: [String] = []
        for img in images {
            let url = try await uploadService.uploadReviewPhoto(image: img, quality: 0.7, uid: currentUid.isEmpty ? nil : currentUid)
            urls.append(url)
        }
        return urls
    }
}
