import Foundation
import Combine
import SwiftUI

@MainActor
class ProviderServicesViewModel: ObservableObject {
    @Published var services: [ExpertService] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // Add/Edit Form Inputs
    @Published var title = ""
    @Published var description = ""
    @Published var price = ""
    @Published var duration = ""
    @Published var selectedCategory = "Tesisatçı"
    @Published var pricingType: ExpertService.PricingType = .fixed
    @Published var selectedImagesData: [Data] = []
    @Published var isActive = true
    
    private let providerService: ProviderService
    
    init(providerService: ProviderService = MockProviderService()) {
        self.providerService = providerService
    }
    
    func loadServices() async {
        isLoading = true
        errorMessage = nil
        do {
            self.services = try await providerService.fetchServices()
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func toggleServiceActive(id: String) async {
        guard let idx = services.firstIndex(where: { $0.id == id }) else { return }
        var updated = services[idx]
        updated.isActive.toggle()
        
        do {
            let saved = try await providerService.updateService(updated)
            services[idx] = saved
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func softDeleteService(id: String) async {
        isLoading = true
        do {
            // Soft delete: set isActive = false, or delete from database mock
            try await providerService.deleteService(id: id)
            services.removeAll(where: { $0.id == id })
            successMessage = "Hizmet başarıyla silindi."
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func addService() async {
        guard !title.isEmpty && !price.isEmpty else {
            errorMessage = "Lütfen başlık ve fiyat alanlarını doldurun."
            return
        }
        
        isLoading = true
        errorMessage = nil
        do {
            let doublePrice = Double(price) ?? 0.0
            let intDuration = Int(duration) ?? 60
            
            let newService = ExpertService(
                id: "",
                title: title,
                description: description,
                price: doublePrice,
                durationMinutes: intDuration,
                isActive: isActive,
                imageUrls: [],
                pricingType: pricingType
            )
            
            let saved = try await providerService.addService(newService)
            services.append(saved)
            successMessage = "Yeni hizmet başarıyla eklendi."
            resetForm()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func updateService(id: String) async {
        guard !title.isEmpty && !price.isEmpty else {
            errorMessage = "Lütfen başlık ve fiyat alanlarını doldurun."
            return
        }
        
        isLoading = true
        errorMessage = nil
        do {
            let doublePrice = Double(price) ?? 0.0
            let intDuration = Int(duration) ?? 60
            
            let updatedService = ExpertService(
                id: id,
                title: title,
                description: description,
                price: doublePrice,
                durationMinutes: intDuration,
                isActive: isActive,
                imageUrls: [],
                pricingType: pricingType
            )
            
            let saved = try await providerService.updateService(updatedService)
            if let idx = services.firstIndex(where: { $0.id == id }) {
                services[idx] = saved
            }
            successMessage = "Hizmet bilgileri güncellendi."
            resetForm()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func populateForm(with service: ExpertService) {
        title = service.title
        description = service.description
        price = String(format: "%.0f", service.price)
        duration = "\(service.durationMinutes)"
        pricingType = service.pricingType
        isActive = service.isActive
    }
    
    func resetForm() {
        title = ""
        description = ""
        price = ""
        duration = ""
        pricingType = .fixed
        isActive = true
        selectedImagesData = []
    }
}
