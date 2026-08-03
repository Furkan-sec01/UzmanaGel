import Foundation
import Testing
@testable import UzmanaGel

@Suite("NotificationSettings Tests")
struct NotificationSettingsTests {

    @Test("Settings encode and decode correctly")
    func settingsEncodeAndDecodeCorrectly() throws {
        let settings = NotificationSettings(
            pushNotificationsEnabled: true,
            emailNotificationsEnabled: false,
            smsNotificationsEnabled: true,
            messageNotificationsEnabled: false,
            systemNotificationsEnabled: true,
            bookingNotificationsEnabled: false,
            marketingNotificationsEnabled: true,
            promoNotificationsEnabled: true
        )

        let data = try JSONEncoder().encode(settings)
        let decodedSettings = try JSONDecoder().decode(
            NotificationSettings.self,
            from: data
        )

        #expect(decodedSettings == settings)
    }

    @Test("Notification categories remain independent")
    func notificationCategoriesRemainIndependent() {
        let settings = NotificationSettings(
            pushNotificationsEnabled: true,
            emailNotificationsEnabled: false,
            smsNotificationsEnabled: true,
            messageNotificationsEnabled: false,
            systemNotificationsEnabled: true,
            bookingNotificationsEnabled: false,
            marketingNotificationsEnabled: true,
            promoNotificationsEnabled: true
        )

        #expect(settings.emailNotificationsEnabled == false)
        #expect(settings.smsNotificationsEnabled == true)
        #expect(settings.messageNotificationsEnabled == false)
        #expect(settings.systemNotificationsEnabled == true)
        #expect(settings.bookingNotificationsEnabled == false)
        #expect(settings.marketingNotificationsEnabled == true)
    }
}
@Suite("Notification Preference Resolver Tests")
struct NotificationPreferenceResolverTests {

    @Test("Stored value has highest priority")
    func storedValueHasHighestPriority() {
        let result = NotificationPreferenceResolver.resolve(
            localValue: false,
            storedValue: true,
            legacyValue: false,
            defaultValue: false
        )

        #expect(result == true)
    }

    @Test("Local value is used when stored value is missing")
    func localValueIsUsedWhenStoredValueIsMissing() {
        let result = NotificationPreferenceResolver.resolve(
            localValue: false,
            storedValue: nil,
            legacyValue: true,
            defaultValue: true
        )

        #expect(result == false)
    }

    @Test("Legacy value is used during migration")
    func legacyValueIsUsedDuringMigration() {
        let result = NotificationPreferenceResolver.resolve(
            localValue: nil,
            storedValue: nil,
            legacyValue: true,
            defaultValue: false
        )

        #expect(result == true)
    }

    @Test("Default value is used when all values are missing")
    func defaultValueIsUsedWhenAllValuesAreMissing() {
        let result = NotificationPreferenceResolver.resolve(
            localValue: nil,
            storedValue: nil,
            legacyValue: nil,
            defaultValue: false
        )

        #expect(result == false)
    }
}
@Suite("Reservation Slot Key Builder Tests")
struct ReservationSlotKeyBuilderTests {

    @Test("Builds date and time keys correctly")
    func buildsDateAndTimeKeysCorrectly() {
        let timeZone = TimeZone(secondsFromGMT: 0)!

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let date = calendar.date(
            from: DateComponents(
                year: 2026,
                month: 8,
                day: 3,
                hour: 13,
                minute: 45
            )
        )!

        let result = ReservationSlotKeyBuilder.build(
            from: date,
            timeZone: timeZone
        )

        #expect(result.dateKey == "20260803")
        #expect(result.timeString == "13:45")
        #expect(result.timeKey == "1345")
    }

    @Test("Uses the provided time zone")
    func usesProvidedTimeZone() {
        let utc = TimeZone(secondsFromGMT: 0)!
        let istanbul = TimeZone(identifier: "Europe/Istanbul")!

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = utc

        let date = calendar.date(
            from: DateComponents(
                year: 2026,
                month: 8,
                day: 3,
                hour: 22,
                minute: 30
            )
        )!

        let result = ReservationSlotKeyBuilder.build(
            from: date,
            timeZone: istanbul
        )

        #expect(result.dateKey == "20260804")
        #expect(result.timeString == "01:30")
        #expect(result.timeKey == "0130")
    }

    @Test("Preserves leading zeros in time key")
    func preservesLeadingZerosInTimeKey() {
        let timeZone = TimeZone(secondsFromGMT: 0)!

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let date = calendar.date(
            from: DateComponents(
                year: 2026,
                month: 8,
                day: 3,
                hour: 0,
                minute: 5
            )
        )!

        let result = ReservationSlotKeyBuilder.build(
            from: date,
            timeZone: timeZone
        )

        #expect(result.timeString == "00:05")
        #expect(result.timeKey == "0005")
    }
}

@Suite("Reservation Status Tests")
struct ReservationStatusTests {

