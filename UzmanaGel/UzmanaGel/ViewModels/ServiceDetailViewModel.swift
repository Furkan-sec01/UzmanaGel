import Foundation
import Combine
import FirebaseFirestore
import FirebaseStorage
import CoreLocation

@MainActor
final class ServiceDetailViewModel: ObservableObject {

    // MARK: - Published

    @Published var providerServices: [Service] = []
    @Published var galleryURLs: [URL] = []
    @Published var coverImageURL: URL?
    @Published var addressText: String = ""
    @Published var isFavorite: Bool
    @Published var isLoading = false
    /// Uzmanın çalışma saatleri / günleri (service_providers'dan; müşteri tarafında gösterilir)
    @Published var expertProfile: ExpertProfile?

    let service: Service

    private let serviceRepo = ServiceRepository()
    private let favRepo = FavoritesRepository()
    private let userRepo = UserRepository()

    // MARK: - Init

    init(service: Service, imageURL: URL?, isFavorite: Bool) {
        self.service = service
        self.coverImageURL = imageURL
        self.isFavorite = isFavorite
    }

    // MARK: - Public

    func load() {
        guard !isLoading else { return }
        isLoading = true

        Task {
            async let s: () = fetchProviderServices()
            async let g: () = fetchGalleryImages()
            async let a: () = resolveAddress()
            _ = await (s, g, a)

            if coverImageURL == nil {
                loadCoverImage()
            }

            isLoading = false
        }
    }

    /// Uzmanın çalışma günlerini Türkçe kısa isimle döndürür (workingDays: "1"=Pazartesi ... "7"=Pazar). Sıra: Pzt→Paz.
    var workingDaysDisplayNames: [String] {
        let order = ["1", "2", "3", "4", "5", "6", "7"]
        let map: [String: String] = [
            "1": "Pazartesi", "2": "Salı", "3": "Çarşamba", "4": "Perşembe",
            "5": "Cuma", "6": "Cumartesi", "7": "Pazar"
        ]
        let days = expertProfile?.workingDays ?? []
        return order.filter { days.contains($0) }.map { map[$0] ?? $0 }
    }

    var workingHoursRangeText: String? {
        guard let profile = expertProfile else { return nil }
        let start = profile.workingHoursStart?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let end = profile.workingHoursEnd?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if start.isEmpty && end.isEmpty { return nil }
        if start.isEmpty { return end.isEmpty ? nil : "– \(end)" }
        if end.isEmpty { return start }
        return "\(start) – \(end)"
    }

    func toggleFavorite() {
        Task {
            do {
                if isFavorite {
                    try await favRepo.removeFavorite(serviceId: service.serviceId)
                    isFavorite = false
                } else {
                    try await favRepo.addFavorite(serviceId: service.serviceId)
                    isFavorite = true
                }
            } catch {
                print("⚠️ Favori toggle hatası: \(error)")
            }
        }
    }

    func openDirections() {
        guard let geo = service.locationGeo else { return }
        let urlStr = "http://maps.apple.com/?daddr=\(geo.latitude),\(geo.longitude)"
        if let url = URL(string: urlStr) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Private

    private func fetchProviderServices() async {
        guard !service.providerId.isEmpty else { return }
        do {
            providerServices = try await serviceRepo.fetchServicesByProviderId(service.providerId)
        } catch {
            print("⚠️ Provider servisleri yüklenemedi: \(error)")
        }
    }

    /// Portföy: uzmanın service_providers.portfolioImageURLs değerini kullan; tüm ilanlarda aynı portföy gösterilir.
    private func fetchGalleryImages() async {
        if !service.image.isEmpty, let url = URL(string: service.image) {
            coverImageURL = url
        }

        guard !service.providerId.isEmpty else { return }
        do {
            guard let profile = try await userRepo.fetchExpertProfile(uid: service.providerId) else { return }
            expertProfile = profile
            let urls = profile.portfolioImageURLs.compactMap { URL(string: $0) }
            galleryURLs = urls
            if coverImageURL == nil, let first = urls.first {
                coverImageURL = first
            }
        } catch {
            print("📷 Portföy yüklenemedi: \(error.localizedDescription)")
        }
    }

    private func loadCoverImage() {
        if !service.image.isEmpty, let url = URL(string: service.image) {
            coverImageURL = url
            return
        }
        if let first = galleryURLs.first {
            coverImageURL = first
        }
    }

    private func resolveAddress() async {
        guard let geo = service.locationGeo else {
            addressText = service.city
            return
        }

        let location = CLLocation(latitude: geo.latitude, longitude: geo.longitude)

        do {
            let placemarks = try await CLGeocoder().reverseGeocodeLocation(location)
            if let pm = placemarks.first {
                let parts = [
                    pm.subLocality,
                    pm.postalCode,
                    pm.subAdministrativeArea.map { "\($0)" },
                    pm.administrativeArea
                ].compactMap { $0 }
                addressText = parts.isEmpty ? service.city : parts.joined(separator: ", ")
            } else {
                addressText = service.city
            }
        } catch {
            addressText = service.city
        }
    }
}
