import Foundation
import Combine

@MainActor
class AddressListViewModel: ObservableObject {
    @Published var addresses: [Address] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let addressService: AddressService
    
    init(addressService: AddressService = MockAddressService()) {
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
            addresses.remove(at: index)
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func makeDefault(id: String) async {
        isLoading = true
        do {
            try await addressService.setDefaultAddress(id: id)
            // Reload local values
            self.addresses = try await addressService.fetchAddresses()
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
