//
//  ReviewRepository.swift
//  UzmanaGel
//
//  Created by Antigravity on 22.07.2026.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

enum ReviewRepositoryError: LocalizedError {
    case reviewAlreadySubmitted
    case invalidData
    case permissionDenied
    case reviewNotFound
    
    var errorDescription: String? {
        switch self {
        case .reviewAlreadySubmitted:
            return "Bu uzman veya hizmet için zaten bir değerlendirme göndermişsiniz.".localized
        case .invalidData:
            return "Değerlendirme bilgileri geçersiz veya eksik.".localized
        case .permissionDenied:
            return "Bu işlem için yetkiniz bulunmuyor.".localized
        case .reviewNotFound:
            return "Yorum bulunamadı.".localized
        }
    }
}

final class ReviewRepository {
    
    private let db = Firestore.firestore()
    private let collectionName = "reviews"
    
    // MARK: - Fetch Reviews by Provider
    func fetchReviews(forProviderId providerId: String) async throws -> [Review] {
        let snapshot = try await db.collection(collectionName)
            .whereField("providerId", isEqualTo: providerId)
            .getDocuments()
        
        let reviews = snapshot.documents.compactMap { doc -> Review? in
            if var decoded = try? doc.data(as: Review.self) {
                if decoded.id == nil {
                    decoded.id = doc.documentID
                }
                return decoded
            }
            return Review(fromDictionary: doc.data(), id: doc.documentID)
        }
        
        return reviews.sorted { ($0.createdAt?.dateValue() ?? Date.distantPast) > ($1.createdAt?.dateValue() ?? Date.distantPast) }
    }
    
    // MARK: - Check One Review Per Booking
    func fetchReview(forBookingId bookingId: String) async throws -> Review? {
        guard !bookingId.isEmpty else { return nil }
        var snapshot = try await db.collection(collectionName)
            .whereField("bookingId", isEqualTo: bookingId)
            .limit(to: 1)
            .getDocuments()
        
        if snapshot.documents.isEmpty {
            snapshot = try await db.collection(collectionName)
                .whereField("reservationId", isEqualTo: bookingId)
                .limit(to: 1)
                .getDocuments()
        }
        
        guard let first = snapshot.documents.first else { return nil }
        if var decoded = try? first.data(as: Review.self) {
            if decoded.id == nil { decoded.id = first.documentID }
            return decoded
        }
        return Review(fromDictionary: first.data(), id: first.documentID)
    }
    
    // MARK: - Submit New Review
    func submitReview(review: Review) async throws {
        // Validation: one review per booking check if bookingId is provided
        if !review.bookingId.isEmpty {
            if try await fetchReview(forBookingId: review.bookingId) != nil {
                throw ReviewRepositoryError.reviewAlreadySubmitted
            }
        } else {
            // Prevent spam: only one general review per provider per customer
            let snapshot = try await db.collection(collectionName)
                .whereField("customerId", isEqualTo: review.customerId)
                .getDocuments()
            
            let alreadyReviewed = snapshot.documents.contains { doc in
                (doc.data()["providerId"] as? String) == review.providerId
            }
            if alreadyReviewed {
                throw ReviewRepositoryError.reviewAlreadySubmitted
            }
        }
        
        let docRef = db.collection(collectionName).document(review.reviewId)
        try docRef.setData(from: review)
        
        // Review statistics are updated by Cloud Functions.
    }
    
    // MARK: - Provider Response
    func submitProviderResponse(reviewId: String, response: String) async throws {
        guard let currentUid = Auth.auth().currentUser?.uid else {
            throw ReviewRepositoryError.permissionDenied
        }
        
        let docRef = db.collection(collectionName).document(reviewId)
        let snapshot = try await docRef.getDocument()
        guard let data = snapshot.data(), let providerId = data["providerId"] as? String else {
            throw ReviewRepositoryError.reviewNotFound
        }
        
        guard providerId == currentUid else {
            throw ReviewRepositoryError.permissionDenied
        }
        
        try await docRef.updateData([
            "providerResponse": response,
            "providerResponseDate": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date())
        ])
    }
    
    // MARK: - Toggle Helpful / Thumbs Up
    func toggleHelpful(reviewId: String, userId: String) async throws -> (Int, Bool) {
        let docRef = db.collection(collectionName).document(reviewId)
        let snapshot = try await docRef.getDocument()
        
        guard var review = try? snapshot.data(as: Review.self) else {
            throw ReviewRepositoryError.reviewNotFound
        }
        
        var isHelpful = false
        if let idx = review.helpfulUsers.firstIndex(of: userId) {
            review.helpfulUsers.remove(at: idx)
            review.helpfulCount = max(0, review.helpfulCount - 1)
            isHelpful = false
        } else {
            review.helpfulUsers.append(userId)
            review.helpfulCount += 1
            isHelpful = true
        }
        
        try await docRef.updateData([
            "helpfulUsers": review.helpfulUsers,
            "helpfulCount": review.helpfulCount
        ])
        
        return (review.helpfulCount, isHelpful)
    }
    
    // MARK: - Report Review
    func reportReview(
        reviewId: String,
        providerId: String,
        category: ReviewReportCategory,
        description: String
    ) async throws {
        guard let reporterId = Auth.auth().currentUser?.uid else {
            throw NSError(
                domain: "ReviewRepository",
                code: 401,
                userInfo: [
                    NSLocalizedDescriptionKey: "Yorum bildirmek için giriş yapmalısınız."
                ]
            )
        }

        let cleanDescription = description.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard cleanDescription.count <= 500 else {
            throw NSError(
                domain: "ReviewRepository",
                code: 400,
                userInfo: [
                    NSLocalizedDescriptionKey: "Açıklama en fazla 500 karakter olabilir."
                ]
            )
        }

        let reportId = "\(reviewId)_\(reporterId)"
        let reviewRef = db.collection(collectionName).document(reviewId)
        let reportRef = db.collection("review_reports").document(reportId)
        let now = Timestamp(date: Date())

        let batch = db.batch()

        batch.setData([
            "reportId": reportId,
            "reviewId": reviewId,
            "reporterId": reporterId,
            "providerId": providerId,
            "category": category.rawValue,
            "description": cleanDescription,
            "status": "pending",
            "createdAt": now
        ], forDocument: reportRef)

        batch.updateData([
            "isReported": true,
            "updatedAt": now
        ], forDocument: reviewRef)

        try await batch.commit()
    }
}
