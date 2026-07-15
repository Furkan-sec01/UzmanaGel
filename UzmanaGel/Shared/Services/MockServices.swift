import Foundation

// MARK: - Simulate Network Delay Helper
private func simulateDelay() async {
    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
}

// MARK: - Mock Profile Service
class MockProfileService: ProfileService {
    private var profile = UserProfile(
        id: "usr_customer_1",
        displayName: "Süleyman Demir",
        email: "suleyman@demir.com",
        phoneNumber: "+90 533 999 88 77",
        photoURL: nil,
        role: .customer,
        memberSince: Date().addingTimeInterval(-86400 * 365) // 1 year ago
    )
    
    func fetchProfile() async throws -> UserProfile {
        await simulateDelay()
        return profile
    }
    
    func updateProfile(displayName: String, email: String, phone: String?) async throws -> UserProfile {
        await simulateDelay()
        profile.displayName = displayName
        profile.email = email
        profile.phoneNumber = phone
        return profile
    }
    
    func updateProfileImage(imageData: Data) async throws -> String {
        await simulateDelay()
        let url = "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150"
        profile.photoURL = url
        return url
    }
    
    func changePassword(current: String, new: String) async throws {
        await simulateDelay()
        if current.isEmpty || new.isEmpty {
            throw NSError(domain: "ProfileService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Alanlar boş olamaz."])
        }
    }
    
    func verifyPhoneNumber(phone: String, code: String) async throws {
        await simulateDelay()
        if code != "1234" {
            throw NSError(domain: "ProfileService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Hatalı SMS doğrulama kodu."])
        }
        profile.phoneNumber = phone
    }
}

// MARK: - Mock Address Service
class MockAddressService: AddressService {
    private var addresses: [Address] = [
        Address(
            id: "addr_1",
            title: "Ev",
            fullAddress: "Barbaros Blv. Karanfil Sok. Papatya Apt. No: 12",
            city: "İstanbul",
            district: "Beşiktaş",
            buildingNo: "12",
            apartmentNo: "5",
            floor: "3",
            directionsNote: "Girişteki güvenlikten anahtarı alabilirsiniz.",
            tag: "Ev",
            isDefault: true,
            latitude: 41.0422,
            longitude: 29.0084
        ),
        Address(
            id: "addr_2",
            title: "İş",
            fullAddress: "Büyükdere Cad. Kanyon Plaza No: 185",
            city: "İstanbul",
            district: "Şişli",
            buildingNo: "185",
            apartmentNo: "8",
            floor: "12",
            directionsNote: "Resepsiyona 'UzmanaGel usta çağrısı' deyin.",
            tag: "İş",
            isDefault: false,
            latitude: 41.0782,
            longitude: 29.0116
        )
    ]
    
    func fetchAddresses() async throws -> [Address] {
        await simulateDelay()
        return addresses
    }
    
    func addAddress(_ address: Address) async throws -> Address {
        await simulateDelay()
        var newAddress = address
        newAddress.id = "addr_\(UUID().uuidString.prefix(6))"
        if newAddress.isDefault {
            addresses = addresses.map {
                var a = $0
                a.isDefault = false
                return a
            }
        }
        addresses.append(newAddress)
        return newAddress
    }
    
    func updateAddress(_ address: Address) async throws -> Address {
        await simulateDelay()
        guard let idx = addresses.firstIndex(where: { $0.id == address.id }) else {
            throw NSError(domain: "AddressService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Adres bulunamadı"])
        }
        if address.isDefault {
            addresses = addresses.map {
                var a = $0
                a.isDefault = (a.id == address.id)
                return a
            }
        } else {
            addresses[idx] = address
        }
        return address
    }
    
    func deleteAddress(id: String) async throws {
        await simulateDelay()
        addresses.removeAll(where: { $0.id == id })
    }
    
    func setDefaultAddress(id: String) async throws {
        await simulateDelay()
        addresses = addresses.map {
            var a = $0
            a.isDefault = (a.id == id)
            return a
        }
    }
}

// MARK: - Mock Payment Service
class MockPaymentService: PaymentService {
    private var cards: [PaymentCard] = [
        PaymentCard(
            id: "card_1",
            last4: "8888",
            cardType: .visa,
            cardHolderName: "SÜLEYMAN DEMİR",
            expiryDate: "12/28",
            isDefault: true
        ),
        PaymentCard(
            id: "card_2",
            last4: "9999",
            cardType: .mastercard,
            cardHolderName: "SÜLEYMAN DEMİR",
            expiryDate: "05/27",
            isDefault: false
        )
    ]
    
    func fetchCards() async throws -> [PaymentCard] {
        await simulateDelay()
        return cards
    }
    