    @Test("Pending supports only valid transitions")
    func pendingSupportsOnlyValidTransitions() {
        #expect(ReservationStatus.pending.canTransition(to: .accepted))
        #expect(ReservationStatus.pending.canTransition(to: .rejected))
        #expect(ReservationStatus.pending.canTransition(to: .cancelled))

        #expect(!ReservationStatus.pending.canTransition(to: .inProgress))
        #expect(!ReservationStatus.pending.canTransition(to: .completed))
        #expect(!ReservationStatus.pending.canTransition(to: .noShow))
    }

    @Test("Accepted supports only valid transitions")
    func acceptedSupportsOnlyValidTransitions() {
        #expect(ReservationStatus.accepted.canTransition(to: .inProgress))
        #expect(ReservationStatus.accepted.canTransition(to: .noShow))
        #expect(ReservationStatus.accepted.canTransition(to: .cancelled))

        #expect(!ReservationStatus.accepted.canTransition(to: .pending))
        #expect(!ReservationStatus.accepted.canTransition(to: .completed))
        #expect(!ReservationStatus.accepted.canTransition(to: .rejected))
    }

    @Test("In progress can only become completed")
    func inProgressCanOnlyBecomeCompleted() {
        #expect(ReservationStatus.inProgress.canTransition(to: .completed))

        #expect(!ReservationStatus.inProgress.canTransition(to: .pending))
        #expect(!ReservationStatus.inProgress.canTransition(to: .accepted))
        #expect(!ReservationStatus.inProgress.canTransition(to: .cancelled))
    }

    @Test("Terminal statuses cannot transition")
    func terminalStatusesCannotTransition() {
        let terminalStatuses: [ReservationStatus] = [
            .completed,
            .rejected,
            .cancelled,
            .noShow
        ]

        for currentStatus in terminalStatuses {
            for newStatus in ReservationStatus.allCases {
                #expect(!currentStatus.canTransition(to: newStatus))
            }
        }
    }

    @Test("Cancelled and rejected reservations release the slot")
    func cancelledAndRejectedReservationsReleaseSlot() {
        #expect(!ReservationStatus.cancelled.isBlockingSlot)
        #expect(!ReservationStatus.rejected.isBlockingSlot)

        #expect(ReservationStatus.pending.isBlockingSlot)
        #expect(ReservationStatus.accepted.isBlockingSlot)
        #expect(ReservationStatus.inProgress.isBlockingSlot)
        #expect(ReservationStatus.completed.isBlockingSlot)
        #expect(ReservationStatus.noShow.isBlockingSlot)
    }
}

@Suite("Reservation Time Selection Tests")
struct ReservationTimeSelectionTests {

    @Test("Keeps current time when it is available")
    func keepsCurrentTimeWhenAvailable() {
        let result = ReservationTimeSelectionHelper.resolvedTime(
            currentTime: "11:00",
            availableTimeSlots: ["09:00", "10:00", "11:00"],
            bookedTimeStrings: ["09:00", "10:00"]
        )

        #expect(result == "11:00")
    }

    @Test("Selects first available time when current time is booked")
    func selectsFirstAvailableTime() {
        let result = ReservationTimeSelectionHelper.resolvedTime(
            currentTime: "09:00",
            availableTimeSlots: [
                "09:00",
                "10:00",
                "11:00",
                "12:00"
            ],
            bookedTimeStrings: ["09:00", "10:00"]
        )

        #expect(result == "11:00")
    }

    @Test("Keeps current time when all slots are booked")
    func keepsCurrentTimeWhenAllSlotsAreBooked() {
        let result = ReservationTimeSelectionHelper.resolvedTime(
            currentTime: "09:00",
            availableTimeSlots: ["09:00", "10:00"],
            bookedTimeStrings: ["09:00", "10:00"]
        )

        #expect(result == "09:00")
    }

    @Test("Applies selected time to the given date")
    func appliesSelectedTimeToDate() {
        let timeZone = TimeZone(secondsFromGMT: 0)!

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let date = calendar.date(
            from: DateComponents(
                year: 2026,
                month: 8,
                day: 3,
                hour: 7,
                minute: 20
            )
        )!

        let result = ReservationTimeSelectionHelper.applying(
            timeString: "14:45",
            to: date,
            calendar: calendar
        )

        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: result
        )

        #expect(components.year == 2026)
        #expect(components.month == 8)
        #expect(components.day == 3)
        #expect(components.hour == 14)
        #expect(components.minute == 45)
        #expect(components.second == 0)
    }

    @Test("Returns original date for invalid time")
    func returnsOriginalDateForInvalidTime() {
        let date = Date(timeIntervalSince1970: 1_786_000_000)

        let result = ReservationTimeSelectionHelper.applying(
            timeString: "invalid",
            to: date
        )

        #expect(result == date)
    }
}

@Suite("Reservation Form Validation Tests")
struct ReservationFormValidationTests {

    private let now = Date(timeIntervalSince1970: 1_786_000_000)

