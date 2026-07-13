import Foundation
import CoreLocation
import Combine

final class LocationManager: ObservableObject, @unchecked Sendable {

    // MARK: - Published

    @Published var locationText: String = "Konum belirleniyor…"
    @Published var coordinate: CLLocationCoordinate2D?
    @Published var authStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLoading = false

    // MARK: - Private

    private let clManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private let delegate: LocationDelegate

    // MARK: - Init

    init() {
        delegate = LocationDelegate()
        delegate.owner = self
        clManager.delegate = delegate
        clManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authStatus = clManager.authorizationStatus
    }

    // MARK: - Public API

    /// Konum izni iste ve konumu al
    func requestLocation() {
        isLoading = true

        switch clManager.authorizationStatus {
        case .notDetermined:
            clManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            clManager.requestLocation()
        case .denied, .restricted:
            isLoading = false
            locationText = "Konum izni verilmedi"
        @unknown default:
            isLoading = false
        }
    }

    /// Manuel şehir seçimi — forward geocode ile koordinat da alınır
    func setManualLocation(city: String, district: String?) {
        if let district {
            locationText = "\(district), \(city)"
        } else {
            locationText = city
        }

        // Seçilen il/ilçeyi geocode ederek koordinat bul
        let query = district != nil ? "\(district!), \(city), Türkiye" : "\(city), Türkiye"
        isLoading = true
        geocoder.geocodeAddressString(query) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                if let location = placemarks?.first?.location {
                    self.coordinate = location.coordinate
                } else {
                    self.coordinate = nil
                    print("⚠️ Forward geocode başarısız: \(error?.localizedDescription ?? "bilinmeyen hata")")
                }
            }
        }
    }

    /// İki koordinat arası mesafe (km)
    func distance(to geoLat: Double, geoLng: Double) -> Double? {
        guard let coord = coordinate else { return nil }
        let from = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        let to   = CLLocation(latitude: geoLat, longitude: geoLng)
        return from.distance(from: to) / 1000.0   // metre → km
    }

    // MARK: - Reverse Geocode

    fileprivate func reverseGeocode(_ location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false

                if let error {
                    print("❌ Geocode hatası: \(error.localizedDescription)")
                    self.locationText = "Konum alınamadı"
                    return
                }

                guard let placemark = placemarks?.first else {
                    self.locationText = "Konum alınamadı"
                    return
                }

                let district = placemark.subAdministrativeArea ?? placemark.locality ?? ""
                let city = placemark.administrativeArea ?? ""

                if !district.isEmpty && !city.isEmpty {
                    self.locationText = "\(district), \(city)"
                } else if !city.isEmpty {
                    self.locationText = city
                } else {
                    self.locationText = "Konum alınamadı"
                }
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate (ayrı NSObject alt sınıfı)

private final class LocationDelegate: NSObject, CLLocationManagerDelegate {

    weak var owner: LocationManager?

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async { [weak self] in
            guard let owner = self?.owner else { return }
            owner.coordinate = location.coordinate
            owner.reverseGeocode(location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Konum hatası: \(error.localizedDescription)")
        DispatchQueue.main.async { [weak self] in
            guard let owner = self?.owner else { return }
            owner.isLoading = false
            owner.locationText = "Konum alınamadı"
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        DispatchQueue.main.async { [weak self] in
            guard let owner = self?.owner else { return }
            owner.authStatus = status
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
            case .denied, .restricted:
                owner.isLoading = false
                owner.locationText = "Konum izni verilmedi"
            default:
                break
            }
        }
    }
}
