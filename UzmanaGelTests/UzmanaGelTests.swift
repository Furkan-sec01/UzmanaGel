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
