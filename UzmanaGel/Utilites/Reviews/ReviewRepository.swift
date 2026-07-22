import FirebaseAuth
import FirebaseFirestore
import Foundation

enum ReviewRepositoryError: LocalizedError {
    case userNotFound
    case invalidProviderId
    case invalidReview
    case reviewNotAllowed
    case alreadyReviewed

    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "Kullanıcı oturumu bulunamadı."
        case .invalidProviderId:
            return "Uzman bilgisi geçersiz."
        case .invalidReview:
            return "Değerlendirme bilgileri geçersiz."
        case .reviewNotAllowed:
            return "Yalnızca tamamlanan rezervasyonlar değerlendirilebilir."
        case .alreadyReviewed:
            return "Bu rezervasyon daha önce değerlendirilmiş."
        }
    }
}

final class ReviewRepository {

    private let db = Firestore.firestore()
    private let collectionName = "reviews"

    func fetchReviews(
        providerId: String
    ) async throws -> [ProviderReview] {
        guard Auth.auth().currentUser != nil else {
            throw ReviewRepositoryError.userNotFound
        }

        let trimmedProviderId = providerId.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedProviderId.isEmpty else {
            throw ReviewRepositoryError.invalidProviderId
        }

        let snapshot = try await db
            .collection(collectionName)
            .whereField(
                "providerId",
                isEqualTo: trimmedProviderId
            )
            .getDocuments()

        return snapshot.documents
            .compactMap(mapReview)
            .sorted {
                $0.createdAt > $1.createdAt
            }
    }

    func hasReview(
        reservationId: String
    ) async throws -> Bool {
        guard Auth.auth().currentUser != nil else {
            throw ReviewRepositoryError.userNotFound
        }

        let trimmedReservationId = reservationId.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedReservationId.isEmpty else {
            throw ReviewRepositoryError.invalidReview
        }

        let snapshot = try await db
            .collection(collectionName)
            .document(trimmedReservationId)
            .getDocument()

        return snapshot.exists
    }

    func submitReview(
        reservation: Reservation,
        rating: Int,
        comment: String
    ) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw ReviewRepositoryError.userNotFound
        }

        guard
            reservation.customerId == currentUser.uid,
            reservation.status == .completed
        else {
            throw ReviewRepositoryError.reviewNotAllowed
        }

        guard (1...5).contains(rating) else {
            throw ReviewRepositoryError.invalidReview
        }

        let trimmedComment = comment.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard trimmedComment.count <= 500 else {
            throw ReviewRepositoryError.invalidReview
        }

        let reviewRef = db
            .collection(collectionName)
            .document(reservation.reservationId)

        let existingReview = try await reviewRef.getDocument()

        guard !existingReview.exists else {
            throw ReviewRepositoryError.alreadyReviewed
        }

        try await reviewRef.setData([
            "reviewId": reservation.reservationId,
            "reservationId": reservation.reservationId,
            "providerId": reservation.providerId,
            "customerId": reservation.customerId,
            "customerName": reservation.customerName,
            "serviceId": reservation.serviceId,
            "serviceTitle": reservation.serviceTitle,
            "rating": rating,
            "comment": trimmedComment,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }

    private func mapReview(
        from document: QueryDocumentSnapshot
    ) -> ProviderReview? {
        let data = document.data()

        guard
            let reservationId = data["reservationId"] as? String,
            let providerId = data["providerId"] as? String,
            let customerId = data["customerId"] as? String,
            let customerName = data["customerName"] as? String,
            let serviceId = data["serviceId"] as? String,
            let serviceTitle = data["serviceTitle"] as? String,
            let comment = data["comment"] as? String
        else {
            return nil
        }

        let rating: Int

        if let value = data["rating"] as? Int {
            rating = value
        } else if let value = data["rating"] as? NSNumber {
            rating = value.intValue
        } else {
            return nil
        }

        guard (1...5).contains(rating) else {
            return nil
        }

        let createdAt =
            (data["createdAt"] as? Timestamp)?.dateValue()
            ?? Date.distantPast

        let updatedAt =
            (data["updatedAt"] as? Timestamp)?.dateValue()
            ?? createdAt

        let reviewId =
            (data["reviewId"] as? String)?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        return ProviderReview(
            reviewId: reviewId?.isEmpty == false
                ? reviewId!
                : document.documentID,
            reservationId: reservationId,
            providerId: providerId,
            customerId: customerId,
            customerName: customerName,
            serviceId: serviceId,
            serviceTitle: serviceTitle,
            rating: rating,
            comment: comment,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
