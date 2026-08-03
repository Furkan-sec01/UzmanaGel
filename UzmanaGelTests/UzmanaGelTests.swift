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
