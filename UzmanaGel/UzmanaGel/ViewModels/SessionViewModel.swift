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

@MainActor
final class SessionViewModel: ObservableObject {

    @Published var isAuthenticated: Bool = false
    @Published var userId: String? = nil
    @Published var needsProfileSetup: Bool = false
    @Published var isCheckingProfile: Bool = false
    @Published var userRole: String = "user"

    /// Uzman başvuru akışındayken true; profil tamamlama yerine bu akışta kalınır.
    @Published var isInExpertSignupFlow: Bool = false
    /// Uzman başvuru ViewModel’i – akış boyunca aynı instance kullanılır (adım korunur).
    var expertSignUpViewModel: ExpertSignUpViewModel?

    var isExpert: Bool { userRole == "expert" }

    private var handle: AuthStateDidChangeListenerHandle?
    private let userRepo = UserRepository()

    init() {
        startListening()
    }

    func startListening() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            Task { @MainActor in
                if let user {
                    self.isAuthenticated = true
                    self.userId = user.uid
                    await self.checkProfileCompletion(uid: user.uid)
                } else {
                    self.isAuthenticated = false
                    self.userId = nil
                    self.needsProfileSetup = false
                    self.userRole = "user"
                }
            }
        }
    }

    private func checkProfileCompletion(uid: String) async {
        isCheckingProfile = true
        defer { isCheckingProfile = false }

        let isPhoneSignIn = isCurrentUserPhoneSignIn()

        if isInExpertSignupFlow {
            needsProfileSetup = false
            userRole = "user"
            return
        }

        do {
            let user = try await userRepo.fetchUser(uid: uid)
            let name = user.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            userRole = user.role ?? "user"
            if userRole == "expert" {
                needsProfileSetup = false
            } else if isPhoneSignIn {
                needsProfileSetup = name.isEmpty || name == "Telefon Kullanıcısı"
            } else {
                needsProfileSetup = false
            }
        } catch {
            userRole = "user"
            needsProfileSetup = isPhoneSignIn
        }
    }

    /// Giriş yapan kullanıcı sadece telefon ile mi giriş yaptı (ilk kez kayıt / profil tamamlanmamış telefon kullanıcısı).
    private func isCurrentUserPhoneSignIn() -> Bool {
        guard let user = Auth.auth().currentUser else { return false }
        return user.providerData.contains { $0.providerID == "phone" }
    }

    /// Uzman başvuru ekranı açılmadan önce çağrılır; ViewModel oluşturulur ve akış başlar.
    func startExpertSignup() {
        expertSignUpViewModel = ExpertSignUpViewModel()
        isInExpertSignupFlow = true
    }

    /// Uzman başvuru iptal/bitince çağrılır. İptalde çıkış yapılıp giriş sayfasına dönülür.
    func clearExpertSignup(shouldSignOut: Bool = true) {
        isInExpertSignupFlow = false
        expertSignUpViewModel = nil
        if shouldSignOut {
            signOut()
        }
    }

    func profileCompleted() {
        needsProfileSetup = false
    }

    /// Uzman başvurusu tamamlandığında çağrılır; RootView'ın ExpertHomepage göstermesi için rolü günceller.
    func setUserRoleAsExpert() {
        userRole = "expert"
        needsProfileSetup = false
    }

    func stopListening() {
        if let handle {
            Auth.auth().removeStateDidChangeListener(handle)
            self.handle = nil
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("SignOut error:", error.localizedDescription)
        }
    }
}
