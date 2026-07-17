//
//  AddAddressView.swift
//  UzmanaGel
//
//  Created by Antigravity on 17.07.2026.
//

import SwiftUI
import MapKit
import CoreLocation

struct AddAddressView: View {
    let address: Address?
    var onSaveSuccess: (Address) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var fullAddress: String = ""
    @State private var city: String = "İstanbul"
    @State private var district: String = ""
    @State private var buildingNo: String = ""
    @State private var apartmentNo: String = ""
    @State private var floor: String = ""
    @State private var directionsNote: String = ""
    @State private var selectedTag: String = "Ev"
    @State private var isDefault: Bool = false
    
    // Map State (iOS 17+ Map Camera Position)
    @State private var position = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784), // Istanbul Center
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
    )
    @State private var centerCoordinate = CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784)
    @State private var isResolvingAddress = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showErrorAlert = false
    
    private let addressService: AddressService = FirestoreAddressService()
    private let accentYellow = Color("TertiaryColor")
    
    init(address: Address? = nil, onSaveSuccess: @escaping (Address) -> Void) {
        self.address = address
        self.onSaveSuccess = onSaveSuccess
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("BackgroundColor").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Constants.spacingM) {
                        // Map Picker Card
                        VStack(alignment: .leading, spacing: Constants.spacingS) {
                            Text("Haritadan Konum Seçin")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(Color.themeSecondaryText)
                                .padding(.horizontal)
                            
                            ZStack {
                                Map(position: $position)
                                    .frame(height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: Constants.radiusL))
                                    .onMapCameraChange { context in
                                        centerCoordinate = context.region.center
                                    }
                                
                                // Center Target Pin Overlay
                                Image(systemName: "mappin")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 32, height: 32)
                                    .foregroundColor(Color("TertiaryColor"))
                                    .offset(y: -16)
                            }
                            .padding(.horizontal)
                            
                            Button {
                                Task {
                                    await resolveSelectedAddress()
                                }
                            } label: {
                                HStack {
                                    if isResolvingAddress {
                                        ProgressView()
                                            .tint(Color("TertiaryColor"))
                                    } else {
                                        Image(systemName: "location.magnifyingglass")
                                        Text("Seçili Konumu Çözümle")
                                    }
                                }
                                .font(.footnote)
                                .fontWeight(.bold)
                                .foregroundColor(Color("TertiaryColor"))
                                .padding(.horizontal)
                            }
                            .disabled(isResolvingAddress)
                        }
                        
                        // Address Details Form
                        VStack(alignment: .leading, spacing: Constants.spacingM) {
                            // Address Title Tag Picker
                            Picker("Adres Tipi", selection: $selectedTag) {
                                Text("Ev").tag("Ev")
                                Text("İş").tag("İş")
                                Text("Diğer").tag("Diğer")
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.bottom, 4)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Adres Başlığı (Örn: Evim, Ofis)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.themeSecondaryText)
                                customTextField("Adres Başlığı", text: $title)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Açık Adres")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.themeSecondaryText)
                                customTextEditor(text: $fullAddress)
                            }
                            
                            HStack(spacing: Constants.spacingM) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("İlçe")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color.themeSecondaryText)
                                    customTextField("İlçe", text: $district)
                                }
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Şehir")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color.themeSecondaryText)
                                    customTextField("Şehir", text: $city)
                                }
                            }
                            
                            HStack(spacing: Constants.spacingS) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Bina No")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color.themeSecondaryText)
                                    customTextField("Bina No", text: $buildingNo)
                                }
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Kat")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color.themeSecondaryText)
                                    customTextField("Kat", text: $floor)
                                }
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Daire")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color.themeSecondaryText)
                                    customTextField("Daire", text: $apartmentNo)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Adres Tarifi / Ulaşım Notu")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.themeSecondaryText)
                                customTextField("Zil çalmıyorsa güvenliği arayın, vb.", text: $directionsNote)
                            }
                            
                            Toggle("Varsayılan Adres Yap", isOn: $isDefault)
                                .tint(Color("TertiaryColor"))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color.themeText)
                                .padding(.vertical, 4)
                            
                            Button {
                                Task {
                                    await saveAddress()
                                }
                            } label: {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text(address == nil ? "Adresi Kaydet" : "Değişiklikleri Kaydet")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("TertiaryColor"))
                                .clipShape(RoundedRectangle(cornerRadius: Constants.radiusM))
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(isLoading)
                        }
                        .padding(16)
                        .background(Color("CardBackground"))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color("TertiaryColor").opacity(0.07), radius: 8, x: 0, y: 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(Color("TertiaryColor").opacity(0.12), lineWidth: 1)
                        )
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle(address == nil ? "Yeni Adres Ekle" : "Adresi Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                populateInitialData()
            }
            .alert("Hata", isPresented: $showErrorAlert) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Custom Premium Inputs
    private func customTextField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .font(.subheadline)
            .padding(.horizontal, Constants.paddingM)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: Constants.radiusM)
                    .fill(Color("BackgroundColor"))
                    .overlay(
                        RoundedRectangle(cornerRadius: Constants.radiusM)
                            .stroke(Color("TertiaryColor").opacity(0.25), lineWidth: 1)
                    )
            )
            .foregroundColor(Color.themeText)
    }
    
    private func customTextEditor(text: Binding<String>) -> some View {
        TextEditor(text: text)
            .font(.subheadline)
            .padding(Constants.paddingS)
            .frame(height: 72)
            .scrollContentBackground(.hidden)
            .background(
                RoundedRectangle(cornerRadius: Constants.radiusM)
                    .fill(Color("BackgroundColor"))
                    .overlay(
                        RoundedRectangle(cornerRadius: Constants.radiusM)
                            .stroke(Color("TertiaryColor").opacity(0.25), lineWidth: 1)
                    )
            )
            .foregroundColor(Color.themeText)
    }
    
    // MARK: - Address Resolution
    private func resolveSelectedAddress() async {
        isResolvingAddress = true
        let location = CLLocation(latitude: centerCoordinate.latitude, longitude: centerCoordinate.longitude)
        
        do {
            let placemarks = try await CLGeocoder().reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
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
                    self.buildingNo = subThoroughfare
                }
                if let subLocality = placemark.subLocality {
                    addressParts.append(subLocality)
                }
                
                if !addressParts.isEmpty {
                    self.fullAddress = addressParts.joined(separator: ", ")
                }
            }
        } catch {
            print("❌ Geocoding error: \(error.localizedDescription)")
        }
        
        isResolvingAddress = false
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
            selectedTag = address.tag ?? "Ev"
            isDefault = address.isDefault
            
            let coord = CLLocationCoordinate2D(
                latitude: address.latitude ?? 41.0082,
                longitude: address.longitude ?? 28.9784
            )
            centerCoordinate = coord
            position = MapCameraPosition.region(
                MKCoordinateRegion(
                    center: coord,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                )
            )
        }
    }
    
    private func saveAddress() async {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty &&
              !fullAddress.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Lütfen adres başlığı ve açık adres alanlarını doldurun."
            showErrorAlert = true
            return
        }
        
        let newAddr = Address(
            id: address?.id ?? "",
            title: title,
            fullAddress: fullAddress,
            city: city,
            district: district,
            buildingNo: buildingNo,
            apartmentNo: apartmentNo,
            floor: floor,
            directionsNote: directionsNote,
            tag: selectedTag,
            isDefault: isDefault,
            latitude: centerCoordinate.latitude,
            longitude: centerCoordinate.longitude
        )
        
        isLoading = true
        do {
            let saved: Address
            if address == nil {
                saved = try await addressService.addAddress(newAddr)
            } else {
                saved = try await addressService.updateAddress(newAddr)
            }
            onSaveSuccess(saved)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
        isLoading = false
    }
}

#Preview {
    AddAddressView { _ in }
}
