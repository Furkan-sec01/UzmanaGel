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
    private let bookedSlotsCollectionName = "provider_booked_slots"

    enum ReservationRepositoryError: LocalizedError {
        case userNotFound
        case invalidService
        case invalidProvider
        case invalidCustomerName
        case invalidReservation
        case slotUnavailable

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
            case .slotUnavailable:
                return "Seçtiğiniz saat dolu. Lütfen başka bir saat seçin."
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
        addressText: String,
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
        let trimmedAddressText = addressText.trimmingCharacters(in: .whitespacesAndNewlines)
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

        let dateKey = bookedSlotDateKey(from: reservationDate)
        let timeString = bookedSlotTimeString(from: reservationDate)
        let timeKey = timeString.replacingOccurrences(of: ":", with: "")

        let bookedSlotRef = db
            .collection(bookedSlotsCollectionName)
            .document(trimmedProviderId)
            .collection("dates")
            .document(dateKey)
            .collection("times")
            .document(timeKey)

        let existingSlot = try await bookedSlotRef.getDocument()

        if let existingData = existingSlot.data(),
           let existingStatus = existingData["status"] as? String,
           existingStatus == ReservationStatus.pending.rawValue ||
           existingStatus == ReservationStatus.accepted.rawValue {
            throw ReservationRepositoryError.slotUnavailable
        }

        let data: [String: Any] = [
            "reservationId": documentRef.documentID,
            "serviceId": trimmedServiceId,
            "serviceTitle": trimmedServiceTitle,
            "providerId": trimmedProviderId,
            "providerName": trimmedProviderName,
            "customerId": currentUser.uid,
            "customerName": trimmedCustomerName,
            "reservationDate": Timestamp(date: reservationDate),
            "addressText": trimmedAddressText,
            "note": trimmedNote,
            "status": ReservationStatus.pending.rawValue,
            "createdAt": Timestamp(date: now),
            "updatedAt": Timestamp(date: now)
        ]

        let bookedSlotData: [String: Any] = [
            "providerId": trimmedProviderId,
            "dateKey": dateKey,
            "timeString": timeString,
            "status": ReservationStatus.pending.rawValue,
            "reservationId": documentRef.documentID,
            "createdAt": Timestamp(date: now),
            "updatedAt": Timestamp(date: now)
        ]

        try await documentRef.setData(data)
        try await bookedSlotRef.setData(bookedSlotData)

        return documentRef.documentID
    }
    
    func fetchBookedTimeStrings(
        providerId: String,
        date: Date
    ) async throws -> Set<String> {
        guard Auth.auth().currentUser != nil else {
            throw ReservationRepositoryError.userNotFound
        }

        let trimmedProviderId = providerId.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedProviderId.isEmpty else {
            throw ReservationRepositoryError.invalidProvider
        }

        let dateKey = bookedSlotDateKey(from: date)

        let snapshot = try await db
            .collection(bookedSlotsCollectionName)
            .document(trimmedProviderId)
            .collection("dates")
            .document(dateKey)
            .collection("times")
            .getDocuments()

        let bookedTimes = snapshot.documents.compactMap { document -> String? in
            let data = document.data()

            guard
                let timeString = data["timeString"] as? String,
                let statusRawValue = data["status"] as? String
            else {
                return nil
            }

            guard
                statusRawValue == ReservationStatus.pending.rawValue ||
                statusRawValue == ReservationStatus.accepted.rawValue
            else {
                return nil
            }

            return timeString
        }

        return Set(bookedTimes)
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
    
    func fetchReservationsForProvider(
        providerId: String
    ) async throws -> [Reservation] {
        guard Auth.auth().currentUser != nil else {
            throw ReservationRepositoryError.userNotFound
        }

        let trimmedProviderId = providerId.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedProviderId.isEmpty else {
            throw ReservationRepositoryError.invalidProvider
        }

        let snapshot = try await db
            .collection(collectionName)
            .whereField("providerId", isEqualTo: trimmedProviderId)
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

        try await updateReservationAndBookedSlotStatus(
            reservationId: trimmedReservationId,
            status: .cancelled
        )
    }
    
    func updateReservationStatus(
        reservationId: String,
        status: ReservationStatus
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

        guard status == .accepted || status == .rejected else {
            throw ReservationRepositoryError.invalidReservation
        }

        try await updateReservationAndBookedSlotStatus(
            reservationId: trimmedReservationId,
            status: status
        )
    }
    
    private func updateReservationAndBookedSlotStatus(
        reservationId: String,
        status: ReservationStatus
    ) async throws {
        let reservationRef = db
            .collection(collectionName)
            .document(reservationId)

        let snapshot = try await reservationRef.getDocument()

        guard
            let data = snapshot.data(),
            let providerId = data["providerId"] as? String,
            let reservationDateTimestamp = data["reservationDate"] as? Timestamp
        else {
            throw ReservationRepositoryError.invalidReservation
        }

        let reservationDate = reservationDateTimestamp.dateValue()
        let now = Date()
        let dateKey = bookedSlotDateKey(from: reservationDate)
        let timeString = bookedSlotTimeString(from: reservationDate)
        let timeKey = timeString.replacingOccurrences(of: ":", with: "")

        let bookedSlotRef = db
            .collection(bookedSlotsCollectionName)
            .document(providerId)
            .collection("dates")
            .document(dateKey)
            .collection("times")
            .document(timeKey)

        let batch = db.batch()

        batch.updateData([
            "status": status.rawValue,
            "updatedAt": Timestamp(date: now)
        ], forDocument: reservationRef)

        // Keep slot status in sync with reservation status.
        batch.setData([
            "providerId": providerId,
            "dateKey": dateKey,
            "timeString": timeString,
            "status": status.rawValue,
            "reservationId": reservationId,
            "updatedAt": Timestamp(date: now)
        ], forDocument: bookedSlotRef, merge: true)

        try await batch.commit()
    }

    private func bookedSlotDateKey(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: date)
    }

    private func bookedSlotTimeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
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
        let addressText = data["addressText"] as? String ?? ""

        return Reservation(
            reservationId: reservationId,
            serviceId: serviceId,
            serviceTitle: serviceTitle,
            providerId: providerId,
            providerName: providerName,
            customerId: customerId,
            customerName: customerName,
            reservationDate: reservationDateTimestamp.dateValue(),
            addressText: addressText,
            note: note,
            status: status,
            createdAt: createdAtTimestamp.dateValue(),
            updatedAt: updatedAtTimestamp.dateValue()
        )
    }
}
