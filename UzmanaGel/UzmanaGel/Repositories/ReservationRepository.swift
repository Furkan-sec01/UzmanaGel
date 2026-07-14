//
//  ReservationRepository.swift
//  UzmanaGel
//
//  Created by Halil Keremoğlu on 13.07.2026.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

final class ReservationRepository {

    private let db = Firestore.firestore()
    private let collectionName = "reservations"

    enum ReservationRepositoryError: LocalizedError {
        case userNotFound
        case invalidService
        case invalidProvider
        case invalidCustomerName
        case invalidReservation

        var errorDescription: String? {
            switch self {
            case .userNotFound:
                return "Kullanıcı oturumu bulunamadı."
            case .invalidService:
                return "Hizmet bilgisi eksik."
            case .invalidProvider:
                return "Uzman bilgisi eksik."
            case .invalidCustomerName:
                return "Müşteri adı eksik."
            case .invalidReservation:
                return "Rezervasyon bilgisi eksik."
            }
        }
    }

    func createReservation(
        serviceId: String,
        serviceTitle: String,
        providerId: String,
        providerName: String,
        customerName: String,
        reservationDate: Date,
        note: String
    ) async throws -> String {

        guard let currentUser = Auth.auth().currentUser else {
            throw ReservationRepositoryError.userNotFound
        }

        let trimmedServiceId = serviceId.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedServiceTitle = serviceTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedProviderId = providerId.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedProviderName = providerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCustomerName = customerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedServiceId.isEmpty && !trimmedServiceTitle.isEmpty else {
            throw ReservationRepositoryError.invalidService
        }

        guard !trimmedProviderId.isEmpty && !trimmedProviderName.isEmpty else {
            throw ReservationRepositoryError.invalidProvider
        }

        guard !trimmedCustomerName.isEmpty else {
            throw ReservationRepositoryError.invalidCustomerName
        }

        let documentRef = db.collection(collectionName).document()
        let now = Date()

        let data: [String: Any] = [
            "reservationId": documentRef.documentID,
            "serviceId": trimmedServiceId,
            "serviceTitle": trimmedServiceTitle,
            "providerId": trimmedProviderId,
            "providerName": trimmedProviderName,
            "customerId": currentUser.uid,
            "customerName": trimmedCustomerName,
            "reservationDate": Timestamp(date: reservationDate),
            "note": trimmedNote,
            "status": ReservationStatus.pending.rawValue,
            "createdAt": Timestamp(date: now),
            "updatedAt": Timestamp(date: now)
        ]

        try await documentRef.setData(data)

        return documentRef.documentID
    }
    
    func fetchMyReservations() async throws -> [Reservation] {
        guard let currentUser = Auth.auth().currentUser else {
            throw ReservationRepositoryError.userNotFound
        }

        let snapshot = try await db
            .collection(collectionName)
            .whereField("customerId", isEqualTo: currentUser.uid)
            .getDocuments()

        let reservations = snapshot.documents.compactMap { document in
            mapReservation(from: document)
        }

        return reservations.sorted {
            $0.createdAt > $1.createdAt
        }
    }
    
    func fetchProviderReservations() async throws -> [Reservation] {
        guard let currentUser = Auth.auth().currentUser else {
            throw ReservationRepositoryError.userNotFound
        }

        let snapshot = try await db
            .collection(collectionName)
            .whereField("providerId", isEqualTo: currentUser.uid)
            .getDocuments()

        let reservations = snapshot.documents.compactMap { document in
            mapReservation(from: document)
        }

        return reservations.sorted {
            $0.reservationDate < $1.reservationDate
        }
    }
    
    func cancelReservation(
        reservationId: String
    ) async throws {
        guard Auth.auth().currentUser != nil else {
            throw ReservationRepositoryError.userNotFound
        }

        let trimmedReservationId = reservationId.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedReservationId.isEmpty else {
            throw ReservationRepositoryError.invalidReservation
        }

        try await db
            .collection(collectionName)
            .document(trimmedReservationId)
            .updateData([
                "status": ReservationStatus.cancelled.rawValue,
                "updatedAt": Timestamp(date: Date())
            ])
    }
    ///Firestore'dan gelen veriyi Swift modeline cevirir
    private func mapReservation(
        from document: QueryDocumentSnapshot
    ) -> Reservation? {
        let data = document.data()

        guard
            let serviceId = data["serviceId"] as? String,
            let serviceTitle = data["serviceTitle"] as? String,
            let providerId = data["providerId"] as? String,
            let providerName = data["providerName"] as? String,
            let customerId = data["customerId"] as? String,
            let customerName = data["customerName"] as? String,
            let reservationDateTimestamp = data["reservationDate"] as? Timestamp,
            let note = data["note"] as? String,
            let statusRawValue = data["status"] as? String,
            let status = ReservationStatus(rawValue: statusRawValue),
            let createdAtTimestamp = data["createdAt"] as? Timestamp,
            let updatedAtTimestamp = data["updatedAt"] as? Timestamp
        else {
            return nil
        }

        let reservationId = data["reservationId"] as? String ?? document.documentID

        return Reservation(
            reservationId: reservationId,
            serviceId: serviceId,
            serviceTitle: serviceTitle,
            providerId: providerId,
            providerName: providerName,
            customerId: customerId,
            customerName: customerName,
            reservationDate: reservationDateTimestamp.dateValue(),
            note: note,
            status: status,
            createdAt: createdAtTimestamp.dateValue(),
            updatedAt: updatedAtTimestamp.dateValue()
        )
    }
}
