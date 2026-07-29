//
//  SessionViewModel.swift
//  UzmanaGel
//
//  Created by Abdullah B on 2.02.2026.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions

// Controls the current user session
@MainActor
final class SessionViewModel: ObservableObject {

    @Published var isAuthenticated: Bool = false
    @Published var userId: String? = nil
    @Published var needsProfileSetup: Bool = false
    @Published var isCheckingProfile: Bool = false
    @Published var userRole: String = "user"
    @Published var isAdmin: Bool = false
    @Published var isInCustomerSignupFlow: Bool = false


    // Account deletion state
    @Published var isDeletingAccount: Bool = false
    @Published var accountDeletionError: String? = nil

    // Keeps the expert signup flow active
    @Published var isInExpertSignupFlow: Bool = false

    // Uses the same ViewModel during expert signup
    var expertSignUpViewModel: ExpertSignUpViewModel?
    var customerSignUpViewModel: SignUpViewModel?

    var isExpert: Bool {
        userRole == "expert"
    }

    private var handle: AuthStateDidChangeListenerHandle?
    private var shouldPreserveExpertSignupOnNextAuthReset = false
    private var shouldPreserveCustomerSignupOnNextAuthReset = false

    private let userRepo = UserRepository()
    private let functions = Functions.functions(
        region: "europe-west1"
    )
    init() {
        startListening()
    }

    // MARK: - Auth Listener

    func startListening() {
        guard handle == nil else {
            return
        }

        handle = Auth.auth().addStateDidChangeListener {
            [weak self] _, user in

            guard let self else {
                return
            }

            Task { @MainActor in
                if let user {
                    self.isAuthenticated = true
                    self.userId = user.uid

                    await self.loadAdminClaim(user: user)
                    await self.checkProfileCompletion(uid: user.uid)
                } else {
                    let preserveExpertSignup =
                        self.shouldPreserveExpertSignupOnNextAuthReset

                    let preserveCustomerSignup =
                        self.shouldPreserveCustomerSignupOnNextAuthReset

                    self.shouldPreserveExpertSignupOnNextAuthReset = false
                    self.shouldPreserveCustomerSignupOnNextAuthReset = false

                    self.resetSessionState(
                        preservingExpertSignup: preserveExpertSignup,
                        preservingCustomerSignup: preserveCustomerSignup
                    )
                }
            }
        }
    }

    func stopListening() {
        if let handle {
            Auth.auth().removeStateDidChangeListener(handle)
            self.handle = nil
        }
    }

    // MARK: - Admin

    private func loadAdminClaim(
        user: FirebaseAuth.User
    ) async {
        do {
            let tokenResult = try await user.getIDTokenResult(
                forcingRefresh: true
            )

            isAdmin =
            tokenResult.claims["admin"] as? Bool == true
        } catch {
            isAdmin = false

            print(
                "Admin claim load error:",
                error.localizedDescription
            )
        }
    }

    // MARK: - Profile

    private func checkProfileCompletion(
        uid: String
    ) async {
        isCheckingProfile = true

        defer {
            isCheckingProfile = false
        }

        let isPhoneSignIn =
        isCurrentUserPhoneSignIn()

        if isInExpertSignupFlow {
            needsProfileSetup = false
            userRole = "user"
            return
        }

        do {
            let user = try await userRepo.fetchUser(
                uid: uid
            )

            let name = user.displayName
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

            userRole = user.role ?? "user"

            if userRole == "expert" {
                needsProfileSetup = false
            } else if isPhoneSignIn {
                needsProfileSetup =
                name.isEmpty ||
                name == "Telefon Kullanıcısı"
            } else {
                needsProfileSetup = false
            }
        } catch {
            userRole = "user"
            needsProfileSetup = isPhoneSignIn
        }
    }

    private func isCurrentUserPhoneSignIn() -> Bool {
        guard let user = Auth.auth().currentUser else {
            return false
        }

        return user.providerData.contains {
            $0.providerID == "phone"
        }
    }

    func profileCompleted() {
        needsProfileSetup = false
    }

    func setUserRoleAsExpert() {
        userRole = "expert"
        needsProfileSetup = false
    }

    // MARK: - Customer Signup

