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
}
