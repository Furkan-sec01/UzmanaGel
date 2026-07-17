//
//  ResetPasswordPage.swift
//  UzmanaGel
//
//  Created by Abdullah B on 03.02.2026.
//

import SwiftUI
import FirebaseAuth

struct ResetPasswordPage: View {

    @Environment(\.dismiss) private var dismiss

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""

    @State private var showCurrent = false
    @State private var showNew = false
    @State private var showConfirm = false

    @State private var isLoading = false
    @State private var isSendingResetEmail = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var alertSuggestion = ""
    @State private var showAlert = false
    @State private var isSuccess = false

    private let accentYellow = Color("TertiaryColor")
    private let bgColor      = Color("BackgroundColor")
    private let primaryColor = Color("PrimaryColor")

    private var fullAlertMessageText: String {
        if alertSuggestion.isEmpty {
            return alertMessage
        } else {
            return "\(alertMessage)\n\n💡 \("Öneri: ".localized)\(alertSuggestion)"
        }
    }

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    Spacer().frame(height: 16)
                    headerCard
                    passwordInputsCard
                    submitButtonsGroup
                    if !newPassword.isEmpty {
                        passwordRequirementsView
                    }
                    validationMessages
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Şifre Değiştir".localized)
        .navigationBarTitleDisplayMode(.inline)
        .alert(alertTitle, isPresented: $showAlert) {
            Button("Tamam".localized) {
                if isSuccess { dismiss() }
            }
        } message: {
            Text(fullAlertMessageText)
        }
    }

    // MARK: - Header Card
    private var headerCard: some View {
        VStack(spacing: 6) {
            Text("Şifre Değiştir".localized)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(primaryColor)

            Text("Mevcut şifreni doğrula ve yeni şifreni belirle.".localized)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 6)
    }

    // MARK: - Password Inputs Card
    private var passwordInputsCard: some View {
        VStack(spacing: 16) {
            passwordField(
                placeholder: "Mevcut şifre".localized,
                text: $currentPassword,
                isVisible: $showCurrent,
                leftIcon: "key.horizontal.fill",
                leftIconColor: .orange
            )

            Divider().background(Color.gray.opacity(0.15))

            passwordField(
                placeholder: "Yeni şifre".localized,
                text: $newPassword,
                isVisible: $showNew,
                leftIcon: "lock.shield.fill",
                leftIconColor: .teal
            )

            passwordField(
                placeholder: "Yeni şifre tekrar".localized,
                text: $confirmPassword,
                isVisible: $showConfirm,
                leftIcon: "checkmark.shield.fill",
                leftIconColor: .indigo
            )
        }
        .padding(16)
        .background(Color.white.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accentYellow.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: accentYellow.opacity(0.1), radius: 8, x: 0, y: 3)
    }

    // MARK: - Submit Buttons Group
    private var submitButtonsGroup: some View {
        VStack(spacing: 14) {
            Button {
                Task { await changePassword() }
            } label: {
                updateButtonLabel
            }
            .buttonStyle(.plain)
            .disabled(!isValid || isLoading)

            Button {
                Task { await sendPasswordResetEmail() }
            } label: {
                HStack(spacing: 8) {
                    if isSendingResetEmail {
                        ProgressView().scaleEffect(0.8)
                    } else {
                        Image(systemName: "envelope.badge.fill")
                            .foregroundColor(.blue)
                    }
                    Text("Mevcut şifreni mi unuttun?".localized)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(primaryColor)
                }
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
            .disabled(isSendingResetEmail)
        }
    }

    private var updateButtonLabel: some View {
        HStack(spacing: 8) {
            if isLoading {
                ProgressView().tint(primaryColor)
            } else {
                Image(systemName: "lock.rotation")
                    .font(.system(size: 16, weight: .bold))
            }
            Text("ŞİFREYİ GÜNCELLE".localized)
                .font(.system(size: 15, weight: .bold))
        }
        .foregroundColor((!isValid || isLoading) ? .secondary : primaryColor)
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background {
            if !isValid || isLoading {
                Color.gray.opacity(0.15)
            } else {
                LinearGradient(
                    colors: [accentYellow, accentYellow.opacity(0.85)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke((!isValid || isLoading) ? Color.clear : primaryColor.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: (!isValid || isLoading) ? .clear : accentYellow.opacity(0.4), radius: 10, x: 0, y: 5)
    }

    // MARK: - Validation Messages

    private var validationMessages: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !currentPassword.isEmpty && currentPassword.count < 6 {
                validationRow(
                    icon: "exclamationmark.circle.fill",
                    text: "Mevcut şifreniz 6 karakterden kısa olamaz.",
                    color: .red
                )
            }

            if !confirmPassword.isEmpty && newPassword != confirmPassword {
                validationRow(
                    icon: "xmark.circle.fill",
                    text: "Girdiğiniz şifreler birbiriyle eşleşmiyor.",
                    color: .red
                )
            } else if !confirmPassword.isEmpty && newPassword == confirmPassword {
                validationRow(
                    icon: "checkmark.circle.fill",
                    text: "Şifreler eşleşiyor.",
                    color: .green
                )
            }

            if newPassword == currentPassword && !newPassword.isEmpty && !currentPassword.isEmpty {
                validationRow(
                    icon: "exclamationmark.triangle.fill",
                    text: "Yeni şifreniz mevcut şifrenizle aynı olamaz.",
                    color: .orange
                )
            }

            if !newPassword.isEmpty && newPassword.count >= 6 && hasSequentialChars(newPassword) {
                validationRow(
                    icon: "exclamationmark.triangle.fill",
                    text: "Şifreniz ardışık karakterler içeriyor (ör: 123, abc).",
                    color: .orange
                )
            }

            if !newPassword.isEmpty && hasRepeatingChars(newPassword) {
                validationRow(
                    icon: "exclamationmark.triangle.fill",
                    text: "Şifreniz tekrar eden karakterler içeriyor (ör: aaa, 111).",
                    color: .orange
                )
            }
        }
    }

    // MARK: - Password Field

    private func passwordField(
        placeholder: String,
        text: Binding<String>,
        isVisible: Binding<Bool>,
        leftIcon: String,
        leftIconColor: Color
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: leftIcon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(leftIconColor)
                .frame(width: 32, height: 32)
                .background(leftIconColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Group {
                if isVisible.wrappedValue {
                    TextField(placeholder, text: text)
                } else {
                    SecureField(placeholder, text: text)
                }
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(primaryColor)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            Button {
                isVisible.wrappedValue.toggle()
            } label: {
                Image(systemName: isVisible.wrappedValue ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 16))
                    .foregroundColor(isVisible.wrappedValue ? .blue : .secondary.opacity(0.7))
                    .padding(4)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .frame(height: 52)
        .background(bgColor)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(leftIconColor.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Password Requirements

    private var passwordRequirementsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "shield.checkered")
                    .foregroundColor(.teal)
                    .font(.system(size: 14, weight: .bold))
                Text("Şifre Gereksinimleri".localized)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(primaryColor)
            }

            requirementRow("En az 6 karakter", met: newPassword.count >= 6)
            requirementRow("En az 1 büyük harf (A-Z)", met: newPassword.range(of: "[A-Z]", options: .regularExpression) != nil)
            requirementRow("En az 1 küçük harf (a-z)", met: newPassword.range(of: "[a-z]", options: .regularExpression) != nil)
            requirementRow("En az 1 rakam (0-9)", met: newPassword.range(of: "[0-9]", options: .regularExpression) != nil)
            requirementRow("En az 1 özel karakter (!@#$%&*)", met: newPassword.range(of: "[^a-zA-Z0-9]", options: .regularExpression) != nil)

            passwordStrengthBar
        }
        .padding(16)
        .background(Color.white.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accentYellow.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: accentYellow.opacity(0.08), radius: 6, x: 0, y: 2)
    }

    private func requirementRow(_ text: String, met: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 13))
                .foregroundColor(met ? .green : .secondary.opacity(0.4))
            Text(text.localized)
                .font(.system(size: 12, weight: met ? .semibold : .regular))
                .foregroundColor(met ? primaryColor : .secondary)
        }
    }

    private var passwordStrengthBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Şifre Gücü:".localized)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                Text(strengthLabel.localized)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(strengthColor)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(strengthColor)
                        .frame(width: geo.size.width * strengthProgress, height: 6)
                        .animation(.easeInOut(duration: 0.3), value: strengthProgress)
                }
            }
            .frame(height: 6)
        }
        .padding(.top, 6)
    }

    private var strengthScore: Int {
        var score = 0
        if newPassword.count >= 6 { score += 1 }
        if newPassword.count >= 10 { score += 1 }
        if newPassword.range(of: "[A-Z]", options: .regularExpression) != nil { score += 1 }
        if newPassword.range(of: "[a-z]", options: .regularExpression) != nil { score += 1 }
        if newPassword.range(of: "[0-9]", options: .regularExpression) != nil { score += 1 }
        if newPassword.range(of: "[^a-zA-Z0-9]", options: .regularExpression) != nil { score += 1 }
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
        case 3: return accentYellow
        case 4: return .mint
        case 5: return .green
        default: return .green
        }
    }

    private var strengthProgress: CGFloat {
        CGFloat(strengthScore) / 6.0
    }

    private func validationRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(color)
            Text(text.localized)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
        !currentPassword.isEmpty &&
        newPassword.count >= 6 &&
        newPassword == confirmPassword &&
        newPassword != currentPassword
    }

    // MARK: - Alert Helpers

    private func showError(title: String, message: String, suggestion: String = "") {
        isSuccess = false
        alertTitle = title
        alertMessage = message
        alertSuggestion = suggestion
        showAlert = true
    }

    private func showSuccess(title: String, message: String) {
        isSuccess = true
        alertTitle = title
        alertMessage = message
        alertSuggestion = ""
        showAlert = true
    }

    // MARK: - Firebase Password Change and Password Reset Mail

    private func changePassword() async {
        guard let user = Auth.auth().currentUser,
              let email = user.email else {
            showError(
                title: "Oturum Hatası".localized,
                message: "Aktif bir oturum veya e-posta bulunamadı.".localized,
                suggestion: "Uygulamadan çıkış yapıp tekrar giriş yapın.".localized
            )
            return
        }

        isLoading = true
        defer { isLoading = false }

        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)

        do {
            try await user.reauthenticate(with: credential)
        } catch {
            mapFirebaseError(error, phase: .reauthentication)
            return
        }

        do {
            try await user.updatePassword(to: newPassword)
            showSuccess(
                title: "Şifre Güncellendi ✓".localized,
                message: "Şifreniz başarıyla değiştirildi. Bir sonraki girişinizde yeni şifrenizi kullanmanız gerekmektedir.".localized
            )
        } catch {
            mapFirebaseError(error, phase: .passwordUpdate)
        }
    }
    private func sendPasswordResetEmail() async {
        guard let email = Auth.auth().currentUser?.email else {
            showError(
                title: "E-posta Bulunamadı".localized,
                message: "Şifre sıfırlama bağlantısı göndermek için hesabınıza bağlı bir e-posta bulunamadı.".localized,
                suggestion: "Profil bilgilerinizden e-posta adresinizi kontrol edin.".localized
            )
            return
        }

        isSendingResetEmail = true
        defer { isSendingResetEmail = false }

        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)

            showSuccess(
                title: "Sıfırlama E-postası Gönderildi".localized,
                message: String(format: "%@ adresine şifre sıfırlama bağlantısı gönderildi.".localized, email)
            )
        } catch {
            mapFirebaseError(error, phase: .passwordUpdate)
        }
    }

    // MARK: - Error Mapping

    private enum ErrorPhase {
        case reauthentication
        case passwordUpdate
    }

    private func mapFirebaseError(_ error: Error, phase: ErrorPhase) {
        let code = (error as NSError).code

        switch code {
        case AuthErrorCode.wrongPassword.rawValue, AuthErrorCode.invalidCredential.rawValue:
            showError(
                title: "Şifre Doğrulanamadı".localized,
                message: "Girdiğiniz mevcut şifre hatalı.".localized,
                suggestion: "Şifrenizi hatırlamıyorsanız \"Şifremi Unuttum\" ile sıfırlayabilirsiniz.".localized
            )
        case AuthErrorCode.weakPassword.rawValue:
            showError(
                title: "Zayıf Şifre".localized,
                message: "Yeni şifreniz güvenlik standartlarını karşılamıyor.".localized,
                suggestion: "Büyük/küçük harf, rakam ve özel karakter kombinasyonu kullanın.".localized
            )
        case AuthErrorCode.requiresRecentLogin.rawValue:
            showError(
                title: "Oturum Süresi Doldu".localized,
                message: "Bu işlem için yakın zamanda giriş yapılmış olması gerekiyor.".localized,
                suggestion: "Çıkış yapıp tekrar giriş yapın ve hemen şifre değiştirin.".localized
            )
        case AuthErrorCode.networkError.rawValue:
            showError(
                title: "Bağlantı Hatası".localized,
                message: "Sunucuyla iletişim kurulamadı.".localized,
                suggestion: "İnternet bağlantınızı kontrol edip tekrar deneyin.".localized
            )
        case AuthErrorCode.tooManyRequests.rawValue:
            showError(
                title: "Çok Fazla Deneme".localized,
                message: "Çok fazla başarısız deneme yapıldı.".localized,
                suggestion: "En az 5 dakika bekleyip tekrar deneyin.".localized
            )
        case AuthErrorCode.userDisabled.rawValue:
            showError(
                title: "Hesap Askıya Alındı".localized,
                message: "Hesabınız devre dışı bırakılmış.".localized,
                suggestion: "destek@uzmanagel.com adresinden bize ulaşın.".localized
            )
        case AuthErrorCode.internalError.rawValue:
            showError(
                title: "Sunucu Hatası".localized,
                message: "Firebase sunucularında beklenmeyen bir hata oluştu.".localized,
                suggestion: "Birkaç dakika bekleyip tekrar deneyin.".localized
            )
        default:
            let phaseText = phase == .reauthentication
                ? "mevcut şifreniz doğrulanırken".localized
                : "yeni şifreniz kaydedilirken".localized
            showError(
                title: "Beklenmeyen Hata".localized,
                message: String(format: "%@ bir hata oluştu (Kod: %d).".localized, phaseText, code),
                suggestion: "Tekrar deneyin. Sorun devam ederse destek ekibimize başvurun.".localized
            )
        }
    }
}

#Preview {
    NavigationStack {
        ResetPasswordPage()
    }
}
