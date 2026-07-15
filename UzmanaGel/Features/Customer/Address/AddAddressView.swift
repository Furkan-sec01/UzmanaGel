import SwiftUI
import MapKit

struct AddAddressView: View {
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
    
    private let addressService: AddressService = MockAddressService()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground.ignoresSafeArea()
                
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
                                
                                // Center Target Pin Overlay
                                Image(systemName: "mappin")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 32, height: 32)
                                    .foregroundColor(Color.themeError)
                                    .offset(y: -16)
                            }
                            .padding(.horizontal)
                            
                            Button {
                                Task {
                                    await resolveSimulatedAddress()
                                }
                            } label: {
                                HStack {
                                    if isResolvingAddress {
                                        ProgressView()
                                            .tint(Color.themePrimary)
                                    } else {
                                        Image(systemName: "location.magnifyingglass")
                                        Text("Seçili Konumu Çözümle")
                                    }
                                }
                                .font(.footnote)
                                .fontWeight(.bold)
                                .foregroundColor(Color.themePrimary)
                                .padding(.horizontal)
                            }
                        }
                        
                        // Address Details Form
                        CardView {
                            VStack(alignment: .leading, spacing: Constants.spacingM) {
                                // Address Title (tag)
                                Picker("Adres Tipi", selection: $selectedTag) {
                                    Text("Ev").tag("Ev")
                                    Text("İş").tag("İş")
                                    Text("Diğer").tag("Diğer")
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Adres Başlığı (Örn: Evim, Ofis)")
                                        .font(.caption)
                                        .foregroundColor(Color.themeSecondaryText)
                                    TextField("Adres Başlığı", text: $title)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Açık Adres")
                                        .font(.caption)
                                        .foregroundColor(Color.themeSecondaryText)
                                    TextEditor(text: $fullAddress)
                                        .frame(height: 60)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color.themeBorder, lineWidth: 1)
                                        )
                                }
                                
                                HStack(spacing: Constants.spacingM) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("İlçe")
                                            .font(.caption)
                                            .foregroundColor(Color.themeSecondaryText)
                                        TextField("İlçe", text: $district)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                    }
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Şehir")
                                            .font(.caption)
                                            .foregroundColor(Color.themeSecondaryText)
                                        TextField("Şehir", text: $city)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                    }
                                }
                                
                                HStack(spacing: Constants.spacingS) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Bina No")
                                            .font(.caption)
                                            .foregroundColor(Color.themeSecondaryText)
                                        TextField("Bina No", text: $buildingNo)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                    }
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Kat")
                                            .font(.caption)
                                            .foregroundColor(Color.themeSecondaryText)
                                        TextField("Kat", text: $floor)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                    }
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Daire")
                                            .font(.caption)
                                            .foregroundColor(Color.themeSecondaryText)
                                        TextField("Daire", text: $apartmentNo)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Adres Tarifi / Ulaşım Notu")
                                        .font(.caption)
                                        .foregroundColor(Color.themeSecondaryText)
                                    TextField("Zil çalmıyorsa güvenliği arayın, vb.", text: $directionsNote)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                Toggle("Varsayılan Adres Yap", isOn: $isDefault)
                                    .tint(Color.themePrimary)
                                    .font(.subheadline)
                                    .padding(.vertical, 4)
                                
                                Button {
                                    Task {
                                        await saveAddress()
                                    }
                                } label: {
                                    Text("Adresi Kaydet")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.themePrimary)
                                        .clipShape(RoundedRectangle(cornerRadius: Constants.radiusM))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Yeni Adres Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func resolveSimulatedAddress() async {
        isResolvingAddress = true
        // Simulate geocoding delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        district = "Kadıköy"
        city = "İstanbul"
        fullAddress = "Moda Cd. Şair Nefi Sok. No: 15"
        buildingNo = "15"
        isResolvingAddress = false
    }
    
    private func saveAddress() async {
        guard !title.isEmpty && !fullAddress.isEmpty else { return }
        
        let newAddr = Address(
            id: "",
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
        
        do {
            let saved = try await addressService.addAddress(newAddr)
            onSaveSuccess(saved)
            dismiss()
        } catch {
            // Error handling
        }
    }
}

#Preview {
    AddAddressView { _ in }
}
