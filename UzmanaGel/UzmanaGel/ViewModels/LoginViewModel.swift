//
//  LoginViewModel.swift
//  UzmanaGel
//
//  Created by Abdullah B on 1.02.2026.
//

import Foundation
import FirebaseAuth
import Combine
import GoogleSignIn
import FirebaseCore

@MainActor
final class LoginViewModel: ObservableObject {

    @Published var email: String = ""
    @Published var password: String = ""

    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var didLogin: Bool = false

    let attemptTracker = LoginAttemptTracker.shared

    func signInWithGoogle(presenting: UIViewController) {
        guard !attemptTracker.isLocked else {
            errorMessage = attemptTracker.lockMessage
            return
        }

        isLoading = true
        errorMessage = nil

        guard let clientID = FirebaseApp.app()?.options.clientID else {
            isLoading = false
            errorMessage = "Google ClientID bulunamadı."
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(withPresenting: presenting) { [weak self] result, error in
            guard let self else { return }

            if let error {
                self.isLoading = false
                self.attemptTracker.recordFailure()
                self.errorMessage = error.localizedDescription
                return
            }

            guard
                let user = result?.user,
                let idToken = user.idToken?.tokenString
            else {
                self.isLoading = false
                self.errorMessage = "Google token alınamadı."
                return
            }

            let accessToken = user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

            Auth.auth().signIn(with: credential) { _, error in
                self.isLoading = false

                if let error {
                    self.attemptTracker.recordFailure()
                    self.errorMessage = error.localizedDescription
                    return
                }

                self.attemptTracker.recordSuccess()
                self.didLogin = true
            }
        }
    }

    func login() {
        guard !attemptTracker.isLocked else {
            errorMessage = attemptTracker.lockMessage
            return
        }

        let trimmedEmail = email
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            errorMessage = "E-posta ve şifre boş olamaz."
            return
        }

        isLoading = true
        errorMessage = nil

        Auth.auth().signIn(withEmail: trimmedEmail, password: password) {
            [weak self] result, error in
            guard let self else { return }

            self.isLoading = false

            if let error {
                self.attemptTracker.recordFailure()
                self.errorMessage = self.attemptTracker.isLocked
                    ? self.attemptTracker.lockMessage
                    : self.mapAuthError(error)
                return
            }

            self.attemptTracker.recordSuccess()
            self.didLogin = true
        }
    }

    private func mapAuthError(_ error: Error) -> String {
        let code = (error as NSError).code

        switch code {
        case AuthErrorCode.invalidCredential.rawValue:
            return "E-posta veya şifre hatalı. Lütfen bilgilerinizi kontrol edip tekrar deneyin."
        case AuthErrorCode.wrongPassword.rawValue:
            return "Şifre hatalı. Lütfen tekrar deneyin."
        case AuthErrorCode.userNotFound.rawValue:
            return "Bu e-posta ile kayıtlı bir hesap bulunamadı."
        case AuthErrorCode.invalidEmail.rawValue:
            return "E-posta formatı hatalı. Lütfen geçerli bir e-posta adresi girin."
        case AuthErrorCode.userDisabled.rawValue:
            return "Bu hesap devre dışı bırakılmış. Destek ekibimizle iletişime geçin."
        case AuthErrorCode.tooManyRequests.rawValue:
            return "Firebase sunucusu çok fazla istek aldı. Lütfen birkaç dakika bekleyin."
        case AuthErrorCode.networkError.rawValue:
            return "İnternet bağlantısı kurulamadı. Bağlantınızı kontrol edip tekrar deneyin."
        default:
            return "Giriş yapılamadı (Kod: \(code)). Lütfen bilgilerinizi kontrol edin."
        }
    }

    func clearError() {
        errorMessage = nil
    }
}
