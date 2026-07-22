import Foundation
import Combine
import SwiftUI

@MainActor
class ScheduleViewModel: ObservableObject {
    @Published var availabilitySlots: [AvailabilitySlot] = []
    @Published var providerReservations: [Reservation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    // Batch settings properties
    @Published var batchStartDate = Date()
    @Published var batchEndDate = Date().addingTimeInterval(86400 * 7)
    @Published var batchIsAvailable = true

    // Recurring Working Hours Setup
    @Published var recurringStartHour = "09:00"
    @Published var recurringEndHour = "18:00"
    @Published var recurringWorkingDays: Set<Int> = [1, 2, 3, 4, 5] // Mon-Fri

    private let scheduleService: ScheduleService
    private let reservationRepository: ReservationRepository

    init(
        scheduleService: ScheduleService = MockScheduleService(),
        reservationRepository: ReservationRepository = ReservationRepository()
    ) {
        self.scheduleService = scheduleService
        self.reservationRepository = reservationRepository
    }

    func loadAvailability() async {
        isLoading = true
        errorMessage = nil

        do {
            let fetchedSlots = try await scheduleService.fetchAvailability()
            let fetchedReservations = try await reservationRepository.fetchProviderReservations()

            providerReservations = fetchedReservations

            if fetchedSlots.isEmpty {
                generate30DaysMock()
            } else {
                availabilitySlots = fetchedSlots
            }

            applyReservationsToAvailability()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func toggleSlotBooking(slotId: String, timeString: String) {
        if let idx = availabilitySlots.firstIndex(where: { $0.id == slotId }) {
            if let tIdx = availabilitySlots[idx].timeSlots.firstIndex(where: { $0.timeString == timeString }) {
                availabilitySlots[idx].timeSlots[tIdx].isBooked.toggle()
                successMessage = "Randevu durumu güncellendi."
            }
        }
    }

    func toggleDayAvailability(slotId: String) async {
        if let idx = availabilitySlots.firstIndex(where: { $0.id == slotId }) {
            let nextState = !availabilitySlots[idx].isAvailable

            do {
                try await scheduleService.updateSlotAvailability(slotId: slotId, isAvailable: nextState)
                availabilitySlots[idx].isAvailable = nextState
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func applyBatchAvailability() async {
        isLoading = true

        do {
            var updated = availabilitySlots

            for index in 0..<updated.count {
                let date = updated[index].date

                if date >= batchStartDate && date <= batchEndDate {
                    updated[index].isAvailable = batchIsAvailable
                }
            }

            try await scheduleService.saveAvailability(slots: updated)
            availabilitySlots = updated
            applyReservationsToAvailability()
            successMessage = "Toplu müsaitlik güncellendi."
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func saveRecurringSettings() {
        successMessage = "Tekrarlayan çalışma saatleri kaydedildi."
    }

    func getDayColor(for date: Date) -> Color {
        guard let slot = availabilitySlots.first(where: {
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }) else {
            return Color.themeBorder
        }

        if !slot.isAvailable {
            return Color.themeError
        }

        let bookedCount = slot.timeSlots.filter { $0.isBooked }.count
        let totalCount = slot.timeSlots.count

        if bookedCount == 0 {
            return Color.themeSuccess
        } else if bookedCount < totalCount {
            return Color.themeWarning
        } else {
            return Color.themeError
        }
    }

    func reservations(for date: Date) -> [Reservation] {
        providerReservations
            .filter {
                Calendar.current.isDate($0.reservationDate, inSameDayAs: date)
            }
            .sorted {
                $0.reservationDate < $1.reservationDate
            }
    }

    func statusColor(for status: ReservationStatus) -> Color {
        switch status {
        case .pending:
            return .orange
        case .accepted:
            return .green
        case .inProgress:
            return .blue
        case .completed:
            return .blue
        case .rejected:
            return .red
        case .cancelled:
            return .gray
        case .noShow:
            return .gray
        }
    }

    private func applyReservationsToAvailability() {
        for reservation in providerReservations where isBlockingStatus(reservation.status) {
            let reservationDate = reservation.reservationDate
            let timeString = timeFormatter.string(from: reservationDate)

            if let dayIndex = availabilitySlots.firstIndex(where: {
                Calendar.current.isDate($0.date, inSameDayAs: reservationDate)
            }) {
                if let timeIndex = availabilitySlots[dayIndex].timeSlots.firstIndex(where: {
                    $0.timeString == timeString
                }) {
                    availabilitySlots[dayIndex].timeSlots[timeIndex].isBooked = true
                } else {
                    availabilitySlots[dayIndex].timeSlots.append(
                        .init(timeString: timeString, isBooked: true)
                    )

                    availabilitySlots[dayIndex].timeSlots.sort {
                        $0.timeString < $1.timeString
                    }
                }
            } else {
                availabilitySlots.append(
                    AvailabilitySlot(
                        id: "reservation_\(reservation.reservationId)",
                        date: reservationDate,
                        timeSlots: [
                            .init(timeString: timeString, isBooked: true)
                        ],
                        isAvailable: true
                    )
                )
            }
        }

        availabilitySlots.sort {
            $0.date < $1.date
        }
    }

    private func isBlockingStatus(_ status: ReservationStatus) -> Bool {
        status.isBlockingSlot
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "HH:mm"
        return formatter
    }

    private func generate30DaysMock() {
        var generated: [AvailabilitySlot] = []
        let calendar = Calendar.current

        for i in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: i, to: Date()) {
                let weekday = calendar.component(.weekday, from: date)
                let isAvail = weekday != 1

                generated.append(
                    AvailabilitySlot(
                        id: "slot_mock_\(i)",
                        date: date,
                        timeSlots: [
                            .init(timeString: "09:00", isBooked: false),
                            .init(timeString: "11:00", isBooked: false),
                            .init(timeString: "14:00", isBooked: false),
                            .init(timeString: "16:00", isBooked: false)
                        ],
                        isAvailable: isAvail
                    )
                )
            }
        }

        availabilitySlots = generated
    }
}
