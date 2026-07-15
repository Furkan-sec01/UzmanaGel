import Foundation
import Combine
import SwiftUI

@MainActor
class PortfolioViewModel: ObservableObject {
    @Published var portfolioItems: [PortfolioItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // UI details
    @Published var fullscreenItem: PortfolioItem? = nil
    @Published var showCropFilterSimulator = false
    @Published var selectedImageData: Data? = nil
    
    // Simulated Drag-and-Drop state
    @Published var dragOverId: String? = nil
    
    private let providerService: ProviderService
    
    init(providerService: ProviderService = MockProviderService()) {
        self.providerService = providerService
    }
    
    func loadPortfolio() async {
        isLoading = true
        errorMessage = nil
        // Simulate network delay loading mock items
        try? await Task.sleep(nanoseconds: 400_000_000)
        
        portfolioItems = [
            .init(id: "port_1", imageUrl: "https://images.unsplash.com/photo-1581578731548-c64695cc6952?auto=format&fit=crop&w=300", description: "Banyo batarya değişimi ve fayans tadilatı tamamlandı.", createdAt: Date().addingTimeInterval(-86400 * 5)),
            .init(id: "port_2", imageUrl: "https://images.unsplash.com/photo-1504307651254-35680f356dfd?auto=format&fit=crop&w=300", description: "Mutfak su kaçak tespit çalışması.", createdAt: Date().addingTimeInterval(-86400 * 12)),
            .init(id: "port_3", imageUrl: "https://images.unsplash.com/photo-1621905251189-08b45d6a269e?auto=format&fit=crop&w=300", description: "Yerden ısıtma kollektör montajı ve temizliği.", createdAt: Date().addingTimeInterval(-86400 * 30))
        ]
        isLoading = false
    }
    
    func addPortfolioItem(description: String, imageData: Data) {
        let newItem = PortfolioItem(
            id: "port_\(UUID().uuidString.prefix(6))",
            imageUrl: "https://images.unsplash.com/photo-1584622650111-993a426fbf0a?auto=format&fit=crop&w=300",
            description: description,
            createdAt: Date()
        )
        portfolioItems.insert(newItem, at: 0)
        successMessage = "Fotoğraf portfolyonuza eklendi."
    }
    
    func deleteItem(id: String) {
        portfolioItems.removeAll(where: { $0.id == id })
        if fullscreenItem?.id == id {
            fullscreenItem = nil
        }
        successMessage = "Öğe galeriden silindi."
    }
    
    // Drag and Drop simulation sorting
    func moveItem(from sourceId: String, to targetId: String) {
        guard let sourceIndex = portfolioItems.firstIndex(where: { $0.id == sourceId }),
              let targetIndex = portfolioItems.firstIndex(where: { $0.id == targetId }),
              sourceIndex != targetIndex else { return }
        
        withAnimation(.spring()) {
            let item = portfolioItems.remove(at: sourceIndex)
            portfolioItems.insert(item, at: targetIndex)
        }
    }
    
    func resetForm() {
        selectedImageData = nil
        showCropFilterSimulator = false
    }
}
