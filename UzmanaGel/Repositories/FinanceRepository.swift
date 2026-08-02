import Foundation
import FirebaseAuth
import FirebaseFirestore

/// FinanceRepository, uzmanın tamamlanan rezervasyonlarından kazanç hesaplar
/// ve para çekme taleplerini Firestore'a kaydeder/okur.
///
/// Koleksiyonlar:
///   - reservations (mevcut) → status == "completed" olanlar kazanç sayılır
///   - withdrawal_requests/{uid}/requests/{docId} → para çekme talepleri
final class FinanceRepository {

    private let db = Firestore.firestore()

    enum FinanceError: LocalizedError {
        case notAuthenticated
        case insufficientBalance

        var errorDescription: String? {
            switch self {
            case .notAuthenticated:
                return "Giriş yapılmamış. Lütfen tekrar giriş yapın."
            case .insufficientBalance:
                return "Çekilebilir bakiyeden fazla tutar çekemezsiniz."
            }
        }
    }

    // MARK: - Earnings

    /// Tamamlanan rezervasyonlardan kazanç listesi döner (en yeniden eskiye)
    func fetchEarnings(providerId: String) async throws -> [Earning] {
        let snapshot = try await db
            .collection("reservations")
            .whereField("providerId", isEqualTo: providerId)
            .whereField("status", isEqualTo: ReservationStatus.completed.rawValue)
            .getDocuments()

        let earnings = snapshot.documents.compactMap { doc -> Earning? in
            let data = doc.data()
            guard
                let serviceTitle = data["serviceTitle"] as? String,
                let createdAtTimestamp = data["createdAt"] as? Timestamp
            else { return nil }

            let price: Double
            if let intPrice = data["servicePrice"] as? Int {
                price = Double(intPrice)
            } else if let doublePrice = data["servicePrice"] as? Double {
                price = doublePrice
            } else {
                price = 0
            }

            return Earning(
                id: doc.documentID,
                amount: price,
                date: createdAtTimestamp.dateValue(),
                description: "Tamamlanan rezervasyon",
                jobTitle: serviceTitle,
                isPending: false
            )
        }

        return earnings.sorted { $0.date > $1.date }
    }

    /// Bekleyen rezervasyonları "bekleyen kazanç" olarak döner
    func fetchPendingEarnings(providerId: String) async throws -> [Earning] {
        let acceptedStatuses = [
            ReservationStatus.accepted.rawValue,
            ReservationStatus.inProgress.rawValue
        ]

        let snapshot = try await db
            .collection("reservations")
            .whereField("providerId", isEqualTo: providerId)
            .whereField("status", in: acceptedStatuses)
            .getDocuments()

        return snapshot.documents.compactMap { doc -> Earning? in
            let data = doc.data()
            guard
                let serviceTitle = data["serviceTitle"] as? String,
                let dateTimestamp = data["reservationDate"] as? Timestamp
            else { return nil }

            let price: Double
            if let intPrice = data["servicePrice"] as? Int {
                price = Double(intPrice)
            } else if let doublePrice = data["servicePrice"] as? Double {
                price = doublePrice
            } else {
                price = 0
            }

            return Earning(
                id: doc.documentID,
                amount: price,
                date: dateTimestamp.dateValue(),
                description: "Bekleyen rezervasyon",
                jobTitle: serviceTitle,
                isPending: true
            )
        }
    }

    // MARK: - Withdrawal Requests

    /// Para çekme taleplerini getirir (en yeniden eskiye)
    func fetchWithdrawalRequests(providerId: String) async throws -> [WithdrawalRequest] {
        let snapshot = try await db
            .collection("withdrawal_requests")
            .document(providerId)
            .collection("requests")
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { doc -> WithdrawalRequest? in
            let data = doc.data()
            guard
                let amount = data["amount"] as? Double,
                let bankName = data["bankName"] as? String,
                let iban = data["iban"] as? String,
                let statusRaw = data["status"] as? String,
                let createdAtTimestamp = data["createdAt"] as? Timestamp
            else { return nil }

            let status = WithdrawalRequest.RequestStatus(rawValue: statusRaw) ?? .pending

            return WithdrawalRequest(
                id: doc.documentID,
                amount: amount,
                bankName: bankName,
                iban: iban,
                status: status,
                date: createdAtTimestamp.dateValue()
            )
        }
    }

    /// Para çekme talebi oluşturur (gerçek transfer yok, sadece kayıt)
    func createWithdrawalRequest(
        providerId: String,
        amount: Double,
        bankName: String,
        iban: String
    ) async throws -> WithdrawalRequest {
        let now = Date()
        let docRef = db
            .collection("withdrawal_requests")
            .document(providerId)
            .collection("requests")
            .document()

        let data: [String: Any] = [
            "amount": amount,
            "bankName": bankName,
            "iban": iban,
            "status": WithdrawalRequest.RequestStatus.pending.rawValue,
            "createdAt": Timestamp(date: now),
            "updatedAt": Timestamp(date: now)
        ]

        try await docRef.setData(data)

        return WithdrawalRequest(
            id: docRef.documentID,
            amount: amount,
            bankName: bankName,
            iban: iban,
            status: .pending,
            date: now
        )
    }

    // MARK: - Balance Calculation

    /// Toplam kazanç = tamamlanan rezervasyon fiyatları toplamı
    func calculateTotalBalance(earnings: [Earning]) -> Double {
        earnings.filter { !$0.isPending }.reduce(0) { $0 + $1.amount }
    }

    /// Çekilebilir bakiye = toplam kazanç - tüm para çekme taleplerinin toplamı
    func calculateWithdrawableBalance(
        earnings: [Earning],
        requests: [WithdrawalRequest]
    ) -> Double {
        let total = calculateTotalBalance(earnings: earnings)
        let withdrawn = requests
            .filter { $0.status != .rejected }
            .reduce(0) { $0 + $1.amount }
        return max(0, total - withdrawn)
    }
}
