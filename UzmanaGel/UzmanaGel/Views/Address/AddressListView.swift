//
//  AddressListView.swift
//  UzmanaGel
//
//  Created by Baran on 9.07.2026.
//


import SwiftUI

struct AddressListView: View {

    @StateObject private var vm = AddressViewModel()
    @State private var addressToDelete: UserAddress?
    @State private var showDeleteConfirm = false

    var body: some View {
        ZStack {
            Color("BackgroundColor").ignoresSafeArea()

            VStack(spacing: 0) {
                if vm.isLoading && vm.addresses.isEmpty {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if vm.addresses.isEmpty {
                    emptyView
                } else {
                    addressesList
                }

                addAddressButton
            }
        }
        .navigationTitle("Kayıtlı Adreslerim")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            vm.loadAddresses()
        }
        .alert("Adresi Sil", isPresented: $showDeleteConfirm, presenting: addressToDelete) { address in
            Button("İptal", role: .cancel) { }
            Button("Sil", role: .destructive) {
                if let id = address.id {
                    Task {
                        await vm.deleteAddress(id: id)
                    }
                }
            }
        } message: { address in
            Text("\"\(address.title)\" adresini silmek istediğinize emin misiniz?")
        }
    }

    // MARK: - Empty View
    private var emptyView: some View {
        VStack(spacing: 14) {
            Spacer()

            Image(systemName: "map.fill")
                .font(.system(size: 48))
                .foregroundColor(Color("TertiaryColor"))

            Text("Kayıtlı Adresiniz Yok")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color("Text"))

            Text("Aşağıdaki butona tıklayarak hemen yeni bir adres ekleyebilirsin.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
        }
    }

    // MARK: - Addresses List
    private var addressesList: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(vm.addresses) { address in
                    addressCard(for: address)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Address Card
    private func addressCard(for address: UserAddress) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Başlık & Varsayılan Badge
            HStack {
                Image(systemName: iconForTitle(address.title))
                    .foregroundColor(Color("TertiaryColor"))
                    .frame(width: 24, height: 24)

                Text(address.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color("Text"))

                if let tag = address.tag, !tag.isEmpty {
                    Text(tag)
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color("TertiaryColor").opacity(0.15))
                        .foregroundColor(Color("TertiaryColor"))
                        .clipShape(Capsule())
                }

                Spacer()

                if address.isDefault {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("VARSAYILAN")
                    }
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.15))
                    .foregroundColor(.orange)
                    .clipShape(Capsule())
                }
            }

            // Tam Adres
            Text(address.fullAddress.isEmpty ? "\(address.district), \(address.city)" : address.fullAddress)
                .font(.system(size: 14))
                .foregroundColor(Color("Text").opacity(0.85))
                .lineLimit(2)

            // Bina, Daire, Kat Detayları
            let details = formatDetails(address: address)
            if !details.isEmpty {
                Text(details)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            // Tarif Notu
            if !address.directionsNote.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text(address.directionsNote)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // Butonlar: Varsayılan Yap / Düzenle / Sil
            HStack {
                if !address.isDefault {
                    Button {
                        if let id = address.id {
                            Task {
                                await vm.setDefaultAddress(id: id)
                            }
                        }
                    } label: {
                        Text("Varsayılan Yap")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color("TertiaryColor"))
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                NavigationLink {
                    AddEditAddressView(address: address) {
                        vm.loadAddresses()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                        Text("Düzenle")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color("Text"))
                }
                .buttonStyle(.plain)

                Button {
                    addressToDelete = address
                    showDeleteConfirm = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                        Text("Sil")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .padding(.leading, 12)
            }
        }
        .padding(16)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    // MARK: - Add Button
    private var addAddressButton: some View {
        NavigationLink {
            AddEditAddressView(address: nil) {
                vm.loadAddresses()
            }
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Yeni Adres Ekle")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color("PrimaryColor"))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color("PrimaryColor").opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .padding(.top, 8)
    }

    // MARK: - Helpers
    private func iconForTitle(_ title: String) -> String {
        switch title.lowercased() {
        case "ev": return "house.fill"
        case "i̇ş", "is": return "briefcase.fill"
        default: return "mappin.circle.fill"
        }
    }

    private func formatDetails(address: UserAddress) -> String {
        var parts: [String] = []
        if !address.buildingNo.isEmpty { parts.append("Bina: \(address.buildingNo)") }
        if !address.apartmentNo.isEmpty { parts.append("Daire: \(address.apartmentNo)") }
        if !address.floor.isEmpty { parts.append("Kat: \(address.floor)") }
        return parts.joined(separator: " • ")
    }
}

#Preview {
    NavigationStack {
        AddressListView()
    }
}
