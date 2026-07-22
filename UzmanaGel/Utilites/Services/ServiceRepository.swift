import Foundation
import FirebaseFirestore

///ServiceRepository, servisleri Firestore'dan getirir, provider bilgileriyle birleştirir, ID bazlı veya provider bazlı servis sorguları yapar ve expert ilanlarını oluşturma/güncelleme/silme işlemlerini yönetir.

final class ServiceRepository {

    private let db = Firestore.firestore()
    
    private let activeServicesPageSize = 25

    private var lastActiveServicesDocument: DocumentSnapshot?
    private var hasMoreActiveServices = true

    // MARK: - Public

    /// Retrieve the first 25 active services and join them with provider information.
    func fetchActiveServices() async throws -> [Service] {

        /// Pagination resets when a new list is loaded.
        lastActiveServicesDocument = nil
        hasMoreActiveServices = true

        let snap = try await db.collection("services")
            .whereField("isActive", isEqualTo: true)
            .limit(to: activeServicesPageSize)
            .getDocuments()

        /// Save the last document of the first page
        lastActiveServicesDocument = snap.documents.last

        /// If the count is less than 25, there are no further pages.
        hasMoreActiveServices = snap.documents.count == activeServicesPageSize

        var services = snap.documents.compactMap { doc -> Service? in
            do {
                var service = try doc.data(as: Service.self)

                if service.serviceId.isEmpty {
                    service.serviceId = doc.documentID
                }

                return service
            } catch {
                print("⚠️ Service decode hatası (\(doc.documentID)): \(error)")
                return nil
            }
        }

        /// Fetch and merge provider information
        let providerIds = Array(
            Set(
                services.compactMap {
                    $0.providerId.isEmpty ? nil : $0.providerId
                }
            )
        )

        if !providerIds.isEmpty {
            let providers = await fetchProviders(ids: providerIds)

            services = services.map {
                mergeProviderData(service: $0, providers: providers)
            }
        }

        print("✅ İlk sayfa aktif servis: \(services.count)")
        print("📄 Devam sayfası var mı: \(hasMoreActiveServices)")

        return services
    }
   
    /// Retrieve the next 25 records of active services
    func fetchNextActiveServicesPage() async throws -> [Service] {

        guard hasMoreActiveServices else {
            print("📄 Yüklenecek başka aktif servis yok")
            return []
        }

        guard let lastDocument = lastActiveServicesDocument else {
            print("⚠️ Pagination cursor bulunamadı")
            return []
        }

        let snap = try await db.collection("services")
            .whereField("isActive", isEqualTo: true)
            .start(afterDocument: lastDocument)
            .limit(to: activeServicesPageSize)
            .getDocuments()

        /// Store the last document of the new page as the cursor
        if let newLastDocument = snap.documents.last {
            lastActiveServicesDocument = newLastDocument
        }

        /// If fewer than 25 were returned, there are no more pages.
        hasMoreActiveServices = snap.documents.count == activeServicesPageSize

        var services = snap.documents.compactMap { doc -> Service? in
            do {
                var service = try doc.data(as: Service.self)

                if service.serviceId.isEmpty {
                    service.serviceId = doc.documentID
                }

                return service
            } catch {
                print("⚠️ Service decode hatası (\(doc.documentID)): \(error)")
                return nil
            }
        }

        /// Only retrieve provider information from this new page
        let providerIds = Array(
            Set(
                services.compactMap {
                    $0.providerId.isEmpty ? nil : $0.providerId
                }
            )
        )

        if !providerIds.isEmpty {
            let providers = await fetchProviders(ids: providerIds)

            services = services.map {
                mergeProviderData(service: $0, providers: providers)
            }
        }

        print("✅ Sonraki sayfa servis: \(services.count)")
        print("📄 Devam sayfası var mı: \(hasMoreActiveServices)")

        return services
    }

