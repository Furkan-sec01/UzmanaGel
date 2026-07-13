import SwiftUI
import CoreLocation

struct LocationPickerSheet: View {

    @ObservedObject var locationManager: LocationManager
    let onDismiss: () -> Void

    @State private var searchText = ""

    private var filteredCities: [TurkishCity] {
        guard !searchText.isEmpty else { return turkishCities }
        let query = searchText.lowercased(with: Locale(identifier: "tr_TR"))
        return turkishCities.compactMap { city in
            let cityMatch = city.name
                .lowercased(with: Locale(identifier: "tr_TR"))
                .contains(query)

            let matchingDistricts = city.districts.filter {
                $0.lowercased(with: Locale(identifier: "tr_TR")).contains(query)
            }

            if cityMatch {
                return city
            } else if !matchingDistricts.isEmpty {
                return TurkishCity(city.name, matchingDistricts)
            }
            return nil
        }
    }

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Mevcut Konum
                Section {
                    Button {
                        locationManager.requestLocation()
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color("PrimaryColor").opacity(0.15))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "location.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color("PrimaryColor"))
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Mevcut Konumumu Kullan")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.primary)

                                if locationManager.isLoading {
                                    Text("Konum alınıyor…")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                } else if locationManager.authStatus == .denied {
                                    Text("Konum izni verilmedi. Ayarlardan açabilirsiniz.")
                                        .font(.system(size: 12))
                                        .foregroundColor(.red)
                                } else if locationManager.coordinate != nil {
                                    Text(locationManager.locationText)
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            if locationManager.isLoading {
                                ProgressView()
                            } else if locationManager.coordinate != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("Otomatik Konum")
                }

                // MARK: - Şehir Seçimi
                Section {
                    ForEach(filteredCities) { city in
                        DisclosureGroup {
                            ForEach(city.districts, id: \.self) { district in
                                Button {
                                    locationManager.setManualLocation(city: city.name, district: district)
                                    onDismiss()
                                } label: {
                                    HStack {
                                        Text(district)
                                            .font(.system(size: 14))
                                            .foregroundColor(.primary)
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "building.2")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                Text(city.name)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                } header: {
                    Text("Şehir ve İlçe Seçin")
                }
            }
            .searchable(text: $searchText, prompt: "Şehir veya ilçe ara…")
            .navigationTitle("Konum Seçin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") {
                        onDismiss()
                    }
                }
            }
            .onChange(of: locationManager.locationText) { _, _ in
                if locationManager.coordinate != nil && !locationManager.isLoading {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        onDismiss()
                    }
                }
            }
        }
    }
}
