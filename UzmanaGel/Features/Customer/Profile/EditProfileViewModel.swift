import Foundation
import SwiftUI
import Combine

@MainActor
class EditProfileViewModel: ObservableObject {
    // Form Inputs
    @Published var displayName: String = ""
    @Published var email: String = ""
    @Published var phone: String = ""
    
    // Password Inputs
    @Published var currentPassword = ""
    @Published var newPassword = ""
    @Published var confirmPassword = ""
    
    // Status states
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // SMS Verification State
    @Published var showSMSVerification = false
    @Published var smsCodeInput = ""
    @Published var targetPhoneNumber = ""
    
    // Image selection helpers
    @Published var profileImageURL: String?
    @Published var selectedImageData: Data?
    
    private let profileService: ProfileService
    private var originalProfile: UserProfile
    
    init(profile: UserProfile, profileService: ProfileService = FirestoreProfileService()) {
        self.originalProfile = profile
        self.profileService = profileService
        self.displayName = profile.displayName
        self.email = profile.email
        self.phone = profile.phoneNumber ?? ""
        self.profileImageURL = profile.photoURL
    }
    
    // Check if email has changed
    var isEmailChanged: Bool {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() != originalProfile.email.lowercased()
    }
    
    // Check if phone has changed
    var isPhoneChanged: Bool {
        phone.trimmingCharacters(in: .whitespacesAndNewlines) != (originalProfile.phoneNumber ?? "")
    }
    
    // Password strength score: 0 (very weak) to 4 (very strong)
    var passwordStrength: Int {
        guard !newPassword.isEmpty else { return 0 }
        var score = 0
        if newPassword.count >= 6 { score += 1 }
        if newPassword.count >= 10 { score += 1 }
        if newPassword.contains(where: { $0.isNumber }) { score += 1 }
        if newPassword.contains(where: { $0.isSymbol || $0.isPunctuation }) { score += 1 }
        return score
    }
    
    var passwordStrengthText: String {
        switch passwordStrength {
        case 0: return "Çok Zayıf"
        case 1: return "Zayıf"
        case 2: return "Orta"
        case 3: return "Güçlü"
        case 4: return "Çok Güçlü"
        default: return ""
        }
    }
    
    var passwordStrengthColor: Color {
        switch passwordStrength {
        case 0, 1: return Color.themeError
        case 2: return Color.themeWarning
        case 3, 4: return Color.themeSuccess
        default: return Color.themeSecondaryText
        }
    }
    
    // Save Profile
    func saveProfile(onSuccess: @escaping (UserProfile) -> Void) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            // 1. Upload photo if selected
            if let imgData = selectedImageData {
                let newURL = try await profileService.updateProfileImage(imageData: imgData)
                self.profileImageURL = newURL
                self.selectedImageData = nil
            }
            
            // 2. Perform general profile update
            let updated = try await profileService.updateProfile(
                displayName: displayName,
                email: email,
                phone: phone
            )
            
            self.originalProfile = updated
            successMessage = "Profil bilgileriniz başarıyla güncellendi."
            onSuccess(updated)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    // Change Password
    func updatePassword() async {
        guard newPassword == confirmPassword else {
            errorMessage = "Yeni şifreler eşleşmiyor."
            return
        }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            try await profileService.changePassword(current: currentPassword, new: newPassword)
            successMessage = "Şifreniz başarıyla değiştirildi."
            currentPassword = ""
            newPassword = ""
            confirmPassword = ""
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    // Trigger Phone change SMS verification flow
    func startPhoneVerificationFlow() {
        guard !phone.isEmpty else { return }
        targetPhoneNumber = phone
        showSMSVerification = true
        smsCodeInput = ""
        errorMessage = nil
    }
    
    // Verify code
    func confirmSMSCode(onSuccess: @escaping (UserProfile) -> Void) async {
        isLoading = true
        errorMessage = nil
        do {
            try await profileService.verifyPhoneNumber(phone: targetPhoneNumber, code: smsCodeInput)
            showSMSVerification = false
            successMessage = "Telefon numaranız doğrulandı."
            
            // Sync with profile
            var updated = originalProfile
            updated.phoneNumber = targetPhoneNumber
            originalProfile = updated
            onSuccess(updated)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
