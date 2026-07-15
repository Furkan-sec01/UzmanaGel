import Foundation
import Combine
import SwiftUI

@MainActor
class EditBusinessProfileViewModel: ObservableObject {
    // Info inputs
    @Published var businessName = ""
    @Published var description = ""
    @Published var selectedCategories: [String] = []
    
    // Character Limit details
    let descriptionLimit = 250
    
    // Image selection properties
    @Published var logoUrl: String?
    @Published var coverUrl: String?
    @Published var selectedLogoData: Data?
    @Published var selectedCoverData: Data?
    
    // Status metrics
    @Published var isCertified = false
    @Published var missingDocuments: [String] = ["Kimlik Fotokopisi (Arka Yüz)", "Mesleki Yeterlilik Belgesi / Sertifika"]
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private let providerService: ProviderService
    
    init(providerService: ProviderService = MockProviderService()) {
        self.providerService = providerService
    }
    
    func loadBusinessInfo() async {
        isLoading = true
        errorMessage = nil
        do {
            let info = try await providerService.fetchProviderProfile()
            self.businessName = info.businessName
            self.description = info.description
            self.logoUrl = info.imageUrl
            self.isCertified = info.isCertified
            
            // Setup mock categories
            self.selectedCategories = ["Tesisatçı", "Tadilat & Renovasyon"]
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func saveBusinessProfile() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            // 1. Upload images if selected
            if selectedLogoData != nil || selectedCoverData != nil {
                let urls = try await providerService.updateProviderImages(
                    logoData: selectedLogoData,
                    coverData: selectedCoverData
                )
                if let logo = urls.logoUrl { self.logoUrl = logo }
                if let cover = urls.coverUrl { self.coverUrl = cover }
                
                self.selectedLogoData = nil
                self.selectedCoverData = nil
            }
            
            // 2. Save texts info
            let _ = try await providerService.updateProviderProfile(
                businessName: businessName,
                description: description,
                categories: selectedCategories
            )
            
            successMessage = "İşletme profili güncellendi."
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func enforceDescriptionLimit() {
        if description.count > descriptionLimit {
            description = String(description.prefix(descriptionLimit))
        }
    }
    
    func removeCategory(_ category: String) {
        selectedCategories.removeAll(where: { $0 == category })
    }
    
    func addCategory(_ category: String) {
        if !selectedCategories.contains(category) {
            selectedCategories.append(category)
        }
    }
}