    func addCard(holderName: String, number: String, expiry: String, cvv: String, isDefault: Bool) async throws -> PaymentCard {
        await simulateDelay()
        let cleanNumber = number.replacingOccurrences(of: " ", with: "")
        let last4 = String(cleanNumber.suffix(4))
        let type: PaymentCard.CardType = number.hasPrefix("4") ? .visa : (number.hasPrefix("5") ? .mastercard : .unknown)
        
        let newCard = PaymentCard(
            id: "card_\(UUID().uuidString.prefix(6))",
            last4: last4,
            cardType: type,
            cardHolderName: holderName.uppercased(),
            expiryDate: expiry,
            isDefault: isDefault
        )
        if isDefault {
            cards = cards.map {
                var c = $0
                c.isDefault = false
                return c
            }
        }
        cards.append(newCard)
        return newCard
    }
    
    func deleteCard(id: String) async throws {
        await simulateDelay()
        cards.removeAll(where: { $0.id == id })
    }
    
    func setDefaultCard(id: String) async throws {
        await simulateDelay()
        cards = cards.map {
            var c = $0
            c.isDefault = (c.id == id)
            return c
        }
    }
    
    func startApplePayPayment(amount: Double) async throws -> Bool {
        await simulateDelay()
        return true
    }
}

// MARK: - Mock Preferences Service
class MockPreferencesService: PreferencesService {
    private var settings = NotificationSettings(
        pushNotificationsEnabled: true,
        emailNotificationsEnabled: true,
        smsNotificationsEnabled: false,
        bookingNotificationsEnabled: true,
        promoNotificationsEnabled: false
    )
    
    private var theme: AppTheme = .system
    private var language: Language = .turkish
    private var privacy = ["locationSharing": true, "profilePublic": true, "dataCollection": true]
    
    func fetchNotificationSettings() async throws -> NotificationSettings {
        await simulateDelay()
        return settings
    }
    
    func saveNotificationSettings(_ settings: NotificationSettings) async throws {
        await simulateDelay()
        self.settings = settings
    }
    
    func fetchTheme() async throws -> AppTheme {
        await simulateDelay()
        return theme
    }
    
    func saveTheme(_ theme: AppTheme) async throws {
        await simulateDelay()
        self.theme = theme
    }
    
    func fetchLanguage() async throws -> Language {
        await simulateDelay()
        return language
    }
    
    func saveLanguage(_ language: Language) async throws {
        await simulateDelay()
        self.language = language
    }
    
    func fetchPrivacySettings() async throws -> [String : Bool] {
        await simulateDelay()
        return privacy
    }
    
    func savePrivacySettings(_ settings: [String : Bool]) async throws {
        await simulateDelay()
        self.privacy = settings
    }
}

// MARK: - Mock Order History Service
class MockOrderHistoryService: OrderHistoryService {
    private var orders: [Order] = [
        Order(
            id: "ord_1",
            providerName: "Ahmet Usta (Elektrik)",
            serviceTitle: "Avize Montajı ve Tesisat Yenileme",
            price: 750.0,
            date: Date().addingTimeInterval(-86400 * 5),
            status: .completed,
            rating: 5,
            isRated: true
        ),
        Order(
            id: "ord_2",
            providerName: "Zeynep Temizlik",
            serviceTitle: "3 Oda 1 Salon Ev Temizliği",
            price: 1200.0,
            date: Date().addingTimeInterval(-86400 * 12),
            status: .completed,
            rating: nil,
            isRated: false
        ),
        Order(
            id: "ord_3",
            providerName: "Hakan Tesisat",
            serviceTitle: "Lavabo Sızıntısı Tamiri",
            price: 450.0,
            date: Date().addingTimeInterval(-86400 * 30),
            status: .cancelled,
            rating: nil,
            isRated: false
        )
    ]
    
    func fetchOrders() async throws -> [Order] {
        await simulateDelay()
        return orders
    }
    
    func repeatOrder(orderId: String) async throws -> Order {
        await simulateDelay()
        guard let order = orders.first(where: { $0.id == orderId }) else {
            throw NSError(domain: "OrderService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Sipariş bulunamadı"])
        }
        var newOrder = order
        newOrder.id = "ord_\(UUID().uuidString.prefix(6))"
        newOrder.date = Date()
        newOrder.status = .pending
        newOrder.isRated = false
        newOrder.rating = nil
        orders.insert(newOrder, at: 0)
        return newOrder
    }
    
    func evaluateOrder(orderId: String, rating: Int, comment: String?) async throws {
        await simulateDelay()
        if let idx = orders.firstIndex(where: { $0.id == orderId }) {
            orders[idx].isRated = true
            orders[idx].rating = rating
        }
    }
}

// MARK: - Mock Provider Service
class MockProviderService: ProviderService {
    private var provider = Provider(
        id: "prv_1",
        businessName: "Esenler Tesisat & Yapı Market",
        rating: 4.8,
        experienceYears: 10,
        acceptsCreditCard: true,
        description: "10 yıllık uzman kadromuzla tesisat, montaj, arıza ve dekorasyon işlerinizde her zaman yanınızdayız.",
        imageUrl: nil,
        isCertified: true
    )
    