    /// ID listesine göre servisleri getir (Firestore "in" query max 30)
    func fetchServicesByIds(_ ids: [String]) async throws -> [Service] {
        guard !ids.isEmpty else { return [] }

        var allServices: [Service] = []
        let chunks = ids.chunked(into: 30)

        for chunk in chunks {
            let snap = try await db.collection("services")
                .whereField("serviceId", in: chunk)
                .getDocuments()

            let services = snap.documents.compactMap { doc -> Service? in
                do {
                    var service = try doc.data(as: Service.self)
                    if service.serviceId.isEmpty {
                        service.serviceId = doc.documentID
                    }
                    return service
                } catch {
                    print("⚠️ Service decode hatası (\(doc.documentID)): \(error)")
                    return nil
                }
            }
            allServices.append(contentsOf: services)
        }

        // Provider bilgilerini çek ve birleştir
        let providerIds = Array(Set(allServices.compactMap { $0.providerId.isEmpty ? nil : $0.providerId }))
        if !providerIds.isEmpty {
            let providers = await fetchProviders(ids: providerIds)
            allServices = allServices.map { mergeProviderData(service: $0, providers: providers) }
        }

        // Orijinal sırayı koru
        let indexMap = Dictionary(uniqueKeysWithValues: ids.enumerated().map { ($0.element, $0.offset) })
        return allServices.sorted { (indexMap[$0.serviceId] ?? .max) < (indexMap[$1.serviceId] ?? .max) }
    }

    func fetchServicesByServiceIds(_ ids: [String]) async throws -> [Service] {
        try await fetchServicesByIds(ids)
    }

    /// Belirli provider'a ait aktif servisleri getir
    func fetchServicesByProviderId(_ providerId: String) async throws -> [Service] {
        guard !providerId.isEmpty else { return [] }

        let snap = try await db.collection("services")
            .whereField("providerId", isEqualTo: providerId)
            .getDocuments()

        return snap.documents.compactMap { doc -> Service? in
            do {
                var service = try doc.data(as: Service.self)
                if service.serviceId.isEmpty {
                    service.serviceId = doc.documentID
                }
                return service
            } catch {
                print("⚠️ Service decode hatası (\(doc.documentID)): \(error)")
                return nil
            }
        }.filter { $0.isActive }
    }

    /// Uzmanın tüm ilanları (aktif + pasif); yönetim sayfası için.
    func fetchAllServicesByProviderId(_ providerId: String) async throws -> [Service] {
        guard !providerId.isEmpty else { return [] }
        let snap = try await db.collection("services")
            .whereField("providerId", isEqualTo: providerId)
            .getDocuments()
        return snap.documents.compactMap { doc -> Service? in
            do {
                var service = try doc.data(as: Service.self)
                if service.serviceId.isEmpty {
                    service.serviceId = doc.documentID
                }
                return service
            } catch {
                print("⚠️ Service decode hatası (\(doc.documentID)): \(error)")
                return nil
            }
        }
    }

    /// İlanı siler (dokümanı kaldırır).
    func deleteService(serviceId: String) async throws {
        try await db.collection("services").document(serviceId).delete()
    }

    /// İlan alanlarını günceller (merge).
    func updateService(serviceId: String, fields: [String: Any]) async throws {
        try await db.collection("services").document(serviceId).setData(fields, merge: true)
    }

    // MARK: - Uzman ilan oluşturma

    /// Uzman ilanı yayınla: services koleksiyonuna ekle, service_providers'ı güncelle.
    /// Müşteri tarafında görünmesi için provider bilgisi service_providers'da olmalı.
    func publishExpertListing(
        providerId: String,
        profile: ExpertProfile,
        title: String,
        category: String,
        duration: String,
        price: Int,
        description: String,
        city: String,
        imageURL: String?
    ) async throws -> String {
        try await ensureExpertProvider(profile: profile, providerId: providerId)

        let ref = db.collection("services").document()
        let serviceId = ref.documentID
        let image = imageURL ?? profile.profileImageURL ?? ""
        let providerName = profile.businessName.isEmpty ? profile.displayName : profile.businessName
        let finalCity = city.isEmpty ? (profile.serviceCities.first ?? "") : city

        let data: [String: Any] = [
            "serviceId": serviceId,
            "title": title,
            "category": category,
            "duration": duration,
            "providerId": providerId,
            "isActive": true,
            "price": price,
            "providerName": providerName,
            "city": finalCity,
            "description": description,
            "image": image,
            "experienceYears": profile.experienceYears,
            "rating": 0.0,
            "isAvailable": true,
            "isCertified": !profile.certificateURLs.isEmpty,
            "acceptsCreditCard": false
        ]

        try await ref.setData(data)
        return serviceId
    }

