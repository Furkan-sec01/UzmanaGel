//
//  PhoneAuthViewModel.swift
//  UzmanaGel
//
//  Created by Abdullah B on 2.02.2026.
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
final class PhoneAuthViewModel: ObservableObject {

    @Published var phone10: String = ""
    @Published var smsCode: String = ""

    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var didLogin: Bool = false
    @Published var didSendCode: Bool = false

    @Published var resendCountdown: Int = 0

    private var verificationID: String?
    private var countdownTimer: Timer?

    let attemptTracker = LoginAttemptTracker.shared

    // MARK: - Telefon Formatı

    private func formattedPhoneE164() -> String? {
        let digits = phone10.filter(\.isNumber)
        guard digits.count == 10, digits.first == "5" else { return nil }
        return "+90" + digits
    }

    // MARK: - Kod Gönder

    func sendCode() {
        guard !attemptTracker.isLocked else {
            errorMessage = attemptTracker.lockMessage
            return
        }

        guard let e164 = formattedPhoneE164() else {
            errorMessage = "Telefon numarası 10 haneli olmalı ve 5 ile başlamalı.\n\nDoğru format: 5XXXXXXXXX\nÖrnek: 5551234567"
            return
        }

        isLoading = true
        errorMessage = nil

        PhoneAuthProvider.provider().verifyPhoneNumber(e164, uiDelegate: nil) { [weak self] verificationID, error in
            guard let self else { return }

            Task { @MainActor in
                self.isLoading = false

                if let error {
                    self.errorMessage = self.mapSendCodeError(error)
                    return
                }

                guard let verificationID else {
                    self.errorMessage = "Doğrulama işlemi başlatılamadı. Lütfen tekrar deneyin."
                    return
                }

                self.verificationID = verificationID
                self.didSendCode = true
                self.startResendCountdown()
            }
        }
    }

    // MARK: - Tekrar Kod Gönder

    func resendCode() {
        guard resendCountdown == 0 else { return }

        guard let e164 = formattedPhoneE164() else { return }

        isLoading = true
        errorMessage = nil

        PhoneAuthProvider.provider().verifyPhoneNumber(e164, uiDelegate: nil) { [weak self] verificationID, error in
            guard let self else { return }

            Task { @MainActor in
                self.isLoading = false

                if let error {
                    self.errorMessage = self.mapSendCodeError(error)
                    return
                }

                guard let verificationID else {
                    self.errorMessage = "Kod tekrar gönderilemedi. Lütfen birkaç dakika bekleyip tekrar deneyin."
                    return
                }

                self.verificationID = verificationID
                self.smsCode = ""
                self.startResendCountdown()
            }
        }
    }

