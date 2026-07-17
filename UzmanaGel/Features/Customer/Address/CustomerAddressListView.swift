//
//  CustomerAddressListView.swift
//  UzmanaGel
//
//  Created by Antigravity on 17.07.2026.
//

import SwiftUI

struct CustomerAddressListView: View {
    @StateObject private var viewModel = AddressListViewModel()
    @State private var showingAddAddress = false
    @State private var addressToEdit: Address? = nil
    @State private var addressToDelete: Address? = nil
    @State private var showDeleteConfirm = false
    
    // App yellow accent
    private let accentYellow = Color("TertiaryColor")
    
    var body: some View {
        ZStack {
            Color("BackgroundColor").ignoresSafeArea()
            
            if viewModel.isLoading && viewModel.addresses.isEmpty {
                LoadingView(message: "Adresleriniz yükleniyor...")
            } else if viewModel.addresses.isEmpty {
                emptyStateSection
            } else {
                List {
                    ForEach(viewModel.addresses) { address in
                        addressCard(address)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                    .onDelete { indexSet in
                        guard let index = indexSet.first else { return }
                        addressToDelete = viewModel.addresses[index]
                        showDeleteConfirm = true
                    }
                }
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .refreshable {
                    await viewModel.loadAddresses()
                }
            }
        }
        .background(Color("BackgroundColor").ignoresSafeArea())
        .navigationTitle("Adreslerim")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddAddress = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(accentYellow.opacity(0.15))
                            .frame(width: 34, height: 34)
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(accentYellow)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddAddress, onDismiss: {
            Task { await viewModel.loadAddresses() }
        }) {
            AddAddressView(address: nil) { _ in }
        }
        .sheet(item: $addressToEdit, onDismiss: {
            Task { await viewModel.loadAddresses() }
        }) { address in
            AddAddressView(address: address) { _ in }
        }
        .alert("Adresi Sil", isPresented: $showDeleteConfirm, presenting: addressToDelete) { address in
            Button("İptal", role: .cancel) { }
            Button("Sil", role: .destructive) {
                if let index = viewModel.addresses.firstIndex(where: { $0.id == address.id }) {
                    Task {
                        await viewModel.deleteAddress(at: IndexSet(integer: index))
                    }
                }
            }
        } message: { address in
            Text("\"\(address.title)\" adresini silmek istediğinize emin misiniz?")
        }
        .task {
            await viewModel.loadAddresses()
        }
        .alert("Hata", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("Tamam", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    // MARK: - Empty State
    private var emptyStateSection: some View {
        VStack(spacing: 28) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(accentYellow.opacity(0.12))
                    .frame(width: 90, height: 90)
                Circle()
                    .fill(accentYellow.opacity(0.06))
                    .frame(width: 110, height: 110)
                Image(systemName: "mappin.and.ellipse")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(accentYellow)
            }
            
            VStack(spacing: 10) {
                Text("Kayıtlı Adres Bulunmamaktadır")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color.themeText)
                    .multilineTextAlignment(.center)
                
                Text("Hızlı sipariş vermek için hemen bir ev veya iş adresi tanımlayın.")
                    .font(.subheadline)
                    .foregroundColor(Color.themeSecondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button {
                showingAddAddress = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                    Text("Yeni Adres Ekle")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: 220)
                .padding(.vertical, 14)
                .background(accentYellow)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: accentYellow.opacity(0.4), radius: 10, x: 0, y: 6)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Address Card
    @ViewBuilder
    private func addressCard(_ address: Address) -> some View {
        VStack(alignment: .leading, spacing: Constants.spacingS) {
            
            // Header row
            HStack(alignment: .center) {
                // Tag icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(accentYellow.opacity(0.15))
                        .frame(width: 38, height: 38)
                    Image(systemName: (address.tag ?? "Ev") == "İş" ? "briefcase.fill" : "house.fill")
                        .font(.system(size: 16))
                        .foregroundColor(accentYellow)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(address.title)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.themeText)
                    Text(address.tag ?? "Ev")
                        .font(.caption2)
                        .foregroundColor(Color.themeSecondaryText)
                }
                
                Spacer()
                
                if address.isDefault {
                    Text("Varsayılan")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(accentYellow)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(accentYellow.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
            
            // Address text
            Text(address.fullAddress)
                .font(.footnote)
                .foregroundColor(Color.themeSecondaryText)
                .lineLimit(2)
                .padding(.leading, 46)
            
            // Building details
            HStack(spacing: 0) {
                Spacer().frame(width: 46)
                Text("Bina: \(address.buildingNo)  Kat: \(address.floor)  D: \(address.apartmentNo)")
                    .font(.caption2)
                    .foregroundColor(Color.themeSecondaryText.opacity(0.7))
            }
            
            if !address.directionsNote.isEmpty {
                HStack(spacing: 6) {
                    Spacer().frame(width: 46)
                    Image(systemName: "info.circle")
                        .font(.caption2)
                        .foregroundColor(accentYellow.opacity(0.7))
                    Text(address.directionsNote)
                        .font(.caption2)
                        .italic()
                        .foregroundColor(Color.themeSecondaryText)
                        .lineLimit(1)
                }
            }
            
            // Separator
            Rectangle()
                .fill(Color.themeBorder)
                .frame(height: 1)
                .padding(.top, 6)
            
            // Action buttons
            HStack(spacing: Constants.spacingM) {
                if !address.isDefault {
                    Button {
                        Task { await viewModel.makeDefault(id: address.id) }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "star")
                                .font(.caption2)
                            Text("Varsayılan Yap")
                                .font(.caption2)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(accentYellow)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Spacer()
                
                Button {
                    addressToEdit = address
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                        Text("Düzenle")
                    }
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(accentYellow)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button {
                    addressToDelete = address
                    showDeleteConfirm = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                        Text("Sil")
                    }
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.themeError)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(16)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: accentYellow.opacity(0.06), radius: 8, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(accentYellow.opacity(0.12), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        CustomerAddressListView()
    }
}