    func startCustomerSignup() {
        customerSignUpViewModel = SignUpViewModel()
        isInCustomerSignupFlow = true
    }

    func completeCustomerSignup() {
        isInCustomerSignupFlow = false
        customerSignUpViewModel = nil
    }

    func prepareForCustomerSignupAuthReset() {
        guard isInCustomerSignupFlow,
              customerSignUpViewModel != nil else {
            return
        }

        shouldPreserveCustomerSignupOnNextAuthReset = true
    }

    func cancelCustomerSignupAuthResetPreparation() {
        shouldPreserveCustomerSignupOnNextAuthReset = false
    }


    // MARK: - Expert Signup

    func startExpertSignup() {
        expertSignUpViewModel =
        ExpertSignUpViewModel()

        isInExpertSignupFlow = true
    }

    func clearExpertSignup(
        shouldSignOut: Bool = true
    ) {
        isInExpertSignupFlow = false
        expertSignUpViewModel = nil

        if shouldSignOut {
            signOut()
        }
    }

    func prepareForExpertSignupAuthReset() {
        guard isInExpertSignupFlow,
              expertSignUpViewModel != nil else {
            return
        }

        shouldPreserveExpertSignupOnNextAuthReset = true
    }

    func cancelExpertSignupAuthResetPreparation() {
        shouldPreserveExpertSignupOnNextAuthReset = false
    }
    // MARK: - Account Deletion

    func deleteAccount() async -> Bool {
        guard let currentUser =
                Auth.auth().currentUser
        else {
            accountDeletionError =
            "Silinecek kullanıcı oturumu bulunamadı."

            return false
        }

        guard !isDeletingAccount else {
            return false
        }

        isDeletingAccount = true
        accountDeletionError = nil

        defer {
            isDeletingAccount = false
        }

        do {
            // Refresh the user token before the request
            _ = try await currentUser.getIDTokenResult(
                forcingRefresh: true
            )

            // Backend will delete user data and Auth account
            _ = try await functions
                .httpsCallable("deleteUserAccount")
                .call([
                    "confirmation": "DELETE_MY_ACCOUNT"
                ])

            // Clear any remaining local session
            try? Auth.auth().signOut()

            resetSessionState()

            return true
        } catch {
            accountDeletionError =
            accountDeletionMessage(
                for: error
            )

            print(
                "Account deletion error:",
                error.localizedDescription
            )

            return false
        }
    }

    func clearAccountDeletionError() {
        accountDeletionError = nil
    }

    private func accountDeletionMessage(
        for error: Error
    ) -> String {
        let nsError = error as NSError

        if nsError.domain ==
            FunctionsErrorDomain {

            switch nsError.code {
            case FunctionsErrorCode.unauthenticated.rawValue:
                return "Oturumunuz sona ermiş. Lütfen tekrar giriş yapın."

            case FunctionsErrorCode.permissionDenied.rawValue:
                return "Bu işlem için yetkiniz bulunmuyor."

            case FunctionsErrorCode.failedPrecondition.rawValue:
                return "Hesabı silmeden önce yeniden giriş yapmanız gerekiyor."

            case FunctionsErrorCode.unavailable.rawValue:
                return "Sunucuya ulaşılamadı. Lütfen tekrar deneyin."

            default:
                break
            }
        }

        return "Hesap silinemedi: \(error.localizedDescription)"
    }

    // MARK: - Sign Out

    func signOut() {
        do {
            try Auth.auth().signOut()
            resetSessionState()
        } catch {
            print(
                "SignOut error:",
                error.localizedDescription
            )
        }
    }

    // MARK: - Session Reset
    private func resetSessionState(
        preservingExpertSignup: Bool = false,
        preservingCustomerSignup: Bool = false
    ) {
        isAuthenticated = false
        userId = nil
        needsProfileSetup = false
        isCheckingProfile = false
        userRole = "user"
        isAdmin = false

        if !preservingExpertSignup {
            isInExpertSignupFlow = false
            expertSignUpViewModel = nil
        }

        if !preservingCustomerSignup {
            isInCustomerSignupFlow = false
            customerSignUpViewModel = nil
        }

        isDeletingAccount = false
        accountDeletionError = nil
    }
}
