import Foundation
import Combine
import FirebaseFirestore
import FirebaseStorage

///HomepageViewModel, ana sayfadaki servis yükleme, arama, filtreleme, sıralama, konum-mesafe, sesli arama, favori ve servis görselleri mantığını yönetir.

@MainActor
final class HomepageViewModel: ObservableObject {

    // MARK: - Published

    @Published var searchText: String = ""
    @Published var isLoading = false
    @Published var isLoadingNextPage = false
    @Published var errorMessage: String?
    @Published var filter = ServiceFilter()
    @Published var imageURLs: [String: URL] = [:]

    let locationManager = LocationManager()
    let speechRecognizer = SpeechRecognizer()

    var selectedLocation: String {
        locationManager.locationText
    }

    /// Filtreleme + arama + sıralama uygulanmış liste
    var filteredServices: [Service] {
        var result = allServices

        // Metin araması (providerName, title, category, city, description)
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            let lower = query.lowercased(with: Locale(identifier: "tr_TR"))
            result = result.filter { service in
                service.providerName.lowercased(with: Locale(identifier: "tr_TR")).contains(lower) ||
                service.title.lowercased(with: Locale(identifier: "tr_TR")).contains(lower) ||
                service.category.lowercased(with: Locale(identifier: "tr_TR")).contains(lower) ||
                service.city.lowercased(with: Locale(identifier: "tr_TR")).contains(lower) ||
                service.description.lowercased(with: Locale(identifier: "tr_TR")).contains(lower)
            }
        }

        // Kategori filtresi (boş string koruması)
        if let cat = filter.selectedCategory, !cat.isEmpty {
            result = result.filter { $0.category == cat }
        }

        // Şehir filtresi (boş string koruması)
        if let city = filter.selectedCity, !city.isEmpty {
            result = result.filter { $0.city == city }
        }

        // Fiyat aralığı (negatif değer koruması)
        if let min = filter.minPrice, min > 0 {
            result = result.filter { $0.price >= min }
        }
        if let max = filter.maxPrice, max > 0 {
            result = result.filter { $0.price <= max }
        }

        // Mesafe filtresi (km)
        if let maxKm = filter.maxDistanceKm, maxKm > 0 {
            result = result.filter { service in
                guard let geo = service.locationGeo else { return false }
                guard let km = locationManager.distance(to: geo.latitude, geoLng: geo.longitude) else { return false }
                return km <= maxKm
            }
        }

        // Müsaitlik filtresi
        if filter.isTodayAvailable || filter.isThisWeekAvailable || filter.selectedDate != nil || filter.startTime != nil || filter.endTime != nil {
            result = result.filter { $0.isAvailable }
        }

        // Değerlendirme filtresi
        if let minRating = filter.minRating, minRating > 0 {
            result = result.filter { service in
                let effectiveRating = service.reviewCount > 0 ? service.rating : 0.0
                return effectiveRating >= minRating
            }
        }

        // Gelişmiş filtreler
        if filter.minExperienceYears > 0 {
            result = result.filter { $0.experienceYears >= filter.minExperienceYears }
        }
        if filter.minCompletedJobs > 0 {
            result = result.filter { $0.completedJobsCount >= filter.minCompletedJobs }
        }
        if filter.isCertifiedOnly {
            result = result.filter { $0.isCertified }
        }
        if let type = filter.selectedServiceType, !type.isEmpty {
            result = result.filter { $0.serviceType.lowercased() == type.lowercased() }
        }


        // Sıralama
        switch filter.sortOption {
        case .priceLowToHigh:
            result.sort { $0.price < $1.price }
        case .priceHighToLow:
            result.sort { $0.price > $1.price }
        case .none:
            break
        }

