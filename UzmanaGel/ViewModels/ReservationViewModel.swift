//
//  ReservationViewModel.swift
//  UzmanaGel
//
//  Created by Halil Keremoğlu on 13.07.2026.
//

import Foundation
import FirebaseAuth
import Combine

enum ReservationTimeSelectionHelper {

    static func resolvedTime(
        currentTime: String,
        availableTimeSlots: [String],
        bookedTimeStrings: Set<String>
    ) -> String {
        guard bookedTimeStrings.contains(currentTime) else {
            return currentTime
        }

        return availableTimeSlots.first {
            !bookedTimeStrings.contains($0)
        } ?? currentTime
    }

    static func applying(
        timeString: String,
        to date: Date,
        calendar: Calendar = .current
    ) -> Date {
        let parts = timeString
            .split(separator: ":")
            .compactMap { Int($0) }

        guard parts.count == 2 else {
            return date
        }

        var components = calendar.dateComponents(
            [.year, .month, .day],
            from: date
        )

        components.hour = parts[0]
        components.minute = parts[1]
        components.second = 0

        return calendar.date(from: components) ?? date
    }
}

enum ReservationFormValidationError: Equatable {
    case bookedSlotsUnavailable
    case selectedTimeBooked
    case customerNameMissing
    case addressMissing
    case reservationDateNotFuture

    var message: String {
        switch self {
        case .bookedSlotsUnavailable:
            return "Dolu saatler kontrol edilemediği için rezervasyon oluşturulamadı."

        case .selectedTimeBooked:
            return "Seçtiğiniz saat dolu. Lütfen başka bir saat seçin."

        case .customerNameMissing:
            return "Kullanıcı adı bulunamadı."

        case .addressMissing:
            return "Adres bilgisi boş bırakılamaz."

        case .reservationDateNotFuture:
            return "Geçmiş bir tarih veya saat seçemezsiniz."
        }
    }
}

enum ReservationFormValidator {

    static func validate(
        bookedSlotsLoaded: Bool,
        selectedTime: String,
        bookedTimeStrings: Set<String>,
        customerName: String,
        addressText: String,
        reservationDate: Date,
        now: Date = Date()
    ) -> ReservationFormValidationError? {
        guard bookedSlotsLoaded else {
            return .bookedSlotsUnavailable
        }

        guard !bookedTimeStrings.contains(selectedTime) else {
            return .selectedTimeBooked
        }

        guard !customerName.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty else {
            return .customerNameMissing
        }

        guard !addressText.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty else {
            return .addressMissing
        }

        guard reservationDate > now else {
            return .reservationDateNotFuture
        }

        return nil
    }
}

@MainActor
final class ReservationViewModel: ObservableObject {

    @Published var reservationDate: Date = ReservationViewModel.defaultReservationDate()
    @Published var selectedTimeString = "09:00"
    @Published var addressText = ""
    @Published var note = ""
    @Published var bookedTimeStrings: Set<String> = []
    @Published var didLoadBookedSlots = false
    @Published var isLoadingBookedSlots = false
    @Published var isSubmitting = false
    @Published var errorMessage = ""
    @Published var showError = false
    @Published var isSuccess = false
    @Published var createdReservationId = ""

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

    func loadBookedSlots(providerId: String) async {
        isLoadingBookedSlots = true
        didLoadBookedSlots = false

        defer {
            isLoadingBookedSlots = false
        }

        do {
            bookedTimeStrings = try await repository.fetchBookedTimeStrings(
                providerId: providerId,
                date: reservationDate
            )

            didLoadBookedSlots = true

            let resolvedTime =
                ReservationTimeSelectionHelper.resolvedTime(
                    currentTime: selectedTimeString,
                    availableTimeSlots: availableTimeSlots,
                    bookedTimeStrings: bookedTimeStrings
                )

            if resolvedTime != selectedTimeString {
                selectedTimeString = resolvedTime
                reservationDate = dateWithSelectedTime(reservationDate)
            }

        } catch {
            bookedTimeStrings = []
            didLoadBookedSlots = false
            errorMessage = "Dolu saatler kontrol edilemedi. Lütfen tekrar deneyin."
            showError = true
        }
    }

    func setSelectedDate(_ date: Date, providerId: String) async {
        reservationDate = dateWithSelectedTime(date)
        await loadBookedSlots(providerId: providerId)
    }

    func setSelectedTime(_ timeString: String) {
        selectedTimeString = timeString
        reservationDate = dateWithSelectedTime(reservationDate)
    }

    func isBooked(_ timeString: String) -> Bool {
        bookedTimeStrings.contains(timeString)
    }

    func createReservation(
        serviceId: String,
        serviceTitle: String,
        servicePrice: Int,
        serviceDuration: String,
        providerId: String,
        providerName: String
    ) async {
        guard !isSubmitting else { return }

        await loadBookedSlots(providerId: providerId)

        guard didLoadBookedSlots else {
            errorMessage = "Dolu saatler kontrol edilemediği için rezervasyon oluşturulamadı."
            showError = true
            return
        }

        guard !bookedTimeStrings.contains(selectedTimeString) else {
            errorMessage = "Seçtiğiniz saat dolu. Lütfen başka bir saat seçin."
            showError = true
            return
        }

        let customerName = getCurrentCustomerName()

        guard !customerName.isEmpty else {
            errorMessage = "Kullanıcı adı bulunamadı."
            showError = true
            return
        }

        let trimmedAddressText = addressText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedAddressText.isEmpty else {
            errorMessage = "Adres bilgisi boş bırakılamaz."
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
        createdReservationId = ""

        defer {
            isSubmitting = false
        }

        do {
            let reservationId = try await repository.createReservation(
                serviceId: serviceId,
                serviceTitle: serviceTitle,
                servicePrice: servicePrice,
                serviceDuration: serviceDuration,
                providerId: providerId,
                providerName: providerName,
                customerName: customerName,
                reservationDate: finalReservationDate,
                addressText: trimmedAddressText,
                note: note
            )

            note = ""
            reservationDate = Self.defaultReservationDate()
            selectedTimeString = "09:00"
            bookedTimeStrings = []
            createdReservationId = reservationId
            isSuccess = true

        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func isBlockingStatus(_ status: ReservationStatus) -> Bool {
        status == .pending || status == .accepted
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func dateWithSelectedTime(_ date: Date) -> Date {
        ReservationTimeSelectionHelper.applying(
            timeString: selectedTimeString,
            to: date
        )
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
