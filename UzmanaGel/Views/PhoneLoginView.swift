//
//  PhoneLoginView.swift
//  UzmanaGel
//
//  Created by Abdullah B on 2.02.2026.
//

import SwiftUI

struct PhoneLoginView: View {

    @StateObject private var vm = PhoneAuthViewModel()
    @State private var showError = false

    var body: some View {
        ZStack {
            Color("BackgroundColor").ignoresSafeArea()

            VStack(spacing: 18) {
                Text("Telefon ile Giriş")
                    .font(.system(size: 22, weight: .bold))
                    .padding(.top, 10)

                Text("Telefon numaranıza 6 haneli bir doğrulama kodu göndereceğiz.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                HStack(spacing: 10) {
                    Text("+90")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)

                    TextField("5XX XXX XX XX", text: $vm.phone10)
                        .keyboardType(.numberPad)
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

                Button {
                    vm.sendCode()
                } label: {
                    Text("KODU GÖNDER")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(vm.attemptTracker.isLocked ? Color.gray : Color("PrimaryColor"))
                        .cornerRadius(14)
                        .shadow(radius: 6, y: 3)
                }
                .buttonStyle(.plain)
                .disabled(vm.isLoading || vm.attemptTracker.isLocked)
                .opacity(vm.isLoading || vm.attemptTracker.isLocked ? 0.6 : 1)
                .padding(.top, 10)

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)

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
        .navigationTitle("Telefon ile Giriş")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: vm.errorMessage) { _, msg in
            showError = (msg != nil)
        }
        .alert("Hata", isPresented: $showError) {
            Button("Tamam", role: .cancel) { vm.clearError() }
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .navigationDestination(isPresented: $vm.didSendCode) {
            OTPView(vm: vm)
        }
    }
}
