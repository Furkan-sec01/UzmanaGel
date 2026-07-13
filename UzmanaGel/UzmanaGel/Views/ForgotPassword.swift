//
//  ForgotPasswordPage.swift
//  UzmanaGel
//
//  Created by Abdullah B on 03.02.2026.
//

import SwiftUI
import FirebaseAuth

struct ForgotPasswordPage: View {

    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var isLoading = false

    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    var body: some View {
        ZStack {
            Color("BackgroundColor")
                .ignoresSafeArea()

            VStack(spacing: 18) {
                
                Spacer().frame(height: 28)

                VStack(spacing: 6) {
                    Text("Şifremi Unuttum")
                        .font(.system(size: 22, weight: .bold))
                    
                    

                    Text("E-postanı gir. Şifre yenileme linkini mail olarak göndereceğiz.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Email field
                HStack(spacing: 10) {
                    Image(systemName: "envelope")
                        .foregroundColor(.secondary)

                    TextField("E-posta", text: $email)
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

                // Send button
                Button {
                    sendReset()
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color(.systemYellow))
                            .cornerRadius(14)
                    } else {
                        Text("Şifreni Yenile")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color(.systemYellow))
                            .cornerRadius(14)
                            .shadow(radius: 6, y: 3)
                    }
                }
                .buttonStyle(.plain)
                .disabled(isLoading || emailTrimmed.isEmpty)
                .opacity((isLoading || emailTrimmed.isEmpty) ? 0.6 : 1)

                Button {
                    dismiss()
                } label: {
                    Text("Giriş ekranına dön")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .padding(.top, 6)

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("Tamam") {
                // Başarılıysa login'e dön
                if alertTitle == "Mail Gönderildi" {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }

    private var emailTrimmed: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func sendReset() {
        isLoading = true

        Auth.auth().sendPasswordReset(withEmail: emailTrimmed) { error in
            isLoading = false

            if let error {
                alertTitle = "Hata"
                alertMessage = friendlyFirebaseError(error)
                showAlert = true
            } else {
                alertTitle = "Mail Gönderildi"
                alertMessage = "Şifre yenileme linkini e-postana gönderdik. Gelen kutusu / spam klasörünü kontrol et."
                showAlert = true
            }
        }
    }

    private func friendlyFirebaseError(_ error: Error) -> String {
        let ns = error as NSError
        // En sık görülenleri kullanıcı dostu yapalım
        switch ns.code {
        case AuthErrorCode.invalidEmail.rawValue:
            return "E-posta formatı geçersiz."
        case AuthErrorCode.userNotFound.rawValue:
            return "Bu e-posta ile kayıtlı kullanıcı bulunamadı."
        case AuthErrorCode.networkError.rawValue:
            return "İnternet bağlantını kontrol et."
        default:
            return error.localizedDescription
        }
    }
}
