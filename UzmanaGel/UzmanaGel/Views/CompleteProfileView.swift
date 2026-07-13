//
//  CompleteProfileView.swift
//  UzmanaGel
//
//  Created by Abdullah B on 23.02.2026.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct CompleteProfileView: View {

    @EnvironmentObject var session: SessionViewModel

    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    @State private var showPassword = false
    @State private var showConfirm = false

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false

    private let userRepo = UserRepository()

    var body: some View {
        ZStack {
            Color("BackgroundColor").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    Spacer().frame(height: 40)

                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 56))
                        .foregroundColor(Color("PrimaryColor"))

                    VStack(spacing: 6) {
                        Text("Profilini Tamamla")
                            .font(.system(size: 24, weight: .bold))

                        Text("Devam etmek için bilgilerini doldur ve bir şifre belirle.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }

                    // Ad Soyad
                    inputField(icon: "person", placeholder: "Ad Soyad") {
                        TextField("Ad Soyad", text: $fullName)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                    }

                    // E-posta
                    inputField(icon: "envelope", placeholder: "E-posta") {
                        TextField("E-posta", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }

                    // Şifre
                    inputField(icon: "lock", placeholder: "Şifre") {
                        Group {
                            if showPassword {
                                TextField("Şifre", text: $password)
                            } else {
                                SecureField("Şifre", text: $password)
                            }
                        }
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                        Button { showPassword.toggle() } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }

                    // Şifre Tekrar
                    inputField(icon: "lock", placeholder: "Şifre Tekrar") {
                        Group {
                            if showConfirm {
                                TextField("Şifre Tekrar", text: $confirmPassword)
                            } else {
                                SecureField("Şifre Tekrar", text: $confirmPassword)
                            }
                        }
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                        Button { showConfirm.toggle() } label: {
                            Image(systemName: showConfirm ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }

                    if !password.isEmpty {
                        passwordRequirementsView
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        if !confirmPassword.isEmpty && password != confirmPassword {
                            hintRow("Şifreler eşleşmiyor.", color: .red)
                        } else if !confirmPassword.isEmpty && password == confirmPassword && password.count >= 6 {
                            hintRow("Şifreler eşleşiyor.", color: .green)
                        }

                        if !password.isEmpty && password.count >= 6 && hasSequentialChars(password) {
                            hintRow("Şifreniz ardışık karakterler içeriyor (ör: 123, abc).", color: .orange)
                        }

                        if !password.isEmpty && hasRepeatingChars(password) {
                            hintRow("Şifreniz tekrar eden karakterler içeriyor (ör: aaa, 111).", color: .orange)
                        }
                    }

                    if let phone = Auth.auth().currentUser?.phoneNumber, !phone.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 14))
                            Text("Telefon: \(phone)")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }

                    Button {
                        Task { await saveProfile() }
                    } label: {
                        HStack(spacing: 8) {
                            if isLoading {
                                ProgressView().tint(.white)
                            }
                            Text("KAYDET VE DEVAM ET")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color("PrimaryColor"))
                        .cornerRadius(14)
                        .shadow(radius: 6, y: 3)
                    }
                    .buttonStyle(.plain)
                    .disabled(!isValid || isLoading)
                    .opacity(isValid && !isLoading ? 1 : 0.6)
                    .padding(.top, 6)

                    Button {
                        session.profileCompleted()
                    } label: {
                        Text("Şimdi değil, ana sayfaya git")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 16)

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .alert("Hata", isPresented: $showError) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Reusable Field

    private func inputField<Content: View>(icon: String, placeholder: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 22)

            content()
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .background(Color(.secondarySystemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
        .cornerRadius(14)
    }

    private func hintRow(_ text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: color == .green ? "checkmark.circle.fill" : color == .orange ? "exclamationmark.triangle.fill" : "xmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(color)
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
        }
    }

    // MARK: - Password Requirements

    private var passwordRequirementsView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Şifre Gereksinimleri")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)

            requirementRow("En az 6 karakter", met: password.count >= 6)
            requirementRow("En az 1 büyük harf (A-Z)", met: password.range(of: "[A-Z]", options: .regularExpression) != nil)
            requirementRow("En az 1 küçük harf (a-z)", met: password.range(of: "[a-z]", options: .regularExpression) != nil)
            requirementRow("En az 1 rakam (0-9)", met: password.range(of: "[0-9]", options: .regularExpression) != nil)
            requirementRow("En az 1 özel karakter (!@#$%&*)", met: password.range(of: "[^a-zA-Z0-9]", options: .regularExpression) != nil)

            passwordStrengthBar
        }
        .padding(12)
        .background(Color(.secondarySystemBackground).opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func requirementRow(_ text: String, met: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 13))
                .foregroundColor(met ? .green : .secondary.opacity(0.5))
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(met ? Color("Text") : .secondary)
        }
    }

    private var passwordStrengthBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Şifre Gücü:")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                Text(strengthLabel)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(strengthColor)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(strengthColor)
                        .frame(width: geo.size.width * strengthProgress, height: 6)
                        .animation(.easeInOut(duration: 0.3), value: strengthProgress)
                }
            }
            .frame(height: 6)
        }
        .padding(.top, 4)
    }

    private var strengthScore: Int {
        var score = 0
        if password.count >= 6 { score += 1 }
        if password.count >= 10 { score += 1 }
        if password.range(of: "[A-Z]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[a-z]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[0-9]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[^a-zA-Z0-9]", options: .regularExpression) != nil { score += 1 }
        return score
    }

    private var strengthLabel: String {
        switch strengthScore {
        case 0...1: return "Çok Zayıf"
        case 2: return "Zayıf"
        case 3: return "Orta"
        case 4: return "İyi"
        case 5: return "Güçlü"
        default: return "Çok Güçlü"
        }
    }

    private var strengthColor: Color {
        switch strengthScore {
        case 0...1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .mint
        case 5: return .green
        default: return .green
        }
    }

    private var strengthProgress: CGFloat {
        CGFloat(strengthScore) / 6.0
    }

    // MARK: - Pattern Detection

    private func hasSequentialChars(_ str: String) -> Bool {
        let lowered = str.lowercased()
        let sequences = ["012", "123", "234", "345", "456", "567", "678", "789",
                         "abc", "bcd", "cde", "def", "efg", "fgh", "ghi", "hij",
                         "ijk", "jkl", "klm", "lmn", "mno", "nop", "opq", "pqr",
                         "qrs", "rst", "stu", "tuv", "uvw", "vwx", "wxy", "xyz"]
        return sequences.contains(where: { lowered.contains($0) })
    }

    private func hasRepeatingChars(_ str: String) -> Bool {
        guard str.count >= 3 else { return false }
        let chars = Array(str)
        for i in 0..<(chars.count - 2) {
            if chars[i] == chars[i+1] && chars[i+1] == chars[i+2] {
                return true
            }
        }
        return false
    }

    // MARK: - Validation

    private var isValid: Bool {
        let name = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let mail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.count >= 2
            && mail.contains("@") && mail.contains(".")
            && password.count >= 6
            && password == confirmPassword
    }

    // MARK: - Kaydet

    private func saveProfile() async {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "Oturum bilgisi bulunamadı."
            showError = true
            return
        }

        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let phone = user.phoneNumber?.replacingOccurrences(of: "+90", with: "") ?? ""

        isLoading = true
        defer { isLoading = false }

        // 1) E-posta mükerrer kontrolü
        do {
            let emailTaken = try await userRepo.isEmailTaken(trimmedEmail)
            if emailTaken {
                errorMessage = "Bu e-posta adresi zaten başka bir hesapta kullanılıyor. Lütfen farklı bir e-posta deneyin."
                showError = true
                return
            }
        } catch {
            errorMessage = "E-posta kontrolü yapılırken bir hata oluştu. İnternet bağlantınızı kontrol edip tekrar deneyin."
            showError = true
            return
        }

        // 2) E-posta/şifre provider'ını hesaba bağla
        let credential = EmailAuthProvider.credential(withEmail: trimmedEmail, password: password)
        do {
            try await user.link(with: credential)
        } catch {
            let code = (error as NSError).code
            switch code {
            case AuthErrorCode.emailAlreadyInUse.rawValue:
                errorMessage = "Bu e-posta adresi Firebase'de başka bir hesaba bağlı. Farklı bir e-posta adresi deneyin."
            case AuthErrorCode.weakPassword.rawValue:
                errorMessage = "Şifreniz çok zayıf. En az 6 karakter uzunluğunda, harf ve rakam içeren bir şifre belirleyin."
            case AuthErrorCode.invalidEmail.rawValue:
                errorMessage = "Geçersiz e-posta formatı. Lütfen doğru bir e-posta adresi girin (ör: ornek@mail.com)."
            case AuthErrorCode.requiresRecentLogin.rawValue:
                errorMessage = "Oturum süreniz dolmuş. Uygulamadan çıkış yapıp tekrar telefon ile giriş yapın."
            case AuthErrorCode.providerAlreadyLinked.rawValue:
                errorMessage = "Hesabınızda zaten bir e-posta/şifre bağlantısı mevcut."
            case AuthErrorCode.networkError.rawValue:
                errorMessage = "İnternet bağlantısı kurulamadı. Bağlantınızı kontrol edip tekrar deneyin."
            default:
                errorMessage = "Şifre belirlenirken bir hata oluştu (Kod: \(code)). Lütfen tekrar deneyin."
            }
            showError = true
            return
        }

        // 3) Firestore kullanıcı belgesi
        do {
            try await userRepo.createUserDocument(
                uid: user.uid,
                displayName: trimmedName,
                email: trimmedEmail,
                phoneNumber: phone
            )
        } catch {
            errorMessage = "Profil bilgileri kaydedilirken bir hata oluştu. Lütfen tekrar deneyin."
            showError = true
            return
        }

        // 4) Firebase Auth displayName
        do {
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = trimmedName
            try await changeRequest.commitChanges()
        } catch {
            // displayName kaydedilemese de devam et
        }

        session.profileCompleted()
    }
}
