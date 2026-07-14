//
//  ReservationViewModel.swift
//  UzmanaGel
//
//  Created by Halil Keremoğlu on 13.07.2026.
//
//Tarih seçimini tutar
//Not alanını tutar
//Repository üzerinden Firestore'a reservation kaydı gönderir
//Başarı / hata durumunu ekrana bildirir

import Foundation
import FirebaseAuth
import Combine

@MainActor
final class ReservationViewModel: ObservableObject {

    @Published var reservationDate: Date = Calendar.current.date(
        byAdding: .day,
        value: 1,
        to: Date()
    ) ?? Date()

    @Published var note = ""
    @Published var isSubmitting = false
    @Published var errorMessage = ""
    @Published var showError = false
    @Published var isSuccess = false

    private let repository = ReservationRepository()

    func createReservation(
        serviceId: String,
        serviceTitle: String,
        providerId: String,
        providerName: String
    ) async {
        guard !isSubmitting else { return }

        let customerName = getCurrentCustomerName()

        guard !customerName.isEmpty else {
            errorMessage = "Kullanıcı adı bulunamadı."
            showError = true
            return
        }

        isSubmitting = true
        errorMessage = ""
        showError = false
        isSuccess = false

        defer {
            isSubmitting = false
        }

        do {
            _ = try await repository.createReservation(
                serviceId: serviceId,
                serviceTitle: serviceTitle,
                providerId: providerId,
                providerName: providerName,
                customerName: customerName,
                reservationDate: reservationDate,
                note: note
            )

            note = ""
            isSuccess = true

        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func getCurrentCustomerName() -> String {
        guard let user = Auth.auth().currentUser else {
            return ""
        }

        let displayName = user.displayName?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if !displayName.isEmpty {
            return displayName
        }

        let email = user.email?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        return email
    }
}
