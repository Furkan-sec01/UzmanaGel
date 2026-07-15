import Foundation
import Combine
import SwiftUI

@MainActor
class ScheduleViewModel: ObservableObject {
    @Published var availabilitySlots: [AvailabilitySlot] = []
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
    
    init(scheduleService: ScheduleService = MockScheduleService()) {
        self.scheduleService = scheduleService
    }
    
    func loadAvailability() async {
        isLoading = true
        errorMessage = nil
        do {
            self.availabilitySlots = try await scheduleService.fetchAvailability()
            
            // Build 30 days grid of mock availability if empty
            if availabilitySlots.isEmpty {
                generate30DaysMock()
            }
        } catch {
            self.errorMessage = error.localizedDescription
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
    
    // Batch Update action
    func applyBatchAvailability() async {
        isLoading = true
        do {
            var updated = availabilitySlots
            let calendar = Calendar.current
            
            for index in 0..<updated.count {
                let date = updated[index].date
                if date >= batchStartDate && date <= batchEndDate {
                    updated[index].isAvailable = batchIsAvailable
                }
            }
            try await scheduleService.saveAvailability(slots: updated)
            self.availabilitySlots = updated
            successMessage = "Toplu müsaitlik güncellendi."
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    // Save Recurring Working Hours Settings
    func saveRecurringSettings() {
        successMessage = "Tekrarlayan çalışma saatleri kaydedildi."
    }
    
    // Check Day Status for Coloring
    func getDayColor(for date: Date) -> Color {
        guard let slot = availabilitySlots.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) else {
            return Color.themeBorder // Default neutral grey
        }
        
        if !slot.isAvailable {
            return Color.themeError // Red (Closed/Unavailable)
        }
        
        let bookedCount = slot.timeSlots.filter { $0.isBooked }.count
        let totalCount = slot.timeSlots.count
        
        if bookedCount == 0 {
            return Color.themeSuccess // Green (Fully Available)
        } else if bookedCount < totalCount {
            return Color.themeWarning // Yellow (Partially Booked)
        } else {
            return Color.themeError // Red (Fully Booked)
        }
    }
    
    private func generate30DaysMock() {
        var generated: [AvailabilitySlot] = []
        let calendar = Calendar.current
        for i in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: i, to: Date()) {
                let weekday = calendar.component(.weekday, from: date)
                let isAvail = weekday != 1 // Closed on Sundays
                
                generated.append(
                    AvailabilitySlot(
                        id: "slot_mock_\(i)",
                        date: date,
                        timeSlots: [
                            .init(timeString: "09:00", isBooked: i % 7 == 0),
                            .init(timeString: "11:00", isBooked: i % 5 == 0),
                            .init(timeString: "14:00", isBooked: false),
                            .init(timeString: "16:00", isBooked: i % 3 == 0)
                        ],
                        isAvailable: isAvail
                    )
                )
            }
        }
        self.availabilitySlots = generated
    }
}
