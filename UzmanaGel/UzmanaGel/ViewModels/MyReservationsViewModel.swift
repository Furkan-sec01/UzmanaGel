//
//  MyReservationsViewModel.swift
//  UzmanaGel
//
//  Created by Halil Keremoğlu on 13.07.2026.
//

//        Rezervasyonlarım sayfası açılınca
//        ↓
//        ReservationRepository.fetchMyReservations()
//        ↓
//        Firestore'dan kullanıcının kendi rezervasyonlarını çeker
//        ↓
//        ekrana liste olarak verir --> Yani bu ViewModel direkt Firestore’a yazmaz. Sadece kullanıcının kendi rezervasyonlarını yükler.

import Foundation
import Combine

@MainActor
final class MyReservationsViewModel: ObservableObject {

    @Published var reservations: [Reservation] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    @Published var reservationToCancel: Reservation?
    @Published var showCancelConfirmation = false
    @Published var isCancelling = false
    
    private let repository = ReservationRepository()
    

    func loadReservations() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = ""
        showError = false

        defer {
            isLoading = false
        }

        do {
            reservations = try await repository.fetchMyReservations()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func requestCancel(
        _ reservation: Reservation
    ) {
        reservationToCancel = reservation
        showCancelConfirmation = true
    }

    func cancelSelectedReservation() async {
        guard !isCancelling else { return }
        guard let reservation = reservationToCancel else { return }

        isCancelling = true
        errorMessage = ""
        showError = false

        defer {
            isCancelling = false
        }

        do {
            try await repository.cancelReservation(
                reservationId: reservation.reservationId
            )

            reservations = try await repository.fetchMyReservations()
            reservationToCancel = nil
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
