//
//  ReservationViewModel.swift
//  UzmanaGel
//
//  Created by Halil Keremoğlu on 13.07.2026.
//

import Foundation
import FirebaseAuth
import Combine

@MainActor
final class ReservationViewModel: ObservableObject {

    @Published var reservationDate: Date = ReservationViewModel.defaultReservationDate()
    @Published var selectedTimeString = "09:00"
    @Published var note = ""
    @Published var isSubmitting = false
    @Published var errorMessage = ""
    @Published var showError = false
    @Published var isSuccess = false

    let availableTimeSlots = [
        "09:00",
        "10:00",
        "11:00",
        "12:00",
        "13:00",
        "14:00",
        "15:00",
        "16:00",
        "17:00",
        "18:00"
    ]

    private let repository = ReservationRepository()

    func setSelectedDate(_ date: Date) {
        reservationDate = dateWithSelectedTime(date)
    }

    func setSelectedTime(_ timeString: String) {
        selectedTimeString = timeString
        reservationDate = dateWithSelectedTime(reservationDate)
    }

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

        let finalReservationDate = dateWithSelectedTime(reservationDate)

        guard finalReservationDate > Date() else {
            errorMessage = "Geçmiş bir tarih veya saat seçemezsiniz."
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
                reservationDate: finalReservationDate,
                note: note
            )

            note = ""
            reservationDate = Self.defaultReservationDate()
            selectedTimeString = "09:00"
            isSuccess = true

        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func dateWithSelectedTime(_ date: Date) -> Date {
        let parts = selectedTimeString
            .split(separator: ":")
            .compactMap { Int($0) }

        guard parts.count == 2 else {
            return date
        }

        var components = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: date
        )

        components.hour = parts[0]
        components.minute = parts[1]
        components.second = 0

        return Calendar.current.date(from: components) ?? date
    }

    private static func defaultReservationDate() -> Date {
        let tomorrow = Calendar.current.date(
            byAdding: .day,
            value: 1,
            to: Date()
        ) ?? Date()

        var components = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: tomorrow
        )

        components.hour = 9
        components.minute = 0
        components.second = 0

        return Calendar.current.date(from: components) ?? tomorrow
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
