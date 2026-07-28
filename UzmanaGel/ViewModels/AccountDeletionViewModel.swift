//
//  AccountDeletionViewModel.swift
//  UzmanaGel
//
//  Created by Halil Keremoğlu on 28.07.2026.
//



import Foundation
import UIKit
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import AuthenticationServices
import CryptoKit
import Combine


@MainActor
final class AccountDeletionViewModel: ObservableObject {

    enum AuthenticationMethod {
        case apple
        case google
        case password
        case phone
        case unsupported
    }

    @Published private(set) var authenticationMethod: AuthenticationMethod =
        .unsupported

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var didDeleteAccount = false

    @Published var password = ""
    @Published var phoneCode = ""
    @Published var isPhoneCodeSent = false

    private var currentNonce: String?
    private var phoneVerificationID: String?

    init() {
        refreshAuthenticationMethod()
    }

    // MARK: - Provider Detection

    func refreshAuthenticationMethod() {
        guard let user = Auth.auth().currentUser else {
            authenticationMethod = .unsupported
            return
        }

        let providerIDs = Set(
            user.providerData.map(\.providerID)
        )

        // Apple is checked first because its token must be revoked
        if providerIDs.contains("apple.com") {
            authenticationMethod = .apple
        } else if providerIDs.contains("google.com") {
            authenticationMethod = .google
        } else if providerIDs.contains("password") {
            authenticationMethod = .password
        } else if providerIDs.contains("phone") {
            authenticationMethod = .phone
        } else {
            authenticationMethod = .unsupported
        }
    }

    // MARK: - Apple

    func prepareAppleRequest(
        _ request: ASAuthorizationAppleIDRequest
    ) {
        do {
            let nonce = try randomNonceString()

            currentNonce = nonce
            errorMessage = nil
            isLoading = true

            request.requestedScopes = [
                .fullName,
                .email
            ]

            request.nonce = sha256(nonce)
        } catch {
            isLoading = false
            errorMessage =
                "Apple doğrulama isteği hazırlanamadı."
        }
    }

    func handleAppleCompletion(
        _ result: Result<ASAuthorization, Error>,
        session: SessionViewModel
    ) {
        switch result {
        case .failure(let error):
            currentNonce = nil
            isLoading = false

            if let authorizationError =
                error as? ASAuthorizationError,
               authorizationError.code == .canceled {
                return
            }

            errorMessage =
                "Apple doğrulaması başarısız: \(error.localizedDescription)"

        case .success(let authorization):
            guard let appleCredential =
                    authorization.credential
                        as? ASAuthorizationAppleIDCredential
            else {
                finishWithError(
                    "Apple kullanıcı bilgisi alınamadı."
                )
                return
            }

            guard let nonce = currentNonce else {
                finishWithError(
                    "Apple doğrulama isteği bulunamadı."
                )
                return
            }

            guard
                let identityToken =
                    appleCredential.identityToken,
                let idTokenString = String(
                    data: identityToken,
                    encoding: .utf8
                )
            else {
                finishWithError(
                    "Apple kimlik tokenı alınamadı."
                )
                return
            }

            guard
                let authorizationCode =
                    appleCredential.authorizationCode,
                let authorizationCodeString = String(
                    data: authorizationCode,
                    encoding: .utf8
                )
            else {
                finishWithError(
                    "Apple yetkilendirme kodu alınamadı."
                )
                return
            }

            currentNonce = nil

            let firebaseCredential =
                OAuthProvider.appleCredential(
                    withIDToken: idTokenString,
                    rawNonce: nonce,
                    fullName: appleCredential.fullName
                )

            Task {
                await reauthenticateWithApple(
                    credential: firebaseCredential,
                    authorizationCode:
                        authorizationCodeString,
                    session: session
                )
            }
        }
    }

    private func reauthenticateWithApple(
        credential: AuthCredential,
        authorizationCode: String,
        session: SessionViewModel
    ) async {
        guard let currentUser =
                Auth.auth().currentUser
        else {
            finishWithError(
                "Kullanıcı oturumu bulunamadı."
            )
            return
        }

        do {
            _ = try await currentUser.reauthenticate(
                with: credential
            )

            // Revoke the Apple token before deleting the account
            try await Auth.auth().revokeToken(
                withAuthorizationCode: authorizationCode
            )

            await deleteAccount(
                session: session
            )
        } catch {
            finishWithError(
                "Apple doğrulaması tamamlanamadı: \(error.localizedDescription)"
            )
        }
    }

    // MARK: - Google

    func deleteWithGoogle(
        presenting viewController: UIViewController,
        session: SessionViewModel
    ) {
        guard let currentUser =
                Auth.auth().currentUser
        else {
            finishWithError(
                "Kullanıcı oturumu bulunamadı."
            )
            return
        }

        guard let clientID =
                FirebaseApp.app()?.options.clientID
        else {
            finishWithError(
                "Google ClientID bulunamadı."
            )
            return
        }

        errorMessage = nil
        isLoading = true

        let configuration =
            GIDConfiguration(clientID: clientID)

        GIDSignIn.sharedInstance.configuration =
            configuration

        // Force Google account selection
        GIDSignIn.sharedInstance.signOut()

        GIDSignIn.sharedInstance.signIn(
            withPresenting: viewController
        ) { [weak self] result, error in
            guard let self else {
                return
            }

            Task { @MainActor in
                if let error {
                    self.finishWithError(
                        "Google doğrulaması başarısız: \(error.localizedDescription)"
                    )
                    return
                }

                guard
                    let googleUser = result?.user,
                    let idToken =
                        googleUser.idToken?.tokenString
                else {
                    self.finishWithError(
                        "Google tokenı alınamadı."
                    )
                    return
                }

                let accessToken =
                    googleUser.accessToken.tokenString

                let credential =
                    GoogleAuthProvider.credential(
                        withIDToken: idToken,
                        accessToken: accessToken
                    )

                do {
                    _ = try await currentUser
                        .reauthenticate(
                            with: credential
                        )

                    await self.deleteAccount(
                        session: session
                    )
                } catch {
                    self.finishWithError(
                        "Google hesabı doğrulanamadı: \(error.localizedDescription)"
                    )
                }
            }
        }
    }

