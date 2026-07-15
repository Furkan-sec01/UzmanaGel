import Foundation

// MARK: - Customer Profile Model
struct CustomerProfile: Codable, Identifiable, Equatable {
    var id: String
    var displayName: String
    var email: String
    var phoneNumber: String?
    var photoURL: String?
    var memberSince: Date
    var role: String
    
    static var empty: CustomerProfile {
        CustomerProfile(
            id: UUID().uuidString,
            displayName: "",
            email: "",
            phoneNumber: "",
            photoURL: nil,
            memberSince: Date(),
            role: "customer"
        )
    }
}

// MARK: - Payment Method Model
struct PaymentMethod: Codable, Identifiable, Equatable {
    var id: String
    var last4: String
    var cardType: CardType
    var cardHolderName: String
    var expiryDate: String // Format: "MM/YY"
    var isDefault: Bool
    
    enum CardType: String, Codable {
        case visa = "Visa"
        case mastercard = "Mastercard"
        case amex = "Amex"
        case discover = "Discover"
        case unknown = "Unknown"
        
        var iconName: String {
            switch self {
            case .visa: return "creditcard.fill"
            case .mastercard: return "creditcard"
            case .amex: return "creditcard.and.123"
            default: return "creditcard.fill"
            }
        }
    }
}

// MARK: - User Preferences Model
struct UserPreferences: Codable, Equatable {
    // Notification Toggles
    var pushNotificationsEnabled: Bool
    var emailNotificationsEnabled: Bool
    var smsNotificationsEnabled: Bool
    
    // Notification Types
    var bookingNotificationsEnabled: Bool
    var promoNotificationsEnabled: Bool
    
    // Appearance settings
    var themeSelection: ThemeSelection
    var accentColorHex: String
    var selectedLanguage: String
    
    // Privacy Settings
    var locationSharingEnabled: Bool
    var profileVisibilityPublic: Bool
    var dataCollectionConsent: Bool
    
    enum ThemeSelection: String, Codable, CaseIterable {
        case light = "Light"
        case dark = "Dark"
        case system = "System"
    }
    
    static var `default`: UserPreferences {
        UserPreferences(
            pushNotificationsEnabled: true,
            emailNotificationsEnabled: true,
            smsNotificationsEnabled: false,
            bookingNotificationsEnabled: true,
            promoNotificationsEnabled: false,
            themeSelection: .system,
            accentColorHex: "#304FFE",
            selectedLanguage: "tr",
            locationSharingEnabled: true,
            profileVisibilityPublic: true,
            dataCollectionConsent: true
        )
    }
}
