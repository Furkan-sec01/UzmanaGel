import Foundation
import Combine
import SwiftUI
import FirebaseFirestore

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
    @Published var savedSearches: [String] = []
    
    enum OrderFilter: String, CaseIterable {
        case all = "Tümü"
        case completed = "Tamamlanan"
        case cancelled = "İptal Edilen"
    }
    
    private let orderHistoryService: OrderHistoryService
    private let favoritesService: FavoritesService
    private let serviceRepository = ServiceRepository()
    
    init(orderHistoryService: OrderHistoryService = FirestoreOrderHistoryService(),
         favoritesService: FavoritesService = FirestoreFavoritesService()) {
        self.orderHistoryService = orderHistoryService
        self.favoritesService = favoritesService
    }
    
    func loadAllData() async {
        isLoading = true
        errorMessage = nil
        
        // Load orders independently
        do {
            self.orders = try await orderHistoryService.fetchOrders()
        } catch {
            self.errorMessage = "Siparişler yüklenemedi: \(error.localizedDescription)"
        }
        
        // Load favorites independently (so orders failure doesn't block favorites)
        do {
            self.favoriteProviders = try await favoritesService.fetchFavoriteProviders()
            self.recentlyViewed = try await favoritesService.fetchRecentlyViewed()
            self.savedSearches = try await favoritesService.fetchSavedSearches()
        } catch {
            // Don't overwrite orders error — show favorites error only if no orders error
            if self.errorMessage == nil {
                self.errorMessage = "Favoriler yüklenemedi: \(error.localizedDescription)"
            }
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
        formatter.locale = Locale(identifier: LanguageManager.shared.languageCode == "en" ? "en_US" : "tr_TR")
        formatter.dateFormat = "MMMM yyyy"
        
        let grouped = Dictionary(grouping: filteredOrders) { order -> String in
            return formatter.string(from: order.date)
        }
        
        return grouped.sorted { (item1, item2) -> Bool in
            // Basic sort by date parsed back or calendar order, fallback simply on string desc
            return item1.key > item2.key
        }
    }
    
    // Fetch the original Service to navigate to ServiceDetailPage ("Hizmeti Yeniden Al")
    func fetchServiceForReorder(order: Order) async -> Service? {
        if let serviceId = order.serviceId, !serviceId.isEmpty {
            if let service = try? await serviceRepository.fetchServicesByServiceIds([serviceId]).first {
                return service
            }
        }
        return await fetchFirstService(forProviderId: order.providerId)
    }

    func fetchFirstService(forProviderId providerId: String?) async -> Service? {
        guard let providerId = providerId, !providerId.isEmpty else { return nil }
        let services = (try? await serviceRepository.fetchServicesByProviderId(providerId)) ?? []
        return services.first
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
        Task {
            do {
                try await favoritesService.toggleFavorite(providerId: id)
                await MainActor.run {
                    favoriteProviders.removeAll(where: { $0.id == id })
                    successMessage = "Favorilerden çıkarıldı."
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func deleteSavedSearch(at indexSet: IndexSet) {
        let indices = Array(indexSet)
        Task {
            do {
                for index in indices {
                    let query = savedSearches[index]
                    try await favoritesService.removeSavedSearch(query)
                }
                await MainActor.run {
                    savedSearches.remove(atOffsets: indexSet)
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