        return result
    }

    /// Servislerdeki benzersiz kategoriler (filtre için, boş olanları atla)
    var availableCategories: [String] {
        Array(Set(allServices.map(\.category)))
            .filter { !$0.isEmpty }
            .sorted { $0.localizedCompare($1) == .orderedAscending }
    }

    /// Servislerdeki benzersiz şehirler (filtre için, boş olanları atla)
    var availableCities: [String] {
        Array(Set(allServices.map(\.city)))
            .filter { !$0.isEmpty }
            .sorted { $0.localizedCompare($1) == .orderedAscending }
    }

    // MARK: - Private

    @Published private var allServices: [Service] = []
    private let repo = ServiceRepository()
    private let favRepo = FavoritesRepository()
    private var favoriteIds = Set<String>()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init() {
        locationManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        // Ses tanıma sonucunu arama metnine yansıt
        speechRecognizer.$transcript
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                guard let self, !text.isEmpty else { return }
                self.searchText = text
            }
            .store(in: &cancellables)

        speechRecognizer.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    // MARK: - Public

    func load() {
        guard !isLoading else { return }
        Task {
            locationManager.requestLocation()
            await fetchServices()
            await fetchFavorites()
            print("🏠 load() tamamlandı — isLoading: \(isLoading), servis: \(allServices.count), filtre sonucu: \(filteredServices.count)")
        }
    }
    
    func loadNextPage() {
        guard !isLoading else { return }
        guard !isLoadingNextPage else { return }

        Task {
            isLoadingNextPage = true
            defer { isLoadingNextPage = false }

            do {
                let nextServices = try await repo.fetchNextActiveServicesPage()

                guard !nextServices.isEmpty else {
                    print("📄 No more services")
                    return
                }

                /// Avoid duplicate services
                let existingIds = Set(allServices.map(\.serviceId))

                let uniqueServices = nextServices.filter {
                    !existingIds.contains($0.serviceId)
                }

                /// Add new services to the current list
                allServices.append(contentsOf: uniqueServices)

                // Use image URL from service data
                for service in uniqueServices {
                    guard !service.image.isEmpty,
                          let url = URL(string: service.image) else {
                        continue
                    }

                    imageURLs[service.serviceId] = url
                }

                /// Load missing images from Storage
                for service in uniqueServices {
                    loadImage(for: service.serviceId)
                }

                print("📄 New services: \(uniqueServices.count)")
                print("📦 Total services: \(allServices.count)")

            } catch {
                print("⚠️ Next page error: \(error)")
                errorMessage = error.localizedDescription
            }
        }
    }

    /// Servisin kullanıcıya olan uzaklığını formatlanmış metin olarak döner
    func distanceText(for service: Service) -> String? {
        guard let geo = service.locationGeo else { return nil }
        guard let km = locationManager.distance(to: geo.latitude, geoLng: geo.longitude) else { return nil }
        if km < 1.0 {
            return "\(Int(km * 1000)) m"
        } else {
            return String(format: "%.1f km", km)
        }
    }

    func isFavorite(serviceId: String) -> Bool {
        favoriteIds.contains(serviceId)
    }

    func toggleFavorite(serviceId: String) {
        Task {
            do {
                if favoriteIds.contains(serviceId) {
                    try await favRepo.removeFavorite(serviceId: serviceId)
                    favoriteIds.remove(serviceId)
                } else {
                    try await favRepo.addFavorite(serviceId: serviceId)
                    favoriteIds.insert(serviceId)
                }
                objectWillChange.send()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func clearError() {
        errorMessage = nil
    }

    /// Tek bir servis için Storage klasöründen ilk görseli çek ve cache'le
    /// Path: service_images/{serviceId}/ → klasördeki ilk dosya
    func loadImage(for serviceId: String) {
        guard !serviceId.isEmpty, imageURLs[serviceId] == nil else { return }

        let folderRef = Storage.storage().reference().child("service_images/\(serviceId)")

        folderRef.list(maxResults: 1) { [weak self] result, error in
            if let error = error {
                print("📷 [\(serviceId)] list error: \(error.localizedDescription)")
                return
            }

            guard let item = result?.items.first else {
                print("📷 [\(serviceId)] klasörde dosya yok")
                return
            }

            item.downloadURL { [weak self] url, error in
                if let error = error {
                    print("📷 [\(serviceId)] downloadURL error: \(error.localizedDescription)")
                    return
                }
                guard let url = url else { return }
                DispatchQueue.main.async {
                    self?.imageURLs[serviceId] = url
                    print("📷 [\(serviceId)] fotoğraf bulundu ✅")
                }
            }
        }
    }

    /// Servis listesi yüklendiğinde tüm görselleri yükle
    private func loadAllImages() {
        for service in allServices {
            loadImage(for: service.serviceId)
        }
    }

    // MARK: - Private Fetch

    private func fetchServices() async {
        isLoading = true
        defer { isLoading = false }

        do {
            allServices = try await repo.fetchActiveServices()
            print("Yüklenen servis sayısı: \(allServices.count)")
            // İlan fotoğrafı: servis dokümanındaki image URL varsa hemen kullan (anasayfada tıklanmadan görünsün)
            for service in allServices {
                guard !service.image.isEmpty, let url = URL(string: service.image) else { continue }
                imageURLs[service.serviceId] = url
            }
            loadAllImages()
        } catch {
            print("fetchServices hatası: \(error)")
            errorMessage = error.localizedDescription
        }
    }

    private func fetchFavorites() async {
        do {
            let ids = try await favRepo.fetchFavoriteServiceIds()
            favoriteIds = Set(ids)
            objectWillChange.send()
            print("❤️ Favori sayısı: \(ids.count)")
        } catch {
            // Favoriler yüklenemezse sadece logla, ana akışı bozma
            print("⚠️ fetchFavorites hatası (servisler etkilenmez): \(error)")
        }
    }
}
