import Foundation

// MARK: - ProfileService Protocol
protocol ProfileService {
    func fetchProfile() async throws -> UserProfile
    func updateProfile(displayName: String, email: String, phone: String?) async throws -> UserProfile
    func updateProfileImage(imageData: Data) async throws -> String
    func changePassword(current: String, new: String) async throws
    func verifyPhoneNumber(phone: String, code: String) async throws
}

// MARK: - AddressService Protocol
protocol AddressService {
    func fetchAddresses() async throws -> [Address]
    func addAddress(_ address: Address) async throws -> Address
    func updateAddress(_ address: Address) async throws -> Address
    func deleteAddress(id: String) async throws
    func setDefaultAddress(id: String) async throws
}

// MARK: - PaymentService Protocol
protocol PaymentService {
    func fetchCards() async throws -> [PaymentCard]
    func addCard(holderName: String, number: String, expiry: String, cvv: String, isDefault: Bool) async throws -> PaymentCard
    func deleteCard(id: String) async throws
    func setDefaultCard(id: String) async throws
    func startApplePayPayment(amount: Double) async throws -> Bool
}

// MARK: - PreferencesService Protocol
protocol PreferencesService {
    func fetchNotificationSettings() async throws -> NotificationSettings
    func saveNotificationSettings(_ settings: NotificationSettings) async throws
    
    func fetchTheme() async throws -> AppTheme
    func saveTheme(_ theme: AppTheme) async throws
    
    func fetchLanguage() async throws -> Language
    func saveLanguage(_ language: Language) async throws
    
    func fetchPrivacySettings() async throws -> [String: Bool]
    func savePrivacySettings(_ settings: [String: Bool]) async throws
}

// MARK: - OrderHistoryService Protocol
protocol OrderHistoryService {
    func fetchOrders() async throws -> [Order]
    func repeatOrder(orderId: String) async throws -> Order
    func evaluateOrder(orderId: String, rating: Int, comment: String?) async throws
}

// MARK: - ProviderService Protocol
protocol ProviderService {
    func fetchProviderProfile() async throws -> Provider
    func updateProviderProfile(businessName: String, description: String, categories: [String]) async throws -> Provider
    func updateProviderImages(logoData: Data?, coverData: Data?) async throws -> (logoUrl: String?, coverUrl: String?)
    func fetchServices() async throws -> [ExpertService]
    func addService(_ service: ExpertService) async throws -> ExpertService
    func updateService(_ service: ExpertService) async throws -> ExpertService
    func deleteService(id: String) async throws
}

// MARK: - ScheduleService Protocol
protocol ScheduleService {
    func fetchAvailability() async throws -> [AvailabilitySlot]
    func saveAvailability(slots: [AvailabilitySlot]) async throws
    func updateSlotAvailability(slotId: String, isAvailable: Bool) async throws
}

// MARK: - FinanceService Protocol
protocol FinanceService {
    func fetchEarnings() async throws -> [Earning]
    func fetchWithdrawalRequests() async throws -> [WithdrawalRequest]
    func requestWithdrawal(amount: Double, bankName: String, iban: String) async throws -> WithdrawalRequest
}
