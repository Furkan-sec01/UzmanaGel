import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore
import SwiftUI
import PhotosUI

@MainActor
final class ExpertSignUpViewModel: ObservableObject {

    // MARK: - Step Tracking (sadece 1. adım: temel bilgiler; 2–4. adımlar profilden tamamlanır)

    @Published var currentStep = 1
    let totalSteps = 1

    // MARK: - Step 1: Temel Bilgiler

    @Published var fullName = ""
    @Published var email = ""
    @Published var phone = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var kvkkAccepted = false

    // Telefon SMS doğrulama (Step 1)
    @Published var smsCode = ""
    @Published var phoneVerified = false
    @Published var didSendCode = false
    @Published var resendCountdown = 0

    // MARK: - Step 2: İşletme Bilgileri

    @Published var businessName = ""
    @Published var selectedCategories: Set<String> = []
    @Published var businessType: BusinessType = .individual
    @Published var taxNumber = ""

    // MARK: - Step 3: Profesyonel Bilgiler

    @Published var experienceYears = ""
    @Published var selectedExpertiseAreas: Set<String> = []
    @Published var educationLevel: EducationLevel = .bachelor
    @Published var schoolName = ""
    @Published var certificateImages: [UIImage] = []
    @Published var certificatePickerItems: [PhotosPickerItem] = []
    @Published var certificatePDFs: [Data] = []

    // MARK: - Step 4: Kimlik Doğrulama

    @Published var idFrontImage: UIImage?
    @Published var idBackImage: UIImage?
    @Published var idFrontPickerItem: PhotosPickerItem?
    @Published var idBackPickerItem: PhotosPickerItem?

    // MARK: - State

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var didSignUp = false
    @Published var showImagePicker = false

    private let userRepo = UserRepository()
    private let storageUpload = StorageUploadService()
    private weak var session: SessionViewModel?
    private var verificationID: String?
    private var resendTimer: Timer?

    /// View onAppear'da session verir; böylece createExpertUserDocument sonrası setUserRoleAsExpert() View ekrandan kalkmış olsa da çalışır.
    func setSession(_ session: SessionViewModel?) {
        self.session = session
    }

    // MARK: - Step Navigation

    func nextStep() {
        if currentStep == 1 && !phoneVerified {
            guard validateStep1FieldsOnly() else { return }
            if !didSendCode {
                sendVerificationCode()
                return
            }
            errorMessage = "Lütfen SMS kodunu girin ve doğrulayın."
            return
        }

        guard validateStep1() else { return }

        withAnimation(.easeInOut(duration: 0.3)) {
            submitApplication()
        }
    }