    /// Uzman profilini service_providers'a yazar; müşteri listesinde birleştirme çalışır. Konum (locationGeo) profildeki adresten gelir.
    func ensureExpertProvider(profile: ExpertProfile, providerId: String) async throws {
        let ref = db.collection("service_providers").document(providerId)
        let city = profile.serviceCities.first ?? ""
        var data: [String: Any] = [
            "providerId": providerId,
            "businessName": profile.businessName.isEmpty ? profile.displayName : profile.businessName,
            "city": city,
            "isActive": true,
            "description": profile.about ?? "",
            "image": profile.profileImageURL ?? "",
            "phoneNumber": profile.phoneNumber,
            "rating": 0.0,
            "experienceYears": profile.experienceYears,
            "isCertified": !profile.certificateURLs.isEmpty,
            "acceptsCreditCard": false
        ]
        if let geo = profile.locationGeo {
            data["locationGeo"] = geo
        }
        try await ref.setData(data, merge: true)
    }

    // MARK: - Provider Fetch & Merge

    /// Provider ID listesiyle service_providers koleksiyonundan veri çek
    private func fetchProviders(ids: [String]) async -> [String: ServiceProvider] {
        var providerMap: [String: ServiceProvider] = [:]
        let chunks = ids.chunked(into: 30)

        for chunk in chunks {
            do {
                let snap = try await db.collection("service_providers")
                    .whereField("providerId", in: chunk)
                    .getDocuments()

                for doc in snap.documents {
                    if let provider = try? doc.data(as: ServiceProvider.self) {
                        let key = provider.providerId.isEmpty ? doc.documentID : provider.providerId
                        providerMap[key] = provider
                    }
                }
            } catch {
                print("⚠️ Provider fetch hatası: \(error)")
            }
        }

        // providerId alanı olmayan belgeleri documentID ile de dene
        if providerMap.count < ids.count {
            let missingIds = ids.filter { providerMap[$0] == nil }
            for missingId in missingIds {
                do {
                    let doc = try await db.collection("service_providers")
                        .document(missingId)
                        .getDocument()

                    if doc.exists, let provider = try? doc.data(as: ServiceProvider.self) {
                        providerMap[missingId] = provider
                    }
                } catch {
                    print("⚠️ Provider (\(missingId)) fetch hatası: \(error)")
                }
            }
        }

        print("👤 Yüklenen provider sayısı: \(providerMap.count)/\(ids.count)")
        return providerMap
    }

    /// Provider verisini Service'e birleştir
    private func mergeProviderData(service: Service, providers: [String: ServiceProvider]) -> Service {
        guard let provider = providers[service.providerId] else { return service }

        var merged = service
        merged.providerName = provider.businessName
        merged.city = provider.city
        merged.providerIsAvailable = provider.isAvailable

        let profileImageURL = provider.profileImageURL
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let legacyImageURL = provider.image
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        merged.providerImageURL = profileImageURL.isEmpty
            ? legacyImageURL
            : profileImageURL

        // Provider'dan gelen ek alanlar (varsa)
        if merged.description.isEmpty && !provider.description.isEmpty {
            merged.description = provider.description
        }
        if merged.image.isEmpty && !provider.image.isEmpty {
            merged.image = provider.image
        }
        if merged.rating == 0 && provider.rating > 0 {
            merged.rating = provider.rating
        }
        if merged.experienceYears == 0 && provider.experienceYears > 0 {
            merged.experienceYears = provider.experienceYears
        }
        if !merged.isCertified && provider.isCertified {
            merged.isCertified = provider.isCertified
        }
        if !merged.acceptsCreditCard && provider.acceptsCreditCard {
            merged.acceptsCreditCard = provider.acceptsCreditCard
        }
        if merged.locationGeo == nil, let geo = provider.locationGeo {
            merged.locationGeo = geo
        }

        return merged
    }
}

// MARK: - Array Extension

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
