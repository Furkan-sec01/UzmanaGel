import Foundation
import Combine

@MainActor
class CustomerProfileViewModel: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let profileService: ProfileService
    
    init(profileService: ProfileService = MockProfileService()) {
        self.profileService = profileService
    }
    
    func loadProfile() async {
        isLoading = true
        errorMessage = nil
        do {
            self.userProfile = try await profileService.fetchProfile()
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func logout() {
        // Handle logout process
        self.userProfile = nil
    }
    
    var membershipDurationText: String {
        guard let date = userProfile?.memberSince else { return "" }
        let diff = Calendar.current.dateComponents([.year, .month], from: date, to: Date())
        if let years = diff.year, years > 0 {
            return "\(years) Yıl"
        } else if let months = diff.month, months > 0 {
            return "\(months) Ay"
        } else {
            return "Yeni Üye"
        }
    }
}
