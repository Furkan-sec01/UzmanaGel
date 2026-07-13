//
//  AddEditAddressView.swift
//  UzmanaGel
//
//  Created by Baran on 9.07.2026.
//


import SwiftUI
import MapKit
import CoreLocation

struct AddEditAddressView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = AddressViewModel()

    let address: UserAddress?
    let onSave: () -> Void

    // Form Alanları
    @State private var title: String = "Ev"
    @State private var fullAddress: String = ""
    @State private var city: String = "İstanbul"
    @State private var district: String = ""
    @State private var buildingNo: String = ""
    @State private var apartmentNo: String = ""
    @State private var floor: String = ""
    @State private var directionsNote: String = ""
    @State private var tag: String = ""
    @State private var isDefault: Bool = false

    // Harita & Geocoding
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784), // Varsayılan: İstanbul
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var selectedCoordinate = CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784)
    @State private var isGeocoding = false

    private let titleOptions = ["Ev", "İş", "Diğer"]

    init(address: UserAddress?, onSave: @escaping () -> Void = {}) {
        self.address = address
        self.onSave = onSave
    }

    var body: some View {
        ZStack {
            Color("BackgroundColor").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    mapSection
                    titleSection
                    addressDetailsSection
                    extraInfoSection
                    defaultToggleSection
                    saveButton
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle(address == nil ? "Yeni Adres Ekle" : "Adresi Düzenle")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            populateInitialData()
        }
    }

    // MARK: - Harita Seçimi
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("HARİTADA KONUM SEÇ")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)

                Spacer()

                if isGeocoding {
                    HStack(spacing: 4) {
                        ProgressView().scaleEffect(0.7)
                        Text("Adres çözümleniyor...")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }

            ZStack {
                Map(coordinateRegion: $region, interactionModes: .all, annotationItems: [PinItem(coordinate: selectedCoordinate)]) { item in
                    MapAnnotation(coordinate: item.coordinate) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(Color("TertiaryColor"))
                            .shadow(radius: 3)
                    }
                }
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            updateSelectedLocation(to: region.center)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "mappin.and.ellipse")
                                Text("Bu Konumu Seç")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color("CardBackground"))
                            .foregroundColor(Color("Text"))
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                        }
                        .padding(10)
                    }
                }
            }
        }
    }

    // MARK: - Başlık
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ADRES BAŞLIĞI")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)

            HStack(spacing: 10) {
                ForEach(titleOptions, id: \.self) { option in
                    Button {
                        title = option
                    } label: {
                        Text(option)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(title == option ? .white : Color("Text"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(title == option ? Color("PrimaryColor") : Color("CardBackground"))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Adrees Detay
    private var addressDetailsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ADRES BİLGİLERİ")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)

            VStack(spacing: 12) {
                HStack {
                    TextField("İl", text: $city)
                        .font(.system(size: 14))
                    Divider().frame(height: 18)
                    TextField("İlçe", text: $district)
                        .font(.system(size: 14))
                }
                .padding(12)
                .background(Color("BackgroundColor"))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                TextField("Tam Açık Adres (Sokak, Mahalle vb.)", text: $fullAddress, axis: .vertical)
                    .lineLimit(2...4)
                    .font(.system(size: 14))
                    .padding(12)
                    .background(Color("BackgroundColor"))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                HStack(spacing: 10) {
                    inputBox("Bina No", text: $buildingNo)
                    inputBox("Kat", text: $floor)
                    inputBox("Daire", text: $apartmentNo)
                }
            }
            .padding(14)
            .background(Color("CardBackground"))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        }
    }

    // MARK: - Extra bilgiler
    private var extraInfoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TARİF / NOT")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)

            VStack(spacing: 12) {
                TextField("Adres tarifi veya not (Örn: Kapı zili çalışmıyor)", text: $directionsNote, axis: .vertical)
                    .lineLimit(2...3)
                    .font(.system(size: 14))
                    .padding(12)
                    .background(Color("BackgroundColor"))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                TextField("İsteğe Bağlı Etiket (Örn: Yazlık, Annem vb.)", text: $tag)
                    .font(.system(size: 14))
                    .padding(12)
                    .background(Color("BackgroundColor"))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(14)
            .background(Color("CardBackground"))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        }
    }

    // MARK: - Default Toggle Section
    private var defaultToggleSection: some View {
        HStack {
            Toggle(isOn: $isDefault) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Varsayılan Adres")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color("Text"))
                    Text("Siparişlerinizde otomatik seçilir")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .tint(Color("TertiaryColor"))
        }
        .padding(14)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    // MARK: - Kayıt Button
    private var saveButton: some View {
        Button {
            save()
        } label: {
            HStack {
                if vm.isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(address == nil ? "Adresi Kaydet" : "Değişiklikleri Kaydet")
                        .font(.system(size: 16, weight: .bold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color("PrimaryColor"))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color("PrimaryColor").opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(fullAddress.trimmingCharacters(in: .whitespaces).isEmpty || vm.isLoading)
        .opacity(fullAddress.trimmingCharacters(in: .whitespaces).isEmpty ? 0.6 : 1.0)
    }

    // MARK: - Components
    private func inputBox(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .font(.system(size: 14))
            .padding(12)
            .background(Color("BackgroundColor"))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Helpers
    private func populateInitialData() {
        if let address = address {
            title = address.title
            fullAddress = address.fullAddress
            city = address.city
            district = address.district
            buildingNo = address.buildingNo
            apartmentNo = address.apartmentNo
            floor = address.floor
            directionsNote = address.directionsNote
            tag = address.tag ?? ""
            isDefault = address.isDefault

            if let lat = address.latitude, let lng = address.longitude {
                selectedCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                region = MKCoordinateRegion(center: selectedCoordinate, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005))
            }
        }
    }

    private func updateSelectedLocation(to coord: CLLocationCoordinate2D) {
        selectedCoordinate = coord
        reverseGeocode(coordinate: coord)
    }

    private func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        isGeocoding = true
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                self.isGeocoding = false
                guard let placemark = placemarks?.first, error == nil else { return }

                if let adminArea = placemark.administrativeArea {
                    self.city = adminArea
                }
                if let subAdminArea = placemark.subAdministrativeArea ?? placemark.locality {
                    self.district = subAdminArea
                }

                var addressParts: [String] = []
                if let thoroughfare = placemark.thoroughfare {
                    addressParts.append(thoroughfare)
                }
                if let subThoroughfare = placemark.subThoroughfare {
                    addressParts.append("No: \(subThoroughfare)")
                }
                if let subLocality = placemark.subLocality {
                    addressParts.append(subLocality)
                }

                if !addressParts.isEmpty {
                    self.fullAddress = addressParts.joined(separator: ", ")
                }
            }
        }
    }

    private func save() {
        let updatedAddress = UserAddress(
            id: address?.id,
            title: title,
            fullAddress: fullAddress,
            city: city,
            district: district,
            buildingNo: buildingNo,
            apartmentNo: apartmentNo,
            floor: floor,
            directionsNote: directionsNote,
            tag: tag.isEmpty ? nil : tag,
            isDefault: isDefault,
            latitude: selectedCoordinate.latitude,
            longitude: selectedCoordinate.longitude,
            createdAt: address?.createdAt
        )

        Task {
            let success = await vm.saveAddress(updatedAddress)
            if success {
                onSave()
                dismiss()
            }
        }
    }
}

// MARK: - Pin Item Helper
private struct PinItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

