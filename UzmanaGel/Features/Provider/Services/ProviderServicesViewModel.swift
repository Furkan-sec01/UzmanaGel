import Foundation
import Combine
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

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

    private let serviceRepo = ServiceRepository()
    private let userRepo = UserRepository()
    private let db = Firestore.firestore()

    private var currentUID: String? {
        Auth.auth().currentUser?.uid
    }

    // MARK: - Load

    func loadServices() async {
        guard let uid = currentUID else {
            errorMessage = "Giriş yapılmamış."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let firestoreServices = try await serviceRepo.fetchAllServicesByProviderId(uid)
            // Firestore Service modelini ExpertService modeline dönüştür
            services = firestoreServices.map { s in
                ExpertService(
                    id: s.serviceId,
                    title: s.title,
                    description: s.description,
                    price: Double(s.price),
                    durationMinutes: durationToMinutes(s.duration),
                    isActive: s.isActive,
                    imageUrls: s.image.isEmpty ? [] : [s.image],
                    pricingType: .fixed
                )
            }
            print("✅ Hizmetler yüklendi: \(services.count)")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Hizmet yükleme hatası: \(error)")
        }
    }

    // MARK: - Toggle Active

    func toggleServiceActive(id: String) async {
        guard let idx = services.firstIndex(where: { $0.id == id }) else { return }

        let newActive = !services[idx].isActive
        services[idx].isActive = newActive

        do {
            try await serviceRepo.updateService(serviceId: id, fields: [
                "isActive": newActive,
                "updatedAt": Timestamp(date: Date())
            ])
            successMessage = newActive ? "Hizmet aktif edildi." : "Hizmet pasif edildi."
        } catch {
            // Rollback
            services[idx].isActive = !newActive
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Delete

    func softDeleteService(id: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await serviceRepo.deleteService(serviceId: id)
            services.removeAll(where: { $0.id == id })
            successMessage = "Hizmet başarıyla silindi."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Add

    func addService() async {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !price.isEmpty else {
            errorMessage = "Lütfen başlık ve fiyat alanlarını doldurun."
            return
        }

        guard let uid = currentUID else {
            errorMessage = "Giriş yapılmamış."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // Uzman profilini çek (publishExpertListing için gerekli)
            guard let profile = try await userRepo.fetchExpertProfile(uid: uid) else {
                errorMessage = "Uzman profili bulunamadı."
                return
            }

            let intPrice = Int(Double(price) ?? 0)
            let intDuration = Int(duration) ?? 60
            let durationStr = "\(intDuration) dakika"

            let serviceId = try await serviceRepo.publishExpertListing(
                providerId: uid,
                profile: profile,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                category: selectedCategory,
                duration: durationStr,
                price: intPrice,
                description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                city: profile.serviceCities.first ?? "",
                imageURL: nil
            )

            let newService = ExpertService(
                id: serviceId,
                title: title,
                description: description,
                price: Double(intPrice),
                durationMinutes: intDuration,
                isActive: true,
                imageUrls: [],
                pricingType: pricingType
            )

            services.append(newService)
            successMessage = "Yeni hizmet başarıyla eklendi."
            resetForm()
            print("✅ Hizmet eklendi: \(serviceId)")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Hizmet ekleme hatası: \(error)")
        }
    }

    // MARK: - Update

    func updateService(id: String) async {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !price.isEmpty else {
            errorMessage = "Lütfen başlık ve fiyat alanlarını doldurun."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let intPrice = Int(Double(price) ?? 0)
        let intDuration = Int(duration) ?? 60

        do {
            try await serviceRepo.updateService(serviceId: id, fields: [
                "title": title.trimmingCharacters(in: .whitespacesAndNewlines),
                "description": description.trimmingCharacters(in: .whitespacesAndNewlines),
                "price": intPrice,
                "duration": "\(intDuration) dakika",
                "isActive": isActive,
                "updatedAt": Timestamp(date: Date())
            ])

            if let idx = services.firstIndex(where: { $0.id == id }) {
                services[idx] = ExpertService(
                    id: id,
                    title: title,
                    description: description,
                    price: Double(intPrice),
                    durationMinutes: intDuration,
                    isActive: isActive,
                    imageUrls: services[idx].imageUrls,
                    pricingType: pricingType
                )
            }

            successMessage = "Hizmet bilgileri güncellendi."
            resetForm()
            print("✅ Hizmet güncellendi: \(id)")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Hizmet güncelleme hatası: \(error)")
        }
    }

    // MARK: - Form

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

    // MARK: - Helpers

    private func durationToMinutes(_ durationStr: String) -> Int {
        // "60 dakika" → 60, "60" → 60
        let numbers = durationStr.filter { $0.isNumber }
        return Int(numbers) ?? 60
    }
}
