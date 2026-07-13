//
//  SignUpViewModel.swift
//  UzmanaGel
//
//  Created by Abdullah B on 2.02.2026.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class SignUpViewModel: ObservableObject {

    @Published var name: String = ""
    @Published var email: String = ""
    @Published var phone: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var kvkkAccepted: Bool = false

    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var didSignUp: Bool = false

    private let userRepo = UserRepository()

    func signUp() {
        let trimmedName  = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines).filter(\.isNumber)

        // MARK: - Lokal Validasyon

        guard !trimmedName.isEmpty, !trimmedEmail.isEmpty, !trimmedPhone.isEmpty else {
            errorMessage = "Ad Soyad, E-posta ve Telefon boş olamaz."
            return
        }

        guard trimmedEmail.contains("@") && trimmedEmail.contains(".") else {
            errorMessage = "Geçerli bir e-posta adresi girin."
            return
        }

        guard trimmedPhone.count == 10 else {
            errorMessage = "Telefon numarası 10 haneli olmalıdır. (ör: 5XXXXXXXXX)"
            return
        }

        guard kvkkAccepted else {
            errorMessage = "Devam etmek için KVKK onayını vermelisin."
            return
        }

        guard !password.isEmpty, !confirmPassword.isEmpty else {
            errorMessage = "Şifre alanları boş olamaz."
            return
        }

        guard password == confirmPassword else {
            errorMessage = "Şifreler eşleşmiyor."
            return
        }

        guard password.count >= 6 else {
            errorMessage = "Şifre en az 6 karakter olmalı."
            return
        }

        // MARK: - Mükerrer Kontrol + Hesap Oluşturma

        isLoading = true
        errorMessage = nil

        Task {
            // 1) E-posta mükerrer kontrolü
            do {
                let emailTaken = try await userRepo.isEmailTaken(trimmedEmail)
                if emailTaken {
                    isLoading = false
                    errorMessage = "Bu e-posta adresi (\(trimmedEmail)) zaten başka bir hesapta kullanılıyor. Lütfen farklı bir e-posta adresi deneyin veya mevcut hesabınızla giriş yapın."
                    return
                }
            } catch {
                isLoading = false
                errorMessage = "E-posta kontrolü yapılırken bağlantı hatası oluştu. İnternet bağlantınızı kontrol edip tekrar deneyin."
                return
            }

            // 2) Telefon mükerrer kontrolü
            do {
                let phoneTaken = try await userRepo.isPhoneTaken(trimmedPhone)
                if phoneTaken {
                    isLoading = false
                    errorMessage = "Bu telefon numarası (\(formatPhone(trimmedPhone))) zaten başka bir hesapta kayıtlı. Her telefon numarası yalnızca bir hesapta kullanılabilir. Eğer bu numara size aitse mevcut hesabınızla giriş yapın."
                    return
                }
            } catch {
                isLoading = false
                errorMessage = "Telefon numarası kontrolü yapılırken bağlantı hatası oluştu. İnternet bağlantınızı kontrol edip tekrar deneyin."
                return
            }

            // 3) Firebase Auth hesap oluşturma
            let user: FirebaseAuth.User
            do {
                let result = try await Auth.auth().createUser(withEmail: trimmedEmail, password: password)
                user = result.user
            } catch {
                isLoading = false
                errorMessage = mapAuthError(error)
                return
            }

            // 4) Profil adı güncelleme
            do {
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = trimmedName
                try await changeRequest.commitChanges()
            } catch {
                isLoading = false
                errorMessage = "Hesabınız oluşturuldu ancak profil adınız kaydedilemedi. Profil sayfasından adınızı güncelleyebilirsiniz."
                didSignUp = true
                return
            }

            // 5) Firestore kullanıcı dokümanı oluşturma
            do {
                try await userRepo.createUserDocument(
                    uid: user.uid,
                    displayName: trimmedName,
                    email: trimmedEmail,
                    phoneNumber: trimmedPhone
                )
            } catch {
                isLoading = false
                errorMessage = "Hesabınız oluşturuldu ancak kullanıcı bilgileriniz veritabanına kaydedilemedi. Lütfen uygulamayı kapatıp tekrar açın, bilgileriniz otomatik olarak güncellenecektir."
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

    // MARK: - Firebase Auth Hata Eşleme

    private func mapAuthError(_ error: Error) -> String {
        let code = (error as NSError).code

        switch code {
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return "Bu e-posta adresi zaten bir hesaba bağlı. Farklı bir e-posta adresi deneyin veya \"Giriş Yap\" ekranından mevcut hesabınıza erişin. Şifrenizi hatırlamıyorsanız \"Şifremi Unuttum\" seçeneğini kullanabilirsiniz."

        case AuthErrorCode.invalidEmail.rawValue:
            return "Girdiğiniz e-posta adresi geçersiz. Lütfen doğru formatta bir e-posta girin (ör: ornek@mail.com). E-posta adresinde boşluk veya özel karakter olmadığından emin olun."

        case AuthErrorCode.weakPassword.rawValue:
            return "Belirlediğiniz şifre güvenlik gereksinimlerini karşılamıyor. Şifreniz en az 6 karakter uzunluğunda olmalı ve kolay tahmin edilebilir kalıplar (123456, abcdef vb.) içermemelidir."

        case AuthErrorCode.networkError.rawValue:
            return "Hesap oluşturulurken sunucuya bağlanılamadı. Wi-Fi veya mobil veri bağlantınızın aktif olduğundan emin olun ve tekrar deneyin."

        case AuthErrorCode.tooManyRequests.rawValue:
            return "Kısa sürede çok fazla kayıt denemesi yapıldı. Güvenlik nedeniyle işlem geçici olarak engellendi. Lütfen 5 dakika bekleyip tekrar deneyin."

        case AuthErrorCode.operationNotAllowed.rawValue:
            return "E-posta/şifre ile kayıt şu anda sunucu tarafında devre dışı bırakılmış. Bu geçici bir durumdur, lütfen daha sonra tekrar deneyin."

        case AuthErrorCode.internalError.rawValue:
            return "Firebase sunucularında beklenmeyen bir hata meydana geldi. Bu sizden kaynaklanan bir sorun değil. Lütfen birkaç dakika sonra tekrar deneyin."

        case AuthErrorCode.userDisabled.rawValue:
            return "Bu e-posta adresine ait hesap daha önce devre dışı bırakılmış. Yeni bir hesap oluşturmak için farklı bir e-posta adresi kullanın veya destek ekibimizle iletişime geçin."

        case AuthErrorCode.invalidCredential.rawValue:
            return "Girdiğiniz bilgiler doğrulanamadı. E-posta adresinizi ve şifrenizi kontrol edip tekrar deneyin."

        case AuthErrorCode.missingEmail.rawValue:
            return "E-posta adresi alanı boş bırakılamaz. Lütfen geçerli bir e-posta adresi girin."

        default:
            return "Hesap oluşturulurken beklenmeyen bir hata oluştu (Hata kodu: \(code)). Lütfen bilgilerinizi kontrol edip tekrar deneyin. Sorun devam ederse destek ekibimize başvurun."
        }
    }

    // MARK: - Yardımcı

    private func formatPhone(_ raw: String) -> String {
        guard raw.count == 10 else { return raw }
        return "\(raw.prefix(3)) \(raw.dropFirst(3).prefix(3)) \(raw.dropFirst(6).prefix(2)) \(raw.dropFirst(8))"
    }
}
