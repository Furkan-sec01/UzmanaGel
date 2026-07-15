import Foundation
import Combine
import SwiftUI

@MainActor
class HistoryFavoritesViewModel: ObservableObject {
    // Selection state
    @Published var selectedTab = 0 // 0: Geçmiş, 1: Favoriler
    
    // Order History States
    @Published var orders: [Order] = []
    @Published var orderFilter: OrderFilter = .all
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // Favorites States
    @Published var favoriteProviders: [Provider] = []
    @Published var recentlyViewed: [Provider] = []
    @Published var savedSearches: [String] = ["Su tesisatçısı Kadıköy", "Ev temizliği Beşiktaş", "Duvar boyama boyacı"]
    
    enum OrderFilter: String, CaseIterable {
        case all = "Tümü"
        case completed = "Tamamlanan"
        case cancelled = "İptal Edilen"
    }
    
    private let orderHistoryService: OrderHistoryService
    private let providerService: ProviderService
    
    init(orderHistoryService: OrderHistoryService = MockOrderHistoryService(),
         providerService: ProviderService = MockProviderService()) {
        self.orderHistoryService = orderHistoryService
        self.providerService = providerService
    }
    
    func loadAllData() async {
        isLoading = true
        errorMessage = nil
        do {
            self.orders = try await orderHistoryService.fetchOrders()
            let prov = try await providerService.fetchProviderProfile()
            // Construct a mock list of favorites using provider profile
            self.favoriteProviders = [
                prov,
                Provider(id: "prv_2", businessName: "Umut Temizlik ve Halı Yıkama", rating: 4.9, experienceYears: 5, acceptsCreditCard: true, description: "Profesyonel temizlik ekibi", imageUrl: nil, isCertified: true),
                Provider(id: "prv_3", businessName: "Barış Boya Badana", rating: 4.7, experienceYears: 8, acceptsCreditCard: false, description: "Hızlı ve tertemiz iç boyama hizmetleri", imageUrl: nil, isCertified: false)
            ]
            self.recentlyViewed = [
                Provider(id: "prv_4", businessName: "Yılmaz Cam Balkon", rating: 4.6, experienceYears: 7, acceptsCreditCard: true, description: "Cam balkon imalat ve montajı", imageUrl: nil, isCertified: true),
                Provider(id: "prv_5", businessName: "Kartal Çilingir", rating: 5.0, experienceYears: 15, acceptsCreditCard: true, description: "7/24 kapı ve kasa kilit servisi", imageUrl: nil, isCertified: true)
            ]
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    // Filtered orders list
    var filteredOrders: [Order] {
        switch orderFilter {
        case .all:
            return orders
        case .completed:
            return orders.filter { $0.status == .completed }
        case .cancelled:
            return orders.filter { $0.status == .cancelled }
        }
    }
    
    // Group orders by month-year string
    var groupedOrders: [(key: String, value: [Order])] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "MMMM yyyy"
        
        let grouped = Dictionary(grouping: filteredOrders) { order -> String in
            return formatter.string(from: order.date)
        }
        
        return grouped.sorted { (item1, item2) -> Bool in
            // Basic sort by date parsed back or calendar order, fallback simply on string desc
            return item1.key > item2.key
        }
    }
    
    // Actions
    func repeatOrder(id: String) async {
        isLoading = true
        do {
            let repeated = try await orderHistoryService.repeatOrder(orderId: id)
            orders.insert(repeated, at: 0)
            successMessage = "Tekrar sipariş talebi oluşturuldu."
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func submitRating(orderId: String, rating: Int) async {
        isLoading = true
        do {
            try await orderHistoryService.evaluateOrder(orderId: orderId, rating: rating, comment: nil)
            // Refresh
            self.orders = try await orderHistoryService.fetchOrders()
            successMessage = "Değerlendirmeniz iletildi."
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func toggleFavorite(id: String) {
        favoriteProviders.removeAll(where: { $0.id == id })
        successMessage = "Favorilerden çıkarıldı."
    }
    
    func deleteSavedSearch(at indexSet: IndexSet) {
        savedSearches.remove(atOffsets: indexSet)
    }
}