    @Test("Fails when booked slots could not be loaded")
    func failsWhenBookedSlotsCouldNotBeLoaded() {
        let result = ReservationFormValidator.validate(
            bookedSlotsLoaded: false,
            selectedTime: "09:00",
            bookedTimeStrings: [],
            customerName: "Halil",
            addressText: "Bursa",
            reservationDate: now.addingTimeInterval(3_600),
            now: now
        )

        #expect(result == .bookedSlotsUnavailable)
    }

    @Test("Fails when selected time is booked")
    func failsWhenSelectedTimeIsBooked() {
        let result = ReservationFormValidator.validate(
            bookedSlotsLoaded: true,
            selectedTime: "09:00",
            bookedTimeStrings: ["09:00"],
            customerName: "Halil",
            addressText: "Bursa",
            reservationDate: now.addingTimeInterval(3_600),
            now: now
        )

        #expect(result == .selectedTimeBooked)
    }

    @Test("Fails when customer name is empty")
    func failsWhenCustomerNameIsEmpty() {
        let result = ReservationFormValidator.validate(
            bookedSlotsLoaded: true,
            selectedTime: "09:00",
            bookedTimeStrings: [],
            customerName: "   ",
            addressText: "Bursa",
            reservationDate: now.addingTimeInterval(3_600),
            now: now
        )

        #expect(result == .customerNameMissing)
    }

    @Test("Fails when address is empty")
    func failsWhenAddressIsEmpty() {
        let result = ReservationFormValidator.validate(
            bookedSlotsLoaded: true,
            selectedTime: "09:00",
            bookedTimeStrings: [],
            customerName: "Halil",
            addressText: "   ",
            reservationDate: now.addingTimeInterval(3_600),
            now: now
        )

        #expect(result == .addressMissing)
    }

    @Test("Fails when reservation date is not in the future")
    func failsWhenReservationDateIsNotFuture() {
        let result = ReservationFormValidator.validate(
            bookedSlotsLoaded: true,
            selectedTime: "09:00",
            bookedTimeStrings: [],
            customerName: "Halil",
            addressText: "Bursa",
            reservationDate: now,
            now: now
        )

        #expect(result == .reservationDateNotFuture)
    }

    @Test("Succeeds when reservation form is valid")
    func succeedsWhenReservationFormIsValid() {
        let result = ReservationFormValidator.validate(
            bookedSlotsLoaded: true,
            selectedTime: "09:00",
            bookedTimeStrings: ["10:00"],
            customerName: " Halil ",
            addressText: " Bursa ",
            reservationDate: now.addingTimeInterval(3_600),
            now: now
        )

        #expect(result == nil)
    }
}

@Suite("Reservation Validation Priority Tests")
struct ReservationValidationPriorityTests {

    private let now = Date(timeIntervalSince1970: 1_786_000_000)

    @Test("Booked slot loading error has first priority")
    func bookedSlotLoadingErrorHasFirstPriority() {
        let result = ReservationFormValidator.validate(
            bookedSlotsLoaded: false,
            selectedTime: "09:00",
            bookedTimeStrings: ["09:00"],
            customerName: "",
            addressText: "",
            reservationDate: now,
            now: now
        )

        #expect(result == .bookedSlotsUnavailable)
    }

    @Test("Booked time error is checked before form fields")
    func bookedTimeErrorIsCheckedBeforeFormFields() {
        let result = ReservationFormValidator.validate(
            bookedSlotsLoaded: true,
            selectedTime: "09:00",
            bookedTimeStrings: ["09:00"],
            customerName: "",
            addressText: "",
            reservationDate: now,
            now: now
        )

        #expect(result == .selectedTimeBooked)
    }

    @Test("Customer name is checked before address and date")
    func customerNameIsCheckedBeforeAddressAndDate() {
        let result = ReservationFormValidator.validate(
            bookedSlotsLoaded: true,
            selectedTime: "09:00",
            bookedTimeStrings: [],
            customerName: "   ",
            addressText: "   ",
            reservationDate: now,
            now: now
        )

        #expect(result == .customerNameMissing)
    }

    @Test("Validation errors contain correct user messages")
    func validationErrorsContainCorrectMessages() {
        #expect(
            ReservationFormValidationError.bookedSlotsUnavailable.message ==
            "Dolu saatler kontrol edilemediği için rezervasyon oluşturulamadı."
        )

        #expect(
            ReservationFormValidationError.selectedTimeBooked.message ==
            "Seçtiğiniz saat dolu. Lütfen başka bir saat seçin."
        )

        #expect(
            ReservationFormValidationError.customerNameMissing.message ==
            "Kullanıcı adı bulunamadı."
        )

        #expect(
            ReservationFormValidationError.addressMissing.message ==
            "Adres bilgisi boş bırakılamaz."
        )

        #expect(
            ReservationFormValidationError.reservationDateNotFuture.message ==
            "Geçmiş bir tarih veya saat seçemezsiniz."
        )
    }
}
