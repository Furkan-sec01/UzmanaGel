//
//  OTPView.swift
//  UzmanaGel
//
//  Created by Abdullah B on 2.02.2026.
//

import SwiftUI

struct OTPView: View {

    @ObservedObject var vm: PhoneAuthViewModel
    @State private var showError = false

    var body: some View {
        ZStack {
            Color("BackgroundColor").ignoresSafeArea()

            VStack(spacing: 18) {
                Text("SMS Kodunu Gir")
                    .font(.system(size: 22, weight: .bold))
                    .padding(.top, 10)

                Text("+90 \(formatPhone(vm.phone10)) numarasına gönderilen 6 haneli kodu girin.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                HStack(spacing: 10) {
                    Image(systemName: "number")
                        .foregroundColor(.secondary)

                    TextField("6 haneli kod", text: $vm.smsCode)
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
                    vm.verifyCode()
                } label: {
                    Text("DOĞRULA")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(vm.attemptTracker.isLocked ? Color.gray : Color("PrimaryColor"))
                        .cornerRadius(14)
                        .shadow(radius: 6, y: 3)
                }
                .buttonStyle(.plain)
                .disabled(vm.isLoading || vm.attemptTracker.isLocked || vm.smsCode.filter(\.isNumber).count != 6)
                .opacity(!vm.attemptTracker.isLocked && vm.smsCode.filter(\.isNumber).count == 6 && !vm.isLoading ? 1 : 0.6)
                .padding(.top, 10)

                // Tekrar Kod Gönder
                if vm.resendCountdown > 0 {
                    Text("Tekrar kod gönder (\(vm.resendCountdown)s)")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                } else {
                    Button {
                        vm.resendCode()
                    } label: {
                        Text("Kodu Tekrar Gönder")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color("PrimaryColor"))
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.isLoading)
                    .padding(.top, 8)
                }

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
        .navigationTitle("Doğrulama")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: vm.errorMessage) { _, msg in
            showError = (msg != nil)
        }
        .alert("Hata", isPresented: $showError) {
            Button("Tamam", role: .cancel) { vm.clearError() }
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    private func formatPhone(_ raw: String) -> String {
        let d = raw.filter(\.isNumber)
        guard d.count == 10 else { return raw }
        return "\(d.prefix(3)) \(d.dropFirst(3).prefix(3)) \(d.dropFirst(6).prefix(2)) \(d.dropFirst(8))"
    }
}
