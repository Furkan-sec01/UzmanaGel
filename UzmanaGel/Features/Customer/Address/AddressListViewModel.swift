import Foundation
import SwiftUI
import Combine

@MainActor
class AddressListViewModel: ObservableObject {
    @Published var addresses: [Address] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let addressService: AddressService
    
    init(addressService: AddressService = FirestoreAddressService()) {
        self.addressService = addressService
    }
    
    func loadAddresses() async {
        isLoading = true
        errorMessage = nil
        do {
            self.addresses = try await addressService.fetchAddresses()
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func deleteAddress(at indexSet: IndexSet) async {
        guard let index = indexSet.first else { return }
        let targetId = addresses[index].id
        do {
            try await addressService.deleteAddress(id: targetId)
            // Only remove from UI after Firebase confirms deletion
            withAnimation {
                addresses.remove(at: index)
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func makeDefault(id: String) async {
        isLoading = true
        do {
            try await addressService.setDefaultAddress(id: id)
            // Update in-memory directly instead of a second network fetch
            withAnimation {
                addresses = addresses.map {
                    var a = $0
                    a.isDefault = (a.id == id)
                    return a
                }
                // Re-sort: default first
                addresses.sort { $0.isDefault && !$1.isDefault }
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
