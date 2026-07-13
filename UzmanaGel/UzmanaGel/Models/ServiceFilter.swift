import Foundation

struct ServiceFilter: Equatable {
    var selectedCategory: String?
    var selectedCity: String?
    var minPrice: Int?
    var maxPrice: Int?
    var sortOption: SortOption = .none

    enum SortOption: String, CaseIterable, Equatable {
        case none             = "Varsayılan"
        case priceLowToHigh   = "Fiyat: Düşükten Yükseğe"
        case priceHighToLow   = "Fiyat: Yüksekten Düşüğe"
    }

    var isActive: Bool {
        selectedCategory != nil ||
        selectedCity != nil ||
        minPrice != nil ||
        maxPrice != nil ||
        sortOption != .none
    }

    mutating func reset() {
        selectedCategory = nil
        selectedCity = nil
        minPrice = nil
        maxPrice = nil
        sortOption = .none
    }
}
