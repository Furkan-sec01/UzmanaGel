//
//  ReviewCardView.swift
//  UzmanaGel
//
//  Created by Antigravity on 22.07.2026.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ReviewCardView: View {
    let review: Review
    let isAnonymized: Bool
    let canRespond: Bool
    let onHelpfulTapped: () -> Void
    let onRespondTapped: () -> Void
    let onReportTapped: () -> Void
    let onPhotoTapped: ([String], Int) -> Void
    
    @State private var showCategories = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Üst Satır: Profil Resmi, İsim, Tarih, Onaylı rozet
            HStack(alignment: .top, spacing: 12) {
                userAvatar
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(review.getAnonymizedName(isAnonymized: isAnonymized))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color("Text"))
                        
                        if review.isVerifiedBooking {
                            HStack(spacing: 3) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 11))
                                Text("Onaylı Hizmet".localized)
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.12))
                            .clipShape(Capsule())
                        }
                    }
                    
                    Text(review.formattedDateString)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Yıldızlar
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= Int(review.rating.rounded()) ? "star.fill" : "star")
                            .font(.system(size: 13))
                            .foregroundColor(.orange)
                    }
                }
            }
            
            // Yorum Metni
            if !review.comment.isEmpty {
                Text(review.comment)
                    .font(.system(size: 14))
                    .foregroundColor(Color("Text").opacity(0.9))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Kategori Puanları (Genişletilebilir / Pill listesi)
            if !review.categoryRatings.isEmpty {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showCategories.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(showCategories ? "Detaylı Puanları Gizle".localized : "Kategori Puanları".localized)
                            .font(.system(size: 12, weight: .semibold))
                        Image(systemName: showCategories ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(Color("PrimaryColor"))
                }
                .buttonStyle(.plain)
                
                if showCategories {
                    VStack(spacing: 6) {
                        ForEach(review.categoryRatings.sorted(by: { $0.key < $1.key }), id: \.key) { cat, val in
                            HStack {
                                Text(cat.localized)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                Spacer()
                                HStack(spacing: 2) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(.orange)
                                    Text(String(format: "%.1f", val))
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Color("Text"))
                                }
                            }
                        }
                    }
                    .padding(10)
                    .background(Color("CardBackground").opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
            
            // Fotoğraflar Grid
            if !review.photos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(review.photos.enumerated()), id: \.offset) { idx, photoURL in
                            AsyncImage(url: URL(string: photoURL)) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 84, height: 84)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                default:
                                    Rectangle()
                                        .fill(Color.secondary.opacity(0.15))
                                        .frame(width: 84, height: 84)
                                        .overlay(
                                            Image(systemName: "photo")
                                                .foregroundColor(.secondary)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                            }
                            .onTapGesture {
                                onPhotoTapped(review.photos, idx)
                            }
                        }
                    }
                }
            }
            
            // Uzman Yanıtı (providerResponse)
            if let response = review.providerResponse, !response.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "arrow.turn.down.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color("PrimaryColor"))
                        Text("Sizin Yanıtınız / Uzman Yanıtı".localized)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color("PrimaryColor"))
                        Spacer()
                        if let date = review.providerResponseDate?.dateValue() {
                            Text(formatDate(date))
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text(response)
                        .font(.system(size: 13))
                        .foregroundColor(Color("Text"))
                        .lineSpacing(2)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color("CardBackground"))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color("PrimaryColor").opacity(0.2), lineWidth: 1)
                )
                .padding(.leading, 12)
            } else if canRespond && review.providerResponse == nil {
                // Uzmanın henüz yanıt vermediği yorumlar için Yanıtla butonu
                Button {
                    onRespondTapped()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrowshape.turn.up.left.fill")
                            .font(.system(size: 12))
                        Text("Yanıtla".localized)
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(Color("PrimaryColor"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color("PrimaryColor").opacity(0.12))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.leading, 12)
            }
            
            Divider().padding(.top, 4)
            
            // Alt Çubuğu: Faydalı Sayacı ve Rapor Et
            HStack {
                Button {
                    onHelpfulTapped()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isHelpfulByCurrentUser ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .font(.system(size: 13))
                            .foregroundColor(isHelpfulByCurrentUser ? Color("PrimaryColor") : .secondary)
                        
                        Text(review.helpfulCount > 0 ? "\(review.helpfulCount) Faydalı".localized : "Faydalı".localized)
                            .font(.system(size: 13, weight: isHelpfulByCurrentUser ? .bold : .medium))
                            .foregroundColor(isHelpfulByCurrentUser ? Color("PrimaryColor") : .secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(isHelpfulByCurrentUser ? Color("PrimaryColor").opacity(0.1) : Color.clear)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                if !review.isReported {
                    Button {
                        onReportTapped()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "flag")
                                .font(.system(size: 12))
                            Text("Bildir".localized)
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.secondary.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "flag.fill")
                            .font(.system(size: 12))
                        Text("İnceleniyor".localized)
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.orange)
                }
            }
        }
        .padding(16)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
    
    private var isHelpfulByCurrentUser: Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        return review.helpfulUsers.contains(uid)
    }
    
    private var userAvatar: some View {
        Group {
            if let urlStr = review.customerAvatarURL, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        avatarPlaceholder
                    }
                }
            } else {
                avatarPlaceholder
            }
        }
    }
    
    private var avatarPlaceholder: some View {
        ZStack {
            Color(.secondarySystemBackground)
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 26))
                .foregroundColor(.secondary.opacity(0.6))
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateStyle = .short
        return f.string(from: date)
    }
}
