import Foundation

// MARK: - UserProfile Model
struct UserProfile: Codable, Identifiable, Equatable {
    var id: String
    var displayName: String
    var email: String
    var phoneNumber: String?
    var photoURL: String?
    var role: UserRole
    var memberSince: Date
    
    enum UserRole: String, Codable {
        case customer = "customer"
        case provider = "expert"
    }
}

// MARK: - Address Model
struct Address: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var fullAddress: String
    var city: String
    var district: String
    var buildingNo: String
    var apartmentNo: String
    var floor: String
    var directionsNote: String
    var tag: String?
    var isDefault: Bool
    var latitude: Double?
    var longitude: Double?
}

// MARK: - PaymentCard Model
struct PaymentCard: Codable, Identifiable, Equatable {
    var id: String
    var last4: String
    var cardType: CardType
    var cardHolderName: String
    var expiryDate: String // MM/YY
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

// MARK: - NotificationSettings Model
struct NotificationSettings: Codable, Equatable {
    var pushNotificationsEnabled: Bool
    var emailNotificationsEnabled: Bool
    var smsNotificationsEnabled: Bool
    var bookingNotificationsEnabled: Bool
    var promoNotificationsEnabled: Bool
}

// MARK: - AppTheme Model
enum AppTheme: String, Codable, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"
}

// MARK: - Language Model
enum Language: String, Codable, CaseIterable {
    case turkish = "tr"
    case english = "en"
    
    var displayName: String {
        switch self {
        case .turkish: return "Türkçe"
        case .english: return "English"
        }
    }
}

// MARK: - Order Model
struct Order: Codable, Identifiable, Equatable {
    var id: String
    var providerName: String
    var serviceTitle: String
    var price: Double
    var date: Date
    var status: OrderStatus
    var rating: Int?
    var isRated: Bool
    
    enum OrderStatus: String, Codable {
        case pending = "Bekliyor"
        case active = "Aktif"
        case completed = "Tamamlandı"
        case cancelled = "İptal Edildi"
        
        var statusColorName: String {
            switch self {
            case .pending: return "themeWarning"
            case .active: return "themePrimary"
            case .completed: return "themeSuccess"
            case .cancelled: return "themeError"
            }
        }
    }
}

// MARK: - Provider Model
struct Provider: Codable, Identifiable, Equatable {
    var id: String
    var businessName: String
    var rating: Double
    var experienceYears: Int
    var acceptsCreditCard: Bool
    var description: String
    var imageUrl: String?
    var isCertified: Bool
}

// MARK: - ExpertService Model
struct ExpertService: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var description: String
    var price: Double
    var durationMinutes: Int
    var isActive: Bool
    var imageUrls: [String]
    var pricingType: PricingType
    
    enum PricingType: String, Codable {
        case hourly = "Saatlik"
        case fixed = "Proje Bazlı"
    }
}

// MARK: - PortfolioItem Model
struct PortfolioItem: Codable, Identifiable, Equatable {
    var id: String
    var imageUrl: String
    var description: String
    var createdAt: Date
}

// MARK: - AvailabilitySlot Model
struct AvailabilitySlot: Codable, Identifiable, Equatable {
    var id: String
    var date: Date
    var timeSlots: [TimeSlot]
    var isAvailable: Bool
    
    struct TimeSlot: Codable, Equatable, Hashable {
        var timeString: String // e.g., "09:00", "10:00"
        var isBooked: Bool
    }
}

// MARK: - Earning Model
struct Earning: Codable, Identifiable, Equatable {
    var id: String
    var amount: Double
    var date: Date
    var description: String
    var jobTitle: String
    var isPending: Bool
}

// MARK: - WithdrawalRequest Model
struct WithdrawalRequest: Codable, Identifiable, Equatable {
    var id: String
    var amount: Double
    var bankName: String
    var iban: String
    var status: RequestStatus
    var date: Date
    
    enum RequestStatus: String, Codable {
        case pending = "Beklemede"
        case approved = "Onaylandı"
        case rejected = "Reddedildi"
    }
}
