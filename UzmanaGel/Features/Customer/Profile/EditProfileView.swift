import SwiftUI
import PhotosUI

struct EditProfileView: View {
    let profile: UserProfile
    var onProfileUpdate: (UserProfile) -> Void
    
    @StateObject private var viewModel: EditProfileViewModel
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var showCropSimulation = false
    @State private var cropScale: CGFloat = 1.0
    @ObservedObject private var langManager = LanguageManager.shared
    
    init(profile: UserProfile, onProfileUpdate: @escaping (UserProfile) -> Void) {
        self.profile = profile
        self.onProfileUpdate = onProfileUpdate
        self._viewModel = StateObject(wrappedValue: EditProfileViewModel(profile: profile))
    }
    
    var body: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Constants.spacingL) {
                    // Profile Photo Edit Block
                    VStack(spacing: Constants.spacingS) {
                        AvatarView(
                            imageURLString: viewModel.profileImageURL,
                            size: 110,
                            isEditable: true
                        ) {
                            // Programmatic click handled by PhotosPicker overlay below
                        }
                        .overlay {
                            PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                                Color.clear
                            }
                            .frame(width: 110, height: 110)
                            .clipShape(Circle())
                        }
                        
                        Text("Fotoğrafı Değiştir".localized)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color.themePrimary)
                    }
                    .padding(.top)
                    
                    // Main Form Info
                    CardView {
                        VStack(alignment: .leading, spacing: Constants.spacingM) {
                            Text("Kişisel Bilgiler".localized)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(Color.themeSecondaryText)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Ad Soyad".localized)
                                    .font(.caption)
                                    .foregroundColor(Color.themeSecondaryText)
                                TextField("Ad Soyad".localized, text: $viewModel.displayName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("E-posta".localized)
                                    .font(.caption)
                                    .foregroundColor(Color.themeSecondaryText)
                                TextField("E-posta".localized, text: $viewModel.email)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                if viewModel.isEmailChanged {
                                    HStack(spacing: Constants.spacingXS) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .foregroundColor(Color.themeWarning)
                                        Text("E-posta değişikliği doğrulama maili gerektirir.".localized)
                                            .font(.caption2)
                                            .foregroundColor(Color.themeWarning)
                                    }
                                    .padding(.top, 2)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Telefon Numarası".localized)
                                    .font(.caption)
                                    .foregroundColor(Color.themeSecondaryText)
                                HStack {
                                    TextField("Telefon Numarası".localized, text: $viewModel.phone)
                                        .keyboardType(.phonePad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                    
                                    if viewModel.isPhoneChanged {
                                        Button {
                                            viewModel.startPhoneVerificationFlow()
                                        } label: {
                                            Text("Doğrula".localized)
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.themePrimary)
                                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                        }
                                    }
                                }
                            }
                            
                            Button {
                                Task {
                                    await viewModel.saveProfile(onSuccess: onProfileUpdate)
                                }
                            } label: {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Değişiklikleri Kaydet".localized)
                                        .fontWeight(.semibold)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.themePrimary)
                            .clipShape(RoundedRectangle(cornerRadius: Constants.radiusM))
                            .disabled(viewModel.isLoading)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Password Change Section
                    CardView {
                        VStack(alignment: .leading, spacing: Constants.spacingM) {
                            Text("Şifre Değiştir".localized)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(Color.themeSecondaryText)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Mevcut Şifre".localized)
                                    .font(.caption)
                                    .foregroundColor(Color.themeSecondaryText)
                                SecureField("Mevcut Şifre".localized, text: $viewModel.currentPassword)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Yeni Şifre".localized)
                                    .font(.caption)
                                    .foregroundColor(Color.themeSecondaryText)
                                SecureField("Yeni Şifre".localized, text: $viewModel.newPassword)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                // Password strength bar
                                if !viewModel.newPassword.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 4) {
                                            ForEach(0..<4) { index in
                                                RoundedRectangle(cornerRadius: 2)
                                                    .fill(index < viewModel.passwordStrength ? viewModel.passwordStrengthColor : Color.themeBorder)
                                                    .frame(height: 4)
                                            }
                                        }
                                        Text("\("Şifre Gücü: ".localized)\(viewModel.passwordStrengthText.localized)")
                                            .font(.caption2)
                                            .foregroundColor(viewModel.passwordStrengthColor)
                                            .fontWeight(.semibold)
                                    }
                                    .padding(.top, 2)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Yeni Şifre (Tekrar)".localized)
                                    .font(.caption)
                                    .foregroundColor(Color.themeSecondaryText)
                                SecureField("Yeni Şifre (Tekrar)".localized, text: $viewModel.confirmPassword)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            Button {
                                Task {
                                    await viewModel.updatePassword()
                                }
                            } label: {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Şifreyi Güncelle".localized)
                                        .fontWeight(.semibold)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.themeSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: Constants.radiusM))
                            .disabled(viewModel.isLoading)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, Constants.paddingXL)
            }
            
            // Status HUD / Alert Toast
            if let errorMsg = viewModel.errorMessage {
                statusOverlay(message: errorMsg.localized, isError: true)
            }
            
            if let successMsg = viewModel.successMessage {
                statusOverlay(message: successMsg.localized, isError: false)
            }
        }
        .navigationTitle("Bilgileri Düzenle".localized)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    viewModel.selectedImageData = data
                    showCropSimulation = true
                }
            }
        }
        // SMS Code Dialog Sheet
        .sheet(isPresented: $viewModel.showSMSVerification) {
            smsVerificationSheet
        }
        // Crop simulation overlay
        .fullScreenCover(isPresented: $showCropSimulation) {
            cropSimulationView
        }
    }
    
    // MARK: - Overlays & Panels
    
    private var smsVerificationSheet: some View {
        NavigationStack {
            VStack(spacing: Constants.spacingL) {
                Image(systemName: "message.badge.filled.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundColor(Color.themePrimary)
                    .padding(.top)
                
                VStack(spacing: Constants.spacingS) {
                    Text("SMS Doğrulama".localized)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text(String(format: "%@ numaralı telefona gönderilen 4 haneli doğrulama kodunu girin.\n(Mock Kodu: 1234)".localized, viewModel.targetPhoneNumber))
                        .font(.caption)
                        .foregroundColor(Color.themeSecondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Constants.paddingL)
                }
                
                TextField("Doğrulama Kodu".localized, text: $viewModel.smsCodeInput)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()
                    .frame(width: 160)
                    .background(Color.themeBorder.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                Button {
                    Task {
                        await viewModel.confirmSMSCode(onSuccess: onProfileUpdate)
                    }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Onayla ve Telefonu Güncelle".localized)
                            .fontWeight(.semibold)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.themePrimary)
                .clipShape(RoundedRectangle(cornerRadius: Constants.radiusM))
                .disabled(viewModel.isLoading)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Doğrulama".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat".localized) {
                        viewModel.showSMSVerification = false
                    }
                }
            }
            .background(Color.themeBackground)
        }
    }
    
    private var cropSimulationView: some View {
        NavigationStack {
            VStack {
                Text("Görseli Kırp / Ölçeklendir".localized)
                    .font(.headline)
                    .padding(.top)
                
                Spacer()
                
                if let data = viewModel.selectedImageData, let uiImage = UIImage(data: data) {
                    ZStack {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(cropScale)
                            .frame(width: 250, height: 250)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 3))
                            .shadow(radius: 10)
                        
                        Circle()
                            .stroke(Color.themePrimary, style: StrokeStyle(lineWidth: 2, dash: [5]))
                            .frame(width: 260, height: 260)
                    }
                }
                
                Spacer()
                
                Slider(value: $cropScale, in: 0.8...2.0)
                    .padding()
                Text(String(format: "Ölçek: %%%d".localized, Int(cropScale * 100)))
                    .font(.caption)
                    .foregroundColor(Color.themeSecondaryText)
                
                Button("Kırp ve Uygula".localized) {
                    showCropSimulation = false
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.themePrimary)
                .clipShape(RoundedRectangle(cornerRadius: Constants.radiusM))
                .padding()
            }
            .navigationTitle("Kırpma".localized)
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.themeBackground)
        }
    }
    
    @ViewBuilder
    private func statusOverlay(message: String, isError: Bool) -> some View {
        VStack {
            Spacer()
            HStack(spacing: Constants.spacingS) {
                Image(systemName: isError ? "xmark.octagon.fill" : "checkmark.seal.fill")
                    .foregroundColor(.white)
                Text(message)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .padding()
            .background(isError ? Color.themeError.opacity(0.9) : Color.themeSuccess.opacity(0.9))
            .clipShape(Capsule())
            .shadow(radius: 5)
            .padding(.bottom, Constants.paddingXL)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    if isError {
                        viewModel.errorMessage = nil
                    } else {
                        viewModel.successMessage = nil
                    }
                }
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut, value: isError ? viewModel.errorMessage : viewModel.successMessage)
    }
}

#Preview {
    NavigationStack {
        EditProfileView(profile: UserProfile(
            id: "cust_preview",
            displayName: "Bahar Yılmaz",
            email: "bahar@yilmaz.com",
            phoneNumber: "+90 532 999 88 77",
            photoURL: nil,
            role: .customer,
            memberSince: Date()
        )) { _ in }
    }
}