    private var services: [ExpertService] = [
        ExpertService(
            id: "srv_1",
            title: "Petek Temizliği ve Kombi Bakımı",
            description: "Kış ayları gelmeden peteklerinizin verimini artırın.",
            price: 1500.0,
            durationMinutes: 120,
            isActive: true,
            imageUrls: [],
            pricingType: .fixed
        ),
        ExpertService(
            id: "srv_2",
            title: "Tıkanıklık Açma Hizmeti",
            description: "Robot makineler ile kırmadan dökmeden tıkanıklık açılır.",
            price: 600.0,
            durationMinutes: 60,
            isActive: true,
            imageUrls: [],
            pricingType: .hourly
        )
    ]
    
    func fetchProviderProfile() async throws -> Provider {
        await simulateDelay()
        return provider
    }
    
    func updateProviderProfile(businessName: String, description: String, categories: [String]) async throws -> Provider {
        await simulateDelay()
        provider.businessName = businessName
        provider.description = description
        return provider
    }
    
    func updateProviderImages(logoData: Data?, coverData: Data?) async throws -> (logoUrl: String?, coverUrl: String?) {
        await simulateDelay()
        return (
            "https://images.unsplash.com/photo-1560179707-f14e90ef3623?auto=format&fit=crop&w=150",
            "https://images.unsplash.com/photo-1504307651254-35680f356dfd?auto=format&fit=crop&w=600"
        )
    }
    
    func fetchServices() async throws -> [ExpertService] {
        await simulateDelay()
        return services
    }
    
    func addService(_ service: ExpertService) async throws -> ExpertService {
        await simulateDelay()
        var newService = service
        newService.id = "srv_\(UUID().uuidString.prefix(6))"
        services.append(newService)
        return newService
    }
    
    func updateService(_ service: ExpertService) async throws -> ExpertService {
        await simulateDelay()
        if let idx = services.firstIndex(where: { $0.id == service.id }) {
            services[idx] = service
        }
        return service
    }
    
    func deleteService(id: String) async throws {
        await simulateDelay()
        services.removeAll(where: { $0.id == id })
    }
}

// MARK: - Mock Schedule Service
class MockScheduleService: ScheduleService {
    private var slots: [AvailabilitySlot] = [
        AvailabilitySlot(
            id: "slot_1",
            date: Date(),
            timeSlots: [
                .init(timeString: "09:00", isBooked: true),
                .init(timeString: "11:00", isBooked: false),
                .init(timeString: "14:00", isBooked: false)
            ],
            isAvailable: true
        ),
        AvailabilitySlot(
            id: "slot_2",
            date: Date().addingTimeInterval(86400),
            timeSlots: [
                .init(timeString: "10:00", isBooked: false),
                .init(timeString: "15:00", isBooked: false)
            ],
            isAvailable: true
        )
    ]
    
    func fetchAvailability() async throws -> [AvailabilitySlot] {
        await simulateDelay()
        return slots
    }
    
    func saveAvailability(slots: [AvailabilitySlot]) async throws {
        await simulateDelay()
        self.slots = slots
    }
    
    func updateSlotAvailability(slotId: String, isAvailable: Bool) async throws {
        await simulateDelay()
        if let idx = slots.firstIndex(where: { $0.id == slotId }) {
            slots[idx].isAvailable = isAvailable
        }
    }
}

// MARK: - Mock Finance Service
class MockFinanceService: FinanceService {
    private var earnings: [Earning] = [
        Earning(
            id: "earn_1",
            amount: 750.0,
            date: Date().addingTimeInterval(-86400 * 2),
            description: "Avize Montajı işinden kazanıldı.",
            jobTitle: "Avize Montajı",
            isPending: false
        ),
        Earning(
            id: "earn_2",
            amount: 1500.0,
            date: Date().addingTimeInterval(-86400 * 4),
            description: "Kombi Bakımı işinden kazanıldı.",
            jobTitle: "Kombi Bakımı",
            isPending: false
        ),
        Earning(
            id: "earn_3",
            amount: 600.0,
            date: Date(),
            description: "Tıkanıklık Açma işinden bekleyen bakiye.",
            jobTitle: "Tıkanıklık Açma",
            isPending: true
        )
    ]
    
    private var requests: [WithdrawalRequest] = [
        WithdrawalRequest(
            id: "req_1",
            amount: 2000.0,
            bankName: "Akbank",
            iban: "TR1234567890123456789012",
            status: .approved,
            date: Date().addingTimeInterval(-86400 * 10)
        )
    ]
    
    func fetchEarnings() async throws -> [Earning] {
        await simulateDelay()
        return earnings
    }
    
    func fetchWithdrawalRequests() async throws -> [WithdrawalRequest] {
        await simulateDelay()
        return requests
    }
    
    func requestWithdrawal(amount: Double, bankName: String, iban: String) async throws -> WithdrawalRequest {
        await simulateDelay()
        let newRequest = WithdrawalRequest(
            id: "req_\(UUID().uuidString.prefix(6))",
            amount: amount,
            bankName: bankName,
            iban: iban,
            status: .pending,
            date: Date()
        )
        requests.insert(newRequest, at: 0)
        return newRequest
    }
}
