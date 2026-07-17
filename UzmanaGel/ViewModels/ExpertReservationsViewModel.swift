//
//  ExpertReservationsViewModel.swift
//  UzmanaGel
//
//  Created by Halil Keremoğlu on 13.07.2026.
//

import Foundation
import Combine

@MainActor
final class ExpertReservationsViewModel: ObservableObject {

    @Published var reservations: [Reservation] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    @Published var updatingReservationId: String?

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
            reservations = try await repository.fetchProviderReservations()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func acceptReservation(_ reservation: Reservation) async {
        await updateReservationStatus(
            reservation,
            status: .accepted
        )
    }

    func rejectReservation(
        _ reservation: Reservation,
        reason: String
    ) async {
        await updateReservationStatus(
            reservation,
            status: .rejected,
            rejectionReason: reason
        )
    }

    private func updateReservationStatus(
        _ reservation: Reservation,
        status: ReservationStatus,
        rejectionReason: String? = nil
    ) async {
        guard updatingReservationId == nil else { return }

        updatingReservationId = reservation.reservationId
        errorMessage = ""
        showError = false

        defer {
            updatingReservationId = nil
        }

        do {
            try await repository.updateReservationStatus(
                reservationId: reservation.reservationId,
                status: status,
                rejectionReason: rejectionReason
            )

            reservations = try await repository.fetchProviderReservations()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
