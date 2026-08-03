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
