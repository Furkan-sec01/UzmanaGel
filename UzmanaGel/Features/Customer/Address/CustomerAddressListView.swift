import SwiftUI

struct CustomerAddressListView: View {
    @StateObject private var viewModel = AddressListViewModel()
    @State private var showingAddAddress = false
    
    var body: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()
            
            if viewModel.isLoading && viewModel.addresses.isEmpty {
                LoadingView(message: "Adresleriniz yükleniyor...")
            } else if viewModel.addresses.isEmpty {
                EmptyStateView(
                    iconName: "mappin.slash",
                    title: "Kayıtlı Adres Bulunmamaktadır",
                    message: "Hızlı sipariş vermek için hemen bir ev veya iş adresi tanımlayın.",
                    buttonTitle: "Yeni Adres Ekle"
                ) {
                    showingAddAddress = true
                }
            } else {
                List {
                    ForEach(viewModel.addresses) { address in
                        addressCard(address)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                    .onDelete { indexSet in
                        Task {
                            await viewModel.deleteAddress(at: indexSet)
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .refreshable {
                    await viewModel.loadAddresses()
                }
            }
        }
        .navigationTitle("Adreslerim")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddAddress = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(Color.themePrimary)
                }
            }
        }
        .sheet(isPresented: $showingAddAddress) {
            AddAddressView { newAddr in
                Task {
                    await viewModel.loadAddresses()
                }
            }
        }
        .task {
            await viewModel.loadAddresses()
        }
    }
    
    @ViewBuilder
    private func addressCard(_ address: Address) -> some View {
        CardView(cornerRadius: Constants.radiusM, shadowRadius: Constants.shadowRadiusS) {
            VStack(alignment: .leading, spacing: Constants.spacingS) {
                HStack {
                    HStack(spacing: Constants.spacingS) {
                        Image(systemName: address.tag == "İş" ? "briefcase.fill" : "house.fill")
                            .foregroundColor(Color.themePrimary)
                        Text(address.title)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(Color.themeText)
                    }
                    Spacer()
                    if address.isDefault {
                        BadgeView(text: "Varsayılan", style: .success)
                    } else {
                        Button {
                            Task {
                                await viewModel.makeDefault(id: address.id)
                            }
                        } label: {
                            Text("Varsayılan Yap")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(Color.themePrimary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Text(address.fullAddress)
                    .font(.footnote)
                    .foregroundColor(Color.themeSecondaryText)
                    .lineLimit(2)
                
                HStack(spacing: Constants.spacingM) {
                    Text("Bina No: \(address.buildingNo) D: \(address.apartmentNo) Kat: \(address.floor)")
                        .font(.caption2)
                        .foregroundColor(Color.themeSecondaryText)
                    Spacer()
                }
                
                if !address.directionsNote.isEmpty {
                    Text("Not: \(address.directionsNote)")
                        .font(.caption2)
                        .italic()
                        .foregroundColor(Color.themeSecondaryText)
                        .lineLimit(1)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CustomerAddressListView()
    }
}