    private func startResendCountdown() {
        resendCountdown = 60
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            Task { @MainActor [weak self] in
                guard let self else {
                    timer.invalidate()
                    return
                }
                if self.resendCountdown > 0 {
                    self.resendCountdown -= 1
                } else {
                    timer.invalidate()
                }
            }
        }
    }

    // MARK: - Kodu Doğrula

    func verifyCode() {
        guard !attemptTracker.isLocked else {
            errorMessage = attemptTracker.lockMessage
            return
        }

        let codeDigits = smsCode.filter(\.isNumber)

        guard codeDigits.count == 6 else {
            errorMessage = "Doğrulama kodu 6 haneli olmalıdır. Lütfen SMS ile gelen 6 haneli kodu eksiksiz girin."
            return
        }

        guard let verificationID else {
            errorMessage = "Doğrulama oturumu bulunamadı. Lütfen geri dönüp tekrar kod isteyin."
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
                    self.attemptTracker.recordFailure()
                    self.errorMessage = self.attemptTracker.isLocked
                        ? self.attemptTracker.lockMessage
                        : self.mapVerifyCodeError(error)
                    return
                }

                guard result?.user != nil else {
                    self.isLoading = false
                    self.errorMessage = "Giriş yapılamadı. Lütfen tekrar deneyin."
                    return
                }

                self.attemptTracker.recordSuccess()
                self.isLoading = false
                self.didLogin = true
            }
        }
    }

    // MARK: - Hata Temizle

    func clearError() {
        errorMessage = nil
    }

    // MARK: - Kod Gönderme Hataları

    private func mapSendCodeError(_ error: Error) -> String {
        let code = (error as NSError).code

        switch code {
        case AuthErrorCode.invalidPhoneNumber.rawValue:
            return "Girdiğiniz telefon numarası geçersiz. Lütfen başında 0 olmadan, 5 ile başlayan 10 haneli numaranızı girin.\n\nÖrnek: 5551234567"

        case AuthErrorCode.missingPhoneNumber.rawValue:
            return "Telefon numarası alanı boş bırakılamaz. Lütfen telefon numaranızı girin."

        case AuthErrorCode.quotaExceeded.rawValue:
            return "SMS gönderim kotası aşıldı. Bu durum geçicidir, lütfen birkaç saat sonra tekrar deneyin."

        case AuthErrorCode.captchaCheckFailed.rawValue:
            return "Güvenlik doğrulaması başarısız oldu. Lütfen sayfayı yenileyip tekrar deneyin. Sorun devam ederse uygulamayı kapatıp tekrar açın."

        case AuthErrorCode.networkError.rawValue:
            return "İnternet bağlantısı kurulamadı. Wi-Fi veya mobil veri bağlantınızı kontrol edip tekrar deneyin."

        case AuthErrorCode.tooManyRequests.rawValue:
            return "Çok fazla SMS kodu istendi. Güvenlik nedeniyle işlem geçici olarak engellendi. Lütfen 10-15 dakika bekleyip tekrar deneyin."

        case AuthErrorCode.internalError.rawValue:
            return "Sunucuda beklenmeyen bir hata oluştu. Lütfen birkaç dakika sonra tekrar deneyin."

        case AuthErrorCode.appNotAuthorized.rawValue:
            return "Bu uygulama telefon doğrulaması için yetkilendirilmemiş. Lütfen uygulamayı güncelleyin veya destek ekibimize başvurun."

        case AuthErrorCode.missingClientIdentifier.rawValue:
            return "Cihaz doğrulaması yapılamadı. Lütfen cihazınızda bildirim izinlerinin açık olduğundan emin olun ve tekrar deneyin."

        default:
            return "SMS kodu gönderilirken bir hata oluştu (Kod: \(code)). Lütfen tekrar deneyin. Sorun devam ederse destek ekibimize başvurun."
        }
    }

    // MARK: - Kod Doğrulama Hataları

    private func mapVerifyCodeError(_ error: Error) -> String {
        let code = (error as NSError).code

        switch code {
        case AuthErrorCode.invalidVerificationCode.rawValue:
            return "Girdiğiniz doğrulama kodu hatalı. Lütfen SMS ile gelen 6 haneli kodu kontrol edip tekrar girin. Kodun süresinin dolmadığından emin olun."

        case AuthErrorCode.invalidVerificationID.rawValue:
            return "Doğrulama oturumunuzun süresi dolmuş. Lütfen geri dönüp yeni bir kod isteyin."

        case AuthErrorCode.sessionExpired.rawValue:
            return "SMS kodunun geçerlilik süresi doldu. Her kod yalnızca birkaç dakika geçerlidir. Lütfen geri dönüp yeni bir kod isteyin."

        case AuthErrorCode.networkError.rawValue:
            return "İnternet bağlantısı kurulamadı. Bağlantınızı kontrol edip tekrar deneyin."

        case AuthErrorCode.tooManyRequests.rawValue:
            return "Çok fazla hatalı kod girildi. Güvenlik nedeniyle işlem geçici olarak engellendi. Lütfen 10-15 dakika bekleyip tekrar deneyin."

        case AuthErrorCode.userDisabled.rawValue:
            return "Bu telefon numarasına ait hesap devre dışı bırakılmış. Daha fazla bilgi için destek ekibimizle iletişime geçin."

        case AuthErrorCode.operationNotAllowed.rawValue:
            return "Telefon ile giriş şu anda devre dışı. Lütfen e-posta ile giriş yapmayı deneyin veya daha sonra tekrar deneyin."

        case AuthErrorCode.internalError.rawValue:
            return "Sunucuda beklenmeyen bir hata oluştu. Lütfen birkaç dakika sonra tekrar deneyin."

        default:
            return "Doğrulama sırasında bir hata oluştu (Kod: \(code)). Lütfen tekrar deneyin. Sorun devam ederse destek ekibimize başvurun."
        }
    }

    deinit {
        countdownTimer?.invalidate()
    }
}
