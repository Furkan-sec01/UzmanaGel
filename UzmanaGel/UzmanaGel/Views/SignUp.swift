import SwiftUI

struct SignUp: View {

    @StateObject private var vm = SignUpViewModel()

    @State private var isPasswordVisible = false
    @State private var isPasswordVisible2 = false
    @State private var showKvkkSheet = false
    @State private var hasReadKvkk = false

    @State private var showError = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            mainContent
        }
    }
}

// MARK: - UI Parts
private extension SignUp {

    var mainContent: some View {
        ZStack {
            background

            VStack(spacing: 16) {
                titleSection

                nameField
                emailField
                phoneField
                passwordField
                confirmPasswordField

                kvkkSection

                signUpButton
                loginRedirect

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)

            if vm.isLoading {
                loadingOverlay
            }
        }
        .onChange(of: vm.errorMessage) { _, msg in
            showError = (msg != nil)
        }
        .alert("Hata", isPresented: $showError) {
            Button("Tamam", role: .cancel) { vm.clearError() }
        } message: {
            Text(vm.errorMessage ?? "Bilinmeyen hata")
        }
        .onChange(of: vm.didSignUp) { _, newValue in
            if newValue {
                dismiss()
            }
        }
    }

    var background: some View {
        Color("BackgroundColor")
            .ignoresSafeArea()
    }

    var titleSection: some View {
        Text("Hesap Oluştur")
            .font(.system(size: 22, weight: .bold))
            .foregroundColor(.primary)
            .padding(.top, 6)
    }

    var nameField: some View {
        HStack(spacing: 10) {
            Image(systemName: "person")
                .foregroundColor(.secondary)

            TextField("Ad Soyad", text: $vm.name)
                .keyboardType(.namePhonePad)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .shadow(radius: 5)
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

    var emailField: some View {
        HStack(spacing: 10) {
            Image(systemName: "envelope")
                .foregroundColor(.secondary)

            TextField("E-posta", text: $vm.email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .shadow(radius: 5)
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

    var phoneField: some View {
        HStack(spacing: 10) {
            Image(systemName: "phone")
                .foregroundColor(.secondary)

            TextField("Telefon Numarası (5xxx)", text: $vm.phone)
                .keyboardType(.phonePad)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .shadow(radius: 5)
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

    var passwordField: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock")
                .foregroundColor(.secondary)

            Group {
                if isPasswordVisible {
                    TextField("Şifre", text: $vm.password)
                } else {
                    SecureField("Şifre", text: $vm.password)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            Button {
                isPasswordVisible.toggle()
            } label: {
                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
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

    var confirmPasswordField: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock")
                .foregroundColor(.secondary)

            Group {
                if isPasswordVisible2 {
                    TextField("Şifre Tekrar", text: $vm.confirmPassword)
                } else {
                    SecureField("Şifre Tekrar", text: $vm.confirmPassword)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            Button {
                isPasswordVisible2.toggle()
            } label: {
                Image(systemName: isPasswordVisible2 ? "eye.slash" : "eye")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
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

    var kvkkSection: some View {
        HStack(spacing: 8) {

            // Checkbox: okumadıysa tiklenmesin, PDF açsın
            Button {
                if hasReadKvkk {
                    vm.kvkkAccepted.toggle()
                } else {
                    showKvkkSheet = true
                }
            } label: {
                Image(systemName: vm.kvkkAccepted ? "checkmark.square.fill" : "square")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(hasReadKvkk ? Color("PrimaryColor") : .secondary)
            }
            .buttonStyle(.plain)
            .padding(.top, 10)

            VStack(alignment: .leading, spacing: 4) {

                //Metine basınca pdf aç
                Button {
                    showKvkkSheet = true
                } label: {
                    Text("Kullanım şartları ve gizlilik politikasını")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.blue)
                        .italic()
                }
                .buttonStyle(.plain)

                Text("okudum, onaylıyorum.")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color("SecondaryColor"))
            }
        }
        .sheet(isPresented: $showKvkkSheet) {

            //pdf ekranı kapanınca: okunduysa otomatik tikle
            Kvkk(hasRead: $hasReadKvkk)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .onDisappear {
                    if hasReadKvkk {
                        vm.kvkkAccepted = true
                    }
                }
        }
    }

    var signUpButton: some View {
        Button {
            vm.signUp()
        } label: {
            Text("KAYIT OL")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color(.systemYellow))
                .cornerRadius(14)
                .shadow(radius: 6, y: 3)
        }
        .buttonStyle(.plain)
        .padding(.top, 15)
    }

    var loginRedirect: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                Text("Hesabın var mı?")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)

                Button {
                    dismiss()
                } label: {
                    Text("Giriş yap")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color("PrimaryColor"))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 20)
        }
    }

    var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.2).ignoresSafeArea()
            ProgressView()
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
        }
    }
}

#Preview {
    SignUp()
}