    // MARK: - Email and Password

    func deleteWithPassword(
        session: SessionViewModel
    ) {
        guard let currentUser =
                Auth.auth().currentUser
        else {
            finishWithError(
                "Kullanıcı oturumu bulunamadı."
            )
            return
        }

        guard let email = currentUser.email,
              !email.isEmpty else {
            finishWithError(
                "Kullanıcı e-posta adresi bulunamadı."
            )
            return
        }

        let trimmedPassword = password
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !trimmedPassword.isEmpty else {
            finishWithError(
                "Şifrenizi girin."
            )
            return
        }

        errorMessage = nil
        isLoading = true

        let credential =
            EmailAuthProvider.credential(
                withEmail: email,
                password: trimmedPassword
            )

        Task {
            do {
                _ = try await currentUser
                    .reauthenticate(
                        with: credential
                    )

                await deleteAccount(
                    session: session
                )
            } catch {
                finishWithError(
                    "Şifre doğrulanamadı: \(error.localizedDescription)"
                )
            }
        }
    }

    // MARK: - Phone

    func sendPhoneCode() {
        guard let phoneNumber =
                Auth.auth().currentUser?.phoneNumber,
              !phoneNumber.isEmpty
        else {
            finishWithError(
                "Hesaba bağlı telefon numarası bulunamadı."
            )
            return
        }

        errorMessage = nil
        isLoading = true
        Auth.auth().languageCode = "tr"

        PhoneAuthProvider.provider()
            .verifyPhoneNumber(
                phoneNumber,
                uiDelegate: nil
            ) { [weak self] verificationID, error in
                guard let self else {
                    return
                }

                Task { @MainActor in
                    self.isLoading = false

                    if let error {
                        self.errorMessage =
                            "SMS gönderilemedi: \(error.localizedDescription)"
                        return
                    }

                    guard let verificationID else {
                        self.errorMessage =
                            "Telefon doğrulama kimliği alınamadı."
                        return
                    }

                    self.phoneVerificationID =
                        verificationID

                    self.isPhoneCodeSent = true
                }
            }
    }

    func deleteWithPhoneCode(
        session: SessionViewModel
    ) {
        guard let currentUser =
                Auth.auth().currentUser
        else {
            finishWithError(
                "Kullanıcı oturumu bulunamadı."
            )
            return
        }

        guard let verificationID =
                phoneVerificationID
        else {
            finishWithError(
                "Önce SMS doğrulama kodu gönderin."
            )
            return
        }

        let trimmedCode = phoneCode
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !trimmedCode.isEmpty else {
            finishWithError(
                "SMS doğrulama kodunu girin."
            )
            return
        }

        errorMessage = nil
        isLoading = true

        let credential =
            PhoneAuthProvider.provider()
                .credential(
                    withVerificationID:
                        verificationID,
                    verificationCode: trimmedCode
                )

        Task {
            do {
                _ = try await currentUser
                    .reauthenticate(
                        with: credential
                    )

                await deleteAccount(
                    session: session
                )
            } catch {
                finishWithError(
                    "Telefon doğrulaması başarısız: \(error.localizedDescription)"
                )
            }
        }
    }

    // MARK: - Delete Account

    private func deleteAccount(
        session: SessionViewModel
    ) async {
        let success =
            await session.deleteAccount()

        isLoading = false

        if success {
            password = ""
            phoneCode = ""
            phoneVerificationID = nil
            isPhoneCodeSent = false
            didDeleteAccount = true
        } else {
            errorMessage =
                session.accountDeletionError ??
                "Hesap silinemedi."
        }
    }

    // MARK: - Helpers

    func clearError() {
        errorMessage = nil
    }

    private func finishWithError(
        _ message: String
    ) {
        currentNonce = nil
        isLoading = false
        errorMessage = message
    }

    private func sha256(
        _ input: String
    ) -> String {
        let inputData = Data(input.utf8)
        let hashedData =
            SHA256.hash(data: inputData)

        return hashedData
            .compactMap {
                String(format: "%02x", $0)
            }
            .joined()
    }

    private func randomNonceString(
        length: Int = 32
    ) throws -> String {
        guard length > 0 else {
            throw AccountDeletionError.invalidNonceLength
        }

        var randomBytes = [UInt8](
            repeating: 0,
            count: length
        )

        let status = SecRandomCopyBytes(
            kSecRandomDefault,
            randomBytes.count,
            &randomBytes
        )

        guard status == errSecSuccess else {
            throw AccountDeletionError.nonceGenerationFailed
        }

        let characterSet = Array(
            "0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._"
        )

        let nonce = randomBytes.map { byte in
            characterSet[
                Int(byte) % characterSet.count
            ]
        }

        return String(nonce)
    }
}

private enum AccountDeletionError: LocalizedError {
    case invalidNonceLength
    case nonceGenerationFailed

    var errorDescription: String? {
        switch self {
        case .invalidNonceLength:
            return "Nonce uzunluğu geçersiz."

        case .nonceGenerationFailed:
            return "Güvenli nonce oluşturulamadı."
        }
    }
}
