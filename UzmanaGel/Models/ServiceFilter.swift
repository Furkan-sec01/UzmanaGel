import Foundation

struct ServiceFilter: Equatable {
    var selectedCategory: String?
    var selectedCity: String?
    var minPrice: Int?
    var maxPrice: Int?
    var sortOption: SortOption = .none

    // Mesafe Seçimi
    var maxDistanceKm: Double?

    // Müsaitlik Filtresi
    var isTodayAvailable: Bool = false
    var isThisWeekAvailable: Bool = false
    var selectedDate: Date?
    var startTime: Date?
    var endTime: Date?

    // Değerlendirme Filtresi
    var minRating: Double?

    // Gelişmiş Filtreler Accordion
    var minExperienceYears: Int = 0
    var minCompletedJobs: Int = 0
    var isCertifiedOnly: Bool = false
    var selectedServiceType: String?

    enum SortOption: String, CaseIterable, Equatable {
        case none             = "Varsayılan"
        case priceLowToHigh   = "Fiyat: Düşükten Yükseğe"
        case priceHighToLow   = "Fiyat: Yüksekten Düşüğe"
    }

    var activeFilterCount: Int {
        var count = 0
        if selectedCategory != nil && !(selectedCategory?.isEmpty ?? true) { count += 1 }
        if selectedCity != nil && !(selectedCity?.isEmpty ?? true) { count += 1 }
        if minPrice != nil || maxPrice != nil { count += 1 }
        if maxDistanceKm != nil { count += 1 }
        if isTodayAvailable || isThisWeekAvailable || selectedDate != nil || startTime != nil || endTime != nil { count += 1 }
        if minRating != nil { count += 1 }
        if minExperienceYears > 0 { count += 1 }
        if minCompletedJobs > 0 { count += 1 }
        if isCertifiedOnly { count += 1 }
        if selectedServiceType != nil && !(selectedServiceType?.isEmpty ?? true) { count += 1 }
        if sortOption != .none { count += 1 }
        return count
    }

    var isActive: Bool {
        activeFilterCount > 0
    }

    mutating func reset() {
        selectedCategory = nil
        selectedCity = nil
        minPrice = nil
        maxPrice = nil
        sortOption = .none
        maxDistanceKm = nil
        isTodayAvailable = false
        isThisWeekAvailable = false
        selectedDate = nil
        startTime = nil
        endTime = nil
        minRating = nil
        minExperienceYears = 0
        minCompletedJobs = 0
        isCertifiedOnly = false
        selectedServiceType = nil
    }
}