    func previousStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if currentStep > 1 {
                currentStep -= 1
            }
        }
    }

    // MARK: - Validation

    func validateCurrentStep() -> Bool {
        errorMessage = nil

        switch currentStep {
        case 1:
            return validateStep1()
        case 2:
            return validateStep2()
        case 3:
            return validateStep3()
        case 4:
            return validateStep4()
        default:
            return true
        }
    }

    private func validateStep1() -> Bool {
        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines).filter(\.isNumber)

        guard !trimmedName.isEmpty else {
            errorMessage = "Ad Soyad boş olamaz."
            return false
        }

        guard trimmedName.count >= 3 else {
            errorMessage = "Ad Soyad en az 3 karakter olmalıdır."
            return false
        }

        guard !trimmedEmail.isEmpty else {
            errorMessage = "E-posta adresi boş olamaz."
            return false
        }

        guard trimmedEmail.contains("@") && trimmedEmail.contains(".") else {
            errorMessage = "Geçerli bir e-posta adresi girin."
            return false
        }

        guard !trimmedPhone.isEmpty else {
            errorMessage = "Telefon numarası boş olamaz."
            return false
        }

        guard trimmedPhone.count == 10 else {
            errorMessage = "Telefon numarası 10 haneli olmalıdır. (ör: 5XXXXXXXXX)"
            return false
        }

        guard !password.isEmpty else {
            errorMessage = "Şifre boş olamaz."
            return false
        }

        guard password.count >= 6 else {
            errorMessage = "Şifre en az 6 karakter olmalı."
            return false
        }

        guard password == confirmPassword else {
            errorMessage = "Şifreler eşleşmiyor."
            return false
        }

        guard kvkkAccepted else {
            errorMessage = "Devam etmek için KVKK onayını vermelisiniz."
            return false
        }

        guard phoneVerified else {
            errorMessage = "Telefon numaranızı SMS ile doğrulamanız gerekiyor."
            return false
        }

        return true
    }

    /// Step 1 alanları (telefon doğrulaması hariç) – İleri ile SMS istemek için kullanılır.
    private func validateStep1FieldsOnly() -> Bool {
        errorMessage = nil
        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines).filter(\.isNumber)

        guard !trimmedName.isEmpty else {
            errorMessage = "Ad Soyad boş olamaz."
            return false
        }
        guard trimmedName.count >= 3 else {
            errorMessage = "Ad Soyad en az 3 karakter olmalıdır."
            return false
        }
        guard !trimmedEmail.isEmpty, trimmedEmail.contains("@"), trimmedEmail.contains(".") else {
            errorMessage = "Geçerli bir e-posta adresi girin."
            return false
        }
        guard !trimmedPhone.isEmpty, trimmedPhone.count == 10 else {
            errorMessage = "Telefon numarası 10 haneli olmalıdır. (ör: 5XXXXXXXXX)"
            return false
        }
        guard !password.isEmpty, password.count >= 6 else {
            errorMessage = "Şifre en az 6 karakter olmalı."
            return false
        }
        guard password == confirmPassword else {
            errorMessage = "Şifreler eşleşmiyor."
            return false
        }
        guard kvkkAccepted else {
            errorMessage = "Devam etmek için KVKK onayını vermelisiniz."
            return false
        }
        return true
    }

    // MARK: - Telefon SMS Doğrulama

    private func phoneE164() -> String? {
        let digits = phone.trimmingCharacters(in: .whitespacesAndNewlines).filter(\.isNumber)
        guard digits.count == 10, digits.first == "5" else { return nil }
        return "+90" + digits
    }

    func sendVerificationCode() {
        guard let e164 = phoneE164() else {
            errorMessage = "Telefon numarası 10 haneli olmalı ve 5 ile başlamalı. (ör: 5XXXXXXXXX)"
            return
        }

        isLoading = true
        errorMessage = nil

        PhoneAuthProvider.provider().verifyPhoneNumber(e164, uiDelegate: nil) { [weak self] verificationID, error in
            guard let self else { return }

            Task { @MainActor in
                self.isLoading = false

                if let error {
                    self.errorMessage = self.mapPhoneSendError(error)
                    return
                }

                guard let verificationID else {
                    self.errorMessage = "Doğrulama başlatılamadı. Lütfen tekrar deneyin."
                    return
                }

                self.verificationID = verificationID
                self.didSendCode = true
                self.smsCode = ""
                self.startResendCountdown()
            }
        }
    }

    func verifyPhoneCode() {
        let codeDigits = smsCode.filter(\.isNumber)
        guard codeDigits.count == 6 else {
            errorMessage = "Doğrulama kodu 6 haneli olmalıdır."
            return
        }

        guard let verificationID else {
            errorMessage = "Önce doğrulama kodu gönderin."
            return
        }

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmedEmail.isEmpty, trimmedEmail.contains("@"), password.count >= 6 else {
            errorMessage = "Doğrulama için e-posta ve şifre alanları doldurulmuş olmalıdır."
            return
        }

        isLoading = true
        errorMessage = nil

        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: codeDigits
        )

        Auth.auth().signIn(with: credential) { [weak self] result, error in
            guard let self else { return }

            Task { @MainActor in
                if let error {
                    self.isLoading = false
                    self.errorMessage = self.mapPhoneVerifyError(error)
                    return
                }

                guard let firebaseUser = result?.user else {
                    self.isLoading = false
                    self.errorMessage = "Doğrulama tamamlanamadı."
                    return
                }

                let emailCredential = EmailAuthProvider.credential(
                    withEmail: trimmedEmail,
                    password: self.password
                )

                firebaseUser.link(with: emailCredential) { [weak self] _, linkError in
                    guard let self else { return }

                    Task { @MainActor in
                        self.isLoading = false

                        if let linkError {
                            do { try Auth.auth().signOut() } catch { }
                            self.errorMessage = self.mapLinkError(linkError)
                            return
                        }

                        self.phoneVerified = true
                        withAnimation(.easeInOut(duration: 0.3)) {
                            self.currentStep = 2
                        }
                    }
                }
            }
        }
    }

    func resendVerificationCode() {
        guard resendCountdown == 0, let _ = phoneE164() else { return }
        sendVerificationCode()
    }

    private func startResendCountdown() {
        resendCountdown = 60
        resendTimer?.invalidate()
        resendTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if self.resendCountdown > 0 {
                    self.resendCountdown -= 1
                } else {
                    self.resendTimer?.invalidate()
                }
            }
        }
    }

    private func mapPhoneSendError(_ error: Error) -> String {
        let code = (error as NSError).code
        switch code {
        case AuthErrorCode.invalidPhoneNumber.rawValue:
            return "Geçersiz telefon numarası. 5 ile başlayan 10 hane girin. (ör: 5XXXXXXXXX)"
        case AuthErrorCode.quotaExceeded.rawValue:
            return "SMS kotası aşıldı. Lütfen birkaç saat sonra tekrar deneyin."
        case AuthErrorCode.tooManyRequests.rawValue:
            return "Çok fazla istek. 10–15 dakika bekleyip tekrar deneyin."
        default:
            return "SMS gönderilemedi. Lütfen tekrar deneyin."
        }
    }

    private func mapPhoneVerifyError(_ error: Error) -> String {
        let code = (error as NSError).code
        switch code {
        case AuthErrorCode.invalidVerificationCode.rawValue:
            return "Doğrulama kodu hatalı. SMS’teki 6 haneli kodu kontrol edin."
        case AuthErrorCode.sessionExpired.rawValue:
            return "Kodun süresi doldu. Yeni kod isteyin."
        default:
            return "Doğrulama başarısız. Lütfen tekrar deneyin."
        }
    }

    private func mapLinkError(_ error: Error) -> String {
        let code = (error as NSError).code
        if code == AuthErrorCode.emailAlreadyInUse.rawValue {
            return "Bu e-posta adresi zaten kullanılıyor. Farklı bir e-posta deneyin."
        }
        return "E-posta bağlanamadı. Lütfen tekrar deneyin."
    }

    private func validateStep2() -> Bool {
        let trimmedBusiness = businessName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedBusiness.isEmpty else {
            errorMessage = "İşletme adı boş olamaz."
            return false
        }

        guard trimmedBusiness.count >= 2 else {
            errorMessage = "İşletme adı en az 2 karakter olmalıdır."
            return false
        }

        guard !selectedCategories.isEmpty else {
            errorMessage = "En az bir hizmet kategorisi seçmelisiniz."
            return false
        }

        return true
    }

    private func validateStep3() -> Bool {
        let trimmedYears = experienceYears.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedYears.isEmpty, let years = Int(trimmedYears), years >= 0 else {
            errorMessage = "Geçerli bir deneyim yılı girin."
            return false
        }

        guard years <= 60 else {
            errorMessage = "Deneyim yılı 60'tan fazla olamaz."
            return false
        }

        guard !selectedExpertiseAreas.isEmpty else {
            errorMessage = "En az bir uzmanlık alanı seçmelisiniz."
            return false
        }

        return true
    }

    private func validateStep4() -> Bool {
        guard idFrontImage != nil else {
            errorMessage = "Kimlik ön yüz fotoğrafı zorunludur."
            return false
        }

        guard idBackImage != nil else {
            errorMessage = "Kimlik arka yüz fotoğrafı zorunludur."
            return false
        }

        return true
    }

    var isStep4Valid: Bool {
        idFrontImage != nil && idBackImage != nil
    }

    var isStep1Valid: Bool {
        let n = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let e = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let p = phone.trimmingCharacters(in: .whitespacesAndNewlines).filter(\.isNumber)
        return n.count >= 3
            && e.contains("@") && e.contains(".")
            && p.count == 10
            && password.count >= 6
            && password == confirmPassword
            && kvkkAccepted
            && phoneVerified
    }

    /// İleri ile SMS istemek veya 2. adıma geçmek için – telefon doğrulaması şart değil.
    var isStep1FieldsFilled: Bool {
        let n = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let e = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let p = phone.trimmingCharacters(in: .whitespacesAndNewlines).filter(\.isNumber)
        return n.count >= 3
            && e.contains("@") && e.contains(".")
            && p.count == 10
            && password.count >= 6
            && password == confirmPassword
            && kvkkAccepted
    }

    var isStep2Valid: Bool {
        let b = businessName.trimmingCharacters(in: .whitespacesAndNewlines)
        return b.count >= 2 && !selectedCategories.isEmpty
    }

    var isStep3Valid: Bool {
        guard let years = Int(experienceYears.trimmingCharacters(in: .whitespacesAndNewlines)),
              years >= 0, years <= 60 else { return false }
        return !selectedExpertiseAreas.isEmpty
    }

    // MARK: - ID Image Handling

    func loadIdFrontImage() {
        guard let item = idFrontPickerItem else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                idFrontImage = image
            }
        }
    }

    func loadIdBackImage() {
        guard let item = idBackPickerItem else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                idBackImage = image
            }
        }
    }

    // MARK: - Certificate Image Handling

    func loadCertificateImages() {
        Task {
            var images: [UIImage] = []
            for item in certificatePickerItems {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    images.append(image)
                }
            }
            certificateImages = images
        }
    }

    func removeCertificate(at index: Int) {
        guard index < certificateImages.count else { return }
        certificateImages.remove(at: index)
        if index < certificatePickerItems.count {
            certificatePickerItems.remove(at: index)
        }
    }

    func addCertificatePDF(_ data: Data) {
        certificatePDFs.append(data)
    }

    func removeCertificatePDF(at index: Int) {
        guard index < certificatePDFs.count else { return }
        certificatePDFs.remove(at: index)
    }

    // MARK: - Submit (sadece 1. adım: users + service_providers minimal; 2–4. adımlar profilden tamamlanır)

    func submitApplication() {
        guard !didSignUp else { return }
        guard validateStep1() else { return }

        isLoading = true
        errorMessage = nil

        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines).filter(\.isNumber)

        Task {
            let user: FirebaseAuth.User

            if let existingUser = Auth.auth().currentUser, phoneVerified {
                user = existingUser
            } else {
                do {
                    let emailTaken = try await userRepo.isEmailTaken(trimmedEmail)
                    if emailTaken {
                        isLoading = false
                        errorMessage = "Bu e-posta adresi zaten kullanılıyor. Lütfen farklı bir e-posta deneyin veya mevcut hesabınızla giriş yapın."
                        return
                    }
                } catch {
                    isLoading = false
                    errorMessage = "E-posta kontrolü yapılırken bağlantı hatası oluştu."
                    return
                }

                do {
                    let phoneTaken = try await userRepo.isPhoneTaken(trimmedPhone)
                    if phoneTaken {
                        isLoading = false
                        errorMessage = "Bu telefon numarası zaten başka bir hesapta kayıtlı."
                        return
                    }
                } catch {
                    isLoading = false
                    errorMessage = "Telefon kontrolü yapılırken bağlantı hatası oluştu."
                    return
                }

                do {
                    let result = try await Auth.auth().createUser(withEmail: trimmedEmail, password: password)
                    user = result.user
                } catch {
                    isLoading = false
                    errorMessage = mapAuthError(error)
                    return
                }
            }

            session?.setUserRoleAsExpert()

            do {
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = trimmedName
                try await changeRequest.commitChanges()
            } catch {
                // devam et
            }

            do {
                try await userRepo.createExpertUserDocument(
                    uid: user.uid,
                    displayName: trimmedName,
                    email: trimmedEmail,
                    phoneNumber: trimmedPhone
                )
            } catch {
                isLoading = false
                errorMessage = "Kullanıcı bilgileri kaydedilemedi. Lütfen tekrar deneyin."
                return
            }

            do {
                try await userRepo.createMinimalServiceProvider(
                    uid: user.uid,
                    displayName: trimmedName,
                    email: trimmedEmail,
                    phoneNumber: trimmedPhone
                )
            } catch {
                isLoading = false
                errorMessage = "Uzman kaydı tamamlanırken hata oluştu. Giriş yaparak Profilim üzerinden tamamlayabilirsiniz."
                didSignUp = true
                return
            }

            isLoading = false
            didSignUp = true
        }
    }

    func clearError() {
        errorMessage = nil
    }

    // MARK: - Auth Error Mapping

    private func mapAuthError(_ error: Error) -> String {
        let code = (error as NSError).code

        switch code {
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return "Bu e-posta adresi zaten bir hesaba bağlı. Farklı bir e-posta deneyin veya mevcut hesabınızla giriş yapın."
        case AuthErrorCode.invalidEmail.rawValue:
            return "Geçersiz e-posta formatı. Lütfen doğru bir e-posta adresi girin."
        case AuthErrorCode.weakPassword.rawValue:
            return "Şifreniz güvenlik gereksinimlerini karşılamıyor. En az 6 karakter uzunluğunda olmalı."
        case AuthErrorCode.networkError.rawValue:
            return "İnternet bağlantısı kurulamadı. Bağlantınızı kontrol edip tekrar deneyin."
        case AuthErrorCode.tooManyRequests.rawValue:
            return "Çok fazla deneme yapıldı. Lütfen birkaç dakika bekleyip tekrar deneyin."
        default:
            return "Hesap oluşturulurken bir hata oluştu (Kod: \(code)). Lütfen tekrar deneyin."
        }
    }

    deinit {
        resendTimer?.invalidate()
    }
}
