//
//  LoginPage.swift
//  UzmanaGel
//
//  Created by Abdullah B on 29.01.2026.
//

import SwiftUI

struct LoginPage: View {
    @EnvironmentObject private var session: SessionViewModel
    @StateObject private var vm = LoginViewModel()

    @State private var rememberMe = false
    @State private var isPasswordVisible = false

    // Alert göstermek için (vm.errorMessage gelince true yapacağız)
    @State private var showError = false

    // Navigation stack control (geri dönüş olmaması için)
    @State private var path = NavigationPath()

    private enum ExpertSignupDestination: Hashable { case flow }

    var body: some View {
        NavigationStack(path: $path) {

            ZStack {
                Color("BackgroundColor")
                    .ignoresSafeArea()

                VStack(spacing: 18) {

                    Spacer().frame(height: 28)

                    Image("Logo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 110, height: 110)
                        .clipShape(Circle())
                        .shadow(radius: 10)

                    Text("Hoşgeldiniz")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.top, 6)

                    // Email
                    HStack(spacing: 10) {
                        Image(systemName: "envelope")
                            .foregroundColor(.secondary)

                        TextField("E-posta", text: $vm.email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 52)
                    .background(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
                    .cornerRadius(14)

                    // Password
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
                            Image(systemName: isPasswordVisible ?  "eye" : "eye.slash" )
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

                    // Remember + Forgot
                    HStack {
                        Button {
                            rememberMe.toggle()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: rememberMe ? "checkmark.square.fill" : "square")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(rememberMe ? Color("PrimaryColor") : .secondary)

                                Text("Beni Hatırla")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color("PrimaryColor"))
                            }
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        NavigationLink {
                            ForgotPasswordPage()
                        } label: {
                            Text("Şifremi Unuttum")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color("PrimaryColor"))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 2)

                    // Login Button
                    Button {
                        vm.login()
                    } label: {
                        Text("GİRİŞ YAP")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(vm.attemptTracker.isLocked ? Color.gray : Color(.systemYellow))
                            .cornerRadius(14)
                            .shadow(radius: 6, y: 3)
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.attemptTracker.isLocked)
                    .padding(.top, 15)

                    // Divider
                    HStack(spacing: 12) {
                        Rectangle().frame(height: 1).foregroundColor(Color.black.opacity(0.08))
                        Text("VEYA")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        Rectangle().frame(height: 1).foregroundColor(Color.black.opacity(0.08))
                    }
                    .padding(.top, 10)

                    // Social Buttons
                    HStack(spacing: 25) {
                        Button {
                            let vc = getRootViewController()
                            vm.signInWithGoogle(presenting: vc)
                        }  label: {
                            Circle()
                                .fill(Color(.secondarySystemBackground))
                                .frame(width: 54, height: 54)
                                .shadow(radius: 6, y: 3)
                                .overlay(
                                    Image("googleLogo")
                                        .resizable()
                                        .scaledToFit()
                                        .padding(12)
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(vm.attemptTracker.isLocked)
                        .opacity(vm.attemptTracker.isLocked ? 0.4 : 1)

                        NavigationLink {
                            PhoneLoginView()
                        } label: {
                            Circle()
                                .fill(Color(.secondarySystemBackground))
                                .frame(width: 54, height: 54)
                                .shadow(radius: 6, y: 3)
                                .overlay(
                                    Image(systemName: "phone.fill")
                                        .font(.system(size: 26, weight: .semibold))
                                        .foregroundColor(.primary)
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(vm.attemptTracker.isLocked)
                        .opacity(vm.attemptTracker.isLocked ? 0.4 : 1)
                    }
                    .padding(.top, 10)

                    // Sign up + Expert
                    VStack(spacing: 10) {
                        HStack(spacing: 6) {
                            Text("Hesabın yok mu?")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)

                            NavigationLink {
                                SignUp()
                            } label: {
                                Text("Kayıt Ol")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(Color("PrimaryColor"))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 20)

                        HStack {
                            Text("Uzman mısın?")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.orange)

                            Button {
                                session.startExpertSignup()
                                path.append(ExpertSignupDestination.flow)
                            } label: {
                                Text("Başvuru Yap")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.orange)
                                    .underline()
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 10)
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)

                // Loading overlay
                if vm.isLoading {
                    ZStack {
                        Color.black.opacity(0.2).ignoresSafeArea()
                        ProgressView()
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                    }
                }
            }

            // Giriş başarılı olunca RootView otomatik olarak ExpertHomepage veya Homepage gösterir (rol kontrolü orada).

            // ViewModel errorMessage değişince alert aç
            .onChange(of: vm.errorMessage) { _, msg in
                showError = (msg != nil)
            }

            .alert("Hata", isPresented: $showError) {
                Button("Tamam", role: .cancel) {
                    vm.clearError()
                }
            } message: {
                Text(vm.errorMessage ?? "Bilinmeyen hata")
            }

            // route tanımı
            .navigationDestination(for: String.self) { value in
                if value == "home" {
                    Homepage()
                        .navigationBarBackButtonHidden(true)
                }
            }
            .navigationDestination(for: ExpertSignupDestination.self) { _ in
                if let vm = session.expertSignUpViewModel {
                    ExpertSignUpView(vm: vm)
                        .environmentObject(session)
                }
            }
        }
    }
}
private func getRootViewController() -> UIViewController {
    guard
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
        let root = scene.windows.first?.rootViewController
    else {
        return UIViewController()
    }
    return root
}

#Preview {
    LoginPage()
}
