import Foundation
import Combine
import FirebaseFirestore
import FirebaseStorage
import CoreLocation

///ServiceDetailViewModel, müşteri hizmet detay ekranında uzman bilgilerini, portföyü, diğer ilanları, adresi, çalışma saatlerini, favori durumunu ve yol tarifini yönetir.

@MainActor
final class ServiceDetailViewModel: ObservableObject {

    // MARK: - Published

    @Published var providerServices: [Service] = []
    @Published var galleryURLs: [URL] = []
    @Published var coverImageURL: URL?
    @Published var addressText: String = ""
    @Published var isFavorite: Bool
    @Published var isLoading = false
<<<<<<< HEAD
    @Published var providerIsAvailable = true
    @Published var didLoadProviderAvailability = false
    @Published var providerAvailabilityLoadFailed = false

    /// Uzmanın çalışma saatleri / günleri (service_providers'dan; müşteri tarafında gösterilir)
=======
>>>>>>> d7dac80 (feat: Apply advanced filters, review functionality and compact UI)
    @Published var expertProfile: ExpertProfile?
    @Published var reviewCount: Int = 0
    @Published var averageRating: Double = 0.0

    let service: Service

    private let serviceRepo = ServiceRepository()
    private let favRepo = FavoritesRepository()
    private let userRepo = UserRepository()

    // MARK: - Init

    init(service: Service, imageURL: URL?, isFavorite: Bool) {
        self.service = service
        self.coverImageURL = imageURL
        self.isFavorite = isFavorite
        self.providerIsAvailable = service.providerIsAvailable
    }

    // MARK: - Public

    func load() {
        guard !isLoading else { return }
        isLoading = true

        Task {
            async let servicesTask: () = fetchProviderServices()
            async let galleryTask: () = fetchGalleryImages()
            async let addressTask: () = resolveAddress()
            async let availabilityTask: () = fetchProviderAvailability()
            async let reviewTask: () = fetchReviewSummary()

            _ = await (
                servicesTask,
                galleryTask,
                addressTask,
                availabilityTask,
                reviewTask
            )

            if coverImageURL == nil {
                loadCoverImage()
            }

            isLoading = false
        }
    }

    var canCreateReservation: Bool {
        didLoadProviderAvailability
            && service.isActive
            && service.isAvailable
            && providerIsAvailable
    }

    var reservationAvailabilityMessage: String? {
        if providerAvailabilityLoadFailed {
            return "Uzman müsaitliği doğrulanamadı. Lütfen tekrar deneyin."
        }

        if !didLoadProviderAvailability {
            return "Uzman müsaitliği kontrol ediliyor."
        }

        if !service.isActive || !service.isAvailable {
            return "Bu hizmet şu anda rezervasyona kapalı."
        }

        if !providerIsAvailable {
            return "Uzman şu anda yeni rezervasyon kabul etmiyor."
        }

        return nil
    }

    /// Uzmanın çalışma günlerini Türkçe kısa isimle döndürür (workingDays: "1"=Pazartesi ... "7"=Pazar). Sıra: Pzt→Paz.
    var workingDaysDisplayNames: [String] {
        let order = ["1", "2", "3", "4", "5", "6", "7"]
        let map: [String: String] = [
            "1": "Pazartesi", "2": "Salı", "3": "Çarşamba", "4": "Perşembe",
            "5": "Cuma", "6": "Cumartesi", "7": "Pazar"
        ]
        let days = expertProfile?.workingDays ?? []
        return order.filter { days.contains($0) }.map { (map[$0] ?? $0).localized }
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

    private func fetchProviderAvailability() async {
        guard !service.providerId.isEmpty else {
            providerIsAvailable = false
            providerAvailabilityLoadFailed = true
            didLoadProviderAvailability = true
            return
        }

        do {
            providerIsAvailable =
                try await userRepo.fetchExpertAvailability(
                    uid: service.providerId
                )

            providerAvailabilityLoadFailed = false
        } catch {
            providerIsAvailable = false
            providerAvailabilityLoadFailed = true

            print(
                "⚠️ Uzman müsaitliği yüklenemedi: " +
                error.localizedDescription
            )
        }

        didLoadProviderAvailability = true
    }

    private func fetchProviderServices() async {
        guard !service.providerId.isEmpty else { return }
        do {
            let services = try await serviceRepo.fetchServicesByProviderId(service.providerId)
            
            providerServices = services.filter{
                $0.serviceId != service.serviceId
            }
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

    private func fetchReviewSummary() async {
        guard !service.providerId.isEmpty else { return }
        do {
            let reviews = try await ReviewRepository().fetchReviews(forProviderId: service.providerId)
            self.reviewCount = reviews.count
            if !reviews.isEmpty {
                let sum = reviews.reduce(0.0) { $0 + $1.rating }
                self.averageRating = sum / Double(reviews.count)
            } else {
                self.reviewCount = service.reviewCount
                self.averageRating = service.rating
            }
        } catch {
            self.reviewCount = service.reviewCount
            self.averageRating = service.rating
        }
    }
}
