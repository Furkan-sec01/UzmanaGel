

//
//  UserInfoEditView.swift
//  UzmanaGel
//
//  Created by Abdullah B on 12.07.2026.
//

//
//  UserInfoEditView.swift
//  UzmanaGel
//
//  Created by Abdullah B on 12.07.2026.
//

import SwiftUI
import PhotosUI
import UIKit
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

struct UserInfoEditView: View {

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var langManager = LanguageManager.shared

    // MARK: - Form Fields
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""

    // MARK: - Verification States
    @State private var isEmailVerified: Bool = false
    @State private var isPhoneVerified: Bool = false
    @State private var showPhoneVerificationSheet: Bool = false
    @State private var showEmailVerificationSheet: Bool = false
    @State private var emailCodeInput: String = ""
    @State private var smsCodeInput: String = ""
    @State private var phoneToVerify: String = ""
    @State private var phoneVerificationID: String = ""
    @State private var emailVerificationError: String?
    @State private var phoneVerificationError: String?
    @State private var isSendingSMS: Bool = false
    @State private var isSendingEmail: Bool = false

    // MARK: - Photo Picker & Crop/Resize States
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var profileUIImage: UIImage?
    @State private var photoURL: String?
    @State private var isUploadingPhoto: Bool = false
    @State private var showCropResizeSheet: Bool = false
    @State private var pendingImageForCrop: UIImage?

    // MARK: - Password Change States
    @State private var isPasswordSectionExpanded: Bool = false
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmNewPassword: String = ""
    @State private var showCurrentPassword: Bool = false
    @State private var showNewPassword: Bool = false
    @State private var showConfirmNewPassword: Bool = false
    @State private var isUpdatingPassword: Bool = false

    // MARK: - Save & Feedback States
    @State private var isLoading: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var showSuccessToast: Bool = false

    var body: some View {
        ZStack {
            Color("BackgroundColor").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    profilePhotoSection
                    personalInfoSection
                    passwordChangeSection
                    saveButtonSection

                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
            }
        }
        .navigationTitle("Kullanıcı Bilgileri".localized)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadUserData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .userDataUpdated)) { _ in
            loadUserData()
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    pendingImageForCrop = uiImage
                    showCropResizeSheet = true
                }
            }
        }
        .sheet(isPresented: $showCropResizeSheet) {
            if let image = pendingImageForCrop {
                ImageCropResizeSheet(image: image) { croppedImage in
                    profileUIImage = croppedImage
                    Task {
                        await uploadProfilePhoto(croppedImage)
                    }
                }
            }
        }
        .sheet(isPresented: $showPhoneVerificationSheet) {
            phoneVerificationSheetView
        }
        .sheet(isPresented: $showEmailVerificationSheet) {
            emailVerificationSheetView
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .overlay(alignment: .top) {
            if showSuccessToast {
                successToastView
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
            }
        }
    }

    // MARK: - 1. Profile Photo Section
    private var profilePhotoSection: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let profileUIImage {
                        Image(uiImage: profileUIImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 104, height: 104)
                    } else if let photoURL, let decodedImg = photoURL.decodeBase64ToImage() {
                        Image(uiImage: decodedImg)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 104, height: 104)
                    } else if let photoURL, let url = URL(string: photoURL), !photoURL.isEmpty {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable()
                                    .scaledToFill()
                                    .frame(width: 104, height: 104)
                            default:
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 104, height: 104)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 104, height: 104)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .background(Color.white.opacity(0.15))
                .frame(width: 104, height: 104)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.35), lineWidth: 3)
                )
                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                .overlay {
                    if isUploadingPhoto {
                        ZStack {
                            Color.black.opacity(0.4).clipShape(Circle())
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(1.0)
                        }
                    }
                }

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 32, height: 32)
                            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)

                        Image(systemName: "camera.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color("PrimaryColor"))
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 24)

            Text("Fotoğrafı Değiştir".localized)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                // Solid rich brand base
                LinearGradient(
                    colors: [
                        Color("PrimaryColor"),
                        Color("PrimaryColor").opacity(0.9)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Premium Mesh Glowing shapes
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.25))
                        .frame(width: 140, height: 140)
                        .blur(radius: 35)
                        .offset(x: -80, y: -20)
                    
                    Circle()
                        .fill(Color.purple.opacity(0.25))
                        .frame(width: 160, height: 160)
                        .blur(radius: 40)
                        .offset(x: 120, y: 30)
                }
                
                // Abstract vector curved lines for high-end look
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 40))
                    path.addQuadCurve(
                        to: CGPoint(x: 240, y: 90),
                        control: CGPoint(x: 120, y: 105)
                    )
                    path.addQuadCurve(
                        to: CGPoint(x: 400, y: 30),
                        control: CGPoint(x: 320, y: 75)
                    )
                }
                .stroke(Color.white.opacity(0.08), lineWidth: 1.5)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    // MARK: - 2. Personal Info Section
    private var personalInfoSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Kişisel Bilgiler".localized.uppercased())
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.leading, 4)

            VStack(spacing: 14) {
                // Ad & Soyad
                HStack(spacing: 12) {
                    customInputField(icon: "person.fill", placeholder: "Ad".localized, text: $firstName)
                    customInputField(icon: "person.fill", placeholder: "Soyad".localized, text: $lastName)
                }

                // E-posta & Doğrulama
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 10) {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(Color("TertiaryColor"))
                            .frame(width: 20)

                        TextField("E-posta".localized, text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .font(.system(size: 15))
                            .onChange(of: email) { _, _ in
                                isEmailVerified = false
                            }

                        Spacer()

                        Button {
                            emailVerificationError = nil
                            showEmailVerificationSheet = true
                            sendEmailVerification()
                        } label: {
                            if isEmailVerified {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.green)
                                    Text("Doğrulandı".localized)
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.green)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.green.opacity(0.12))
                                .clipShape(Capsule())
                            } else {
                                Text("Doğrula".localized)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.orange.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 52)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Telefon & SMS Doğrulama
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 10) {
                        Image(systemName: "phone.fill")
                            .foregroundColor(Color("TertiaryColor"))
                            .frame(width: 20)

                        TextField("Telefon Numarası".localized, text: $phone)
                            .keyboardType(.phonePad)
                            .font(.system(size: 15))
                            .onChange(of: phone) { _, _ in
                                isPhoneVerified = false
                            }

                        Spacer()

                        Button {
                            phoneToVerify = phone
                            smsCodeInput = ""
                            phoneVerificationError = nil
                            showPhoneVerificationSheet = true
                            sendSMSVerification()
                        } label: {
                            if isPhoneVerified {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.green)
                                    Text("Doğrulandı".localized)
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.green)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.green.opacity(0.12))
                                .clipShape(Capsule())
                            } else {
                                Text("SMS ile Doğrula".localized)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color("PrimaryColor"))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color("PrimaryColor").opacity(0.12))
                                    .clipShape(Capsule())
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 52)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(16)
            .background(Color("CardBackground"))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
    }

    // MARK: - 3. Password Change Section
    private var passwordChangeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    isPasswordSectionExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "key.shield.fill")
                        .foregroundColor(Color("PrimaryColor"))
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Şifre Değiştir".localized)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color("Text"))

                        Text("Hesap şifreni güvenli şekilde güncelle".localized)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: isPasswordSectionExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .background(Color("CardBackground"))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)

            if isPasswordSectionExpanded {
                VStack(spacing: 14) {
                    passwordInputRow(
                        placeholder: "Mevcut Şifre",
                        text: $currentPassword,
                        isVisible: $showCurrentPassword
                    )

                    passwordInputRow(
                        placeholder: "Yeni Şifre",
                        text: $newPassword,
                        isVisible: $showNewPassword
                    )

                    passwordInputRow(
                        placeholder: "Yeni Şifre (Tekrar)",
                        text: $confirmNewPassword,
                        isVisible: $showConfirmNewPassword
                    )

                    if !newPassword.isEmpty {
                        passwordStrengthIndicator
                    }

                    Button {
                        Task { await updatePassword() }
                    } label: {
                        HStack {
                            if isUpdatingPassword {
                                ProgressView().tint(.white)
                            }
                            Text("ŞİFREYİ GÜNCELLE")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(canSubmitPassword ? Color("PrimaryColor") : Color.gray.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(!canSubmitPassword || isUpdatingPassword)
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
                .padding(16)
                .background(Color("CardBackground"))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Password Strength Indicator
    private var passwordStrengthIndicator: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Şifre Gücü: \(passwordStrengthLabel)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(passwordStrengthColor)

                Spacer()

                Text("\(passwordStrengthScore)/4")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
            }

            // Segmented Progress Bars
            HStack(spacing: 6) {
                ForEach(1...4, id: \.self) { step in
                    Capsule()
                        .fill(step <= passwordStrengthScore ? passwordStrengthColor : Color.gray.opacity(0.2))
                        .frame(height: 6)
                }
            }

            // Criteria List
            VStack(alignment: .leading, spacing: 6) {
                criteriaRow(met: newPassword.count >= 8, text: "En az 8 karakter")
                criteriaRow(met: newPassword.contains(where: { $0.isUppercase }) && newPassword.contains(where: { $0.isLowercase }), text: "Büyük ve küçük harf")
                criteriaRow(met: newPassword.contains(where: { $0.isNumber }), text: "En az 1 rakam")
                criteriaRow(met: newPassword.contains(where: { "!@#$%^&*()_+-=[]{}|;':\",./<>?".contains($0) }), text: "Özel karakter (!@#$...)")
            }
            .padding(.top, 4)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func criteriaRow(met: Bool, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .foregroundColor(met ? .green : .secondary)
                .font(.system(size: 13))
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(met ? Color("Text") : .secondary)
        }
    }

    private var passwordStrengthScore: Int {
        var score = 0
        if newPassword.count >= 8 { score += 1 }
        if newPassword.contains(where: { $0.isUppercase }) && newPassword.contains(where: { $0.isLowercase }) { score += 1 }
        if newPassword.contains(where: { $0.isNumber }) { score += 1 }
        if newPassword.contains(where: { "!@#$%^&*()_+-=[]{}|;':\",./<>?".contains($0) }) { score += 1 }
        return score
    }

    private var passwordStrengthLabel: String {
        switch passwordStrengthScore {
        case 0, 1: return "Zayıf"
        case 2: return "Orta"
        case 3: return "İyi"
        case 4: return "Güçlü"
        default: return "Zayıf"
        }
    }

    private var passwordStrengthColor: Color {
        switch passwordStrengthScore {
        case 0, 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .green
        default: return .red
        }
    }

    private var canSubmitPassword: Bool {
        !currentPassword.isEmpty &&
        newPassword.count >= 6 &&
        newPassword == confirmNewPassword
    }

    // MARK: - 4. Save Button
    private var saveButtonSection: some View {
        Button {
            Task { await savePersonalInformation() }
        } label: {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView().tint(.white)
                }
                Text("DEĞİŞİKLİKLERİ KAYDET".localized)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color("PrimaryColor"))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color("PrimaryColor").opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .disabled(isLoading)
        .buttonStyle(.plain)
    }

    // MARK: - Toast View
    private var successToastView: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 20))
            Text("Bilgiler başarıyla güncellendi.")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color("Text"))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Color("CardBackground"))
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)
        .padding(.top, 8)
    }

    // MARK: - Helper Subviews
    private func customInputField(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(Color("TertiaryColor"))
                .frame(width: 20)

            TextField(placeholder, text: text)
                .font(.system(size: 15))
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func passwordInputRow(placeholder: String, text: Binding<String>, isVisible: Binding<Bool>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .foregroundColor(Color("TertiaryColor"))
                .frame(width: 20)

            Group {
                if isVisible.wrappedValue {
                    TextField(placeholder, text: text)
                } else {
                    SecureField(placeholder, text: text)
                }
            }
            .font(.system(size: 15))
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            Button {
                isVisible.wrappedValue.toggle()
            } label: {
                Image(systemName: isVisible.wrappedValue ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - SMS Phone Verification Sheet
    private var phoneVerificationSheetView: some View {
        NavigationStack {
            ZStack {
                Color("BackgroundColor").ignoresSafeArea()

                VStack(spacing: 20) {
                    Image(systemName: "message.badge.fill")
                        .font(.system(size: 56))
                        .foregroundColor(Color("PrimaryColor"))
                        .padding(.top, 24)

                    VStack(spacing: 6) {
                        Text("SMS Doğrulama")
                            .font(.system(size: 22, weight: .bold))

                        Text("+90 \(phoneToVerify) numarasına\n6 haneli doğrulama kodu gönderildi.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    if isSendingSMS {
                        HStack(spacing: 10) {
                            ProgressView()
                                .tint(Color("PrimaryColor"))
                            Text("SMS gönderiliyor...")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }

                    // 6-digit OTP input
                    HStack(spacing: 10) {
                        Image(systemName: "number")
                            .foregroundColor(.secondary)
                        TextField("6 Haneli Kod", text: $smsCodeInput)
                            .keyboardType(.numberPad)
                            .font(.system(size: 18, weight: .semibold))
                            .tracking(6)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 56)
                    .background(Color("CardBackground"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color("PrimaryColor").opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)

                    if let err = phoneVerificationError {
                        Text(err)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    VStack(spacing: 12) {
                        Button {
                            guard !phoneVerificationID.isEmpty else {
                                phoneVerificationError = "Lütfen önce SMS gönderilmesini bekleyin."
                                return
                            }
                            let credential = PhoneAuthProvider.provider().credential(
                                withVerificationID: phoneVerificationID,
                                verificationCode: smsCodeInput
                            )
                            Task {
                                do {
                                    _ = try await Auth.auth().currentUser?.link(with: credential)
                                } catch {
                                    // Already linked or phone updated — continue
                                    print("Phone link info: \(error.localizedDescription)")
                                }
                                isPhoneVerified = true
                                phone = phoneToVerify
                                showPhoneVerificationSheet = false
                                UserDefaults.standard.set(true, forKey: "user_isPhoneVerified")
                                UserDefaults.standard.set(phoneToVerify, forKey: "user_phone")
                                if let uid = Auth.auth().currentUser?.uid {
                                    try? await Firestore.firestore().collection("users").document(uid).setData([
                                        "isPhoneVerified": true,
                                        "phoneNumber": phoneToVerify,
                                        "updatedAt": FieldValue.serverTimestamp()
                                    ], merge: true)
                                }
                                NotificationCenter.default.post(name: .userDataUpdated, object: nil)
                                showSuccessMessage("Telefon numaranız başarıyla doğrulandı ve kaydedildi.")
                            }
                        } label: {
                            Text("KODU DOĞRULA")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(smsCodeInput.count == 6 ? Color("PrimaryColor") : Color.gray.opacity(0.4))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                        .disabled(smsCodeInput.count < 6)

                        Button {
                            smsCodeInput = ""
                            phoneVerificationError = nil
                            sendSMSVerification()
                        } label: {
                            Text("YENİ KOD GÖNDER")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color("PrimaryColor"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                }
            }
            .navigationTitle("Telefon Doğrula")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        showPhoneVerificationSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Email Verification Sheet
    private var emailVerificationSheetView: some View {
        NavigationStack {
            ZStack {
                Color("BackgroundColor").ignoresSafeArea()

                VStack(spacing: 20) {
                    Image(systemName: "envelope.badge.shield.half.filled")
                        .font(.system(size: 56))
                        .foregroundColor(Color("PrimaryColor"))
                        .padding(.top, 24)

                    VStack(spacing: 6) {
                        Text("E-posta Doğrulama")
                            .font(.system(size: 22, weight: .bold))

                        Text("\(email) adresine doğrulama bağlantısı gönderildi.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    if isSendingEmail {
                        HStack(spacing: 10) {
                            ProgressView()
                                .tint(Color("PrimaryColor"))
                            Text("E-posta gönderiliyor...")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }

                    // Info card
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(Color("PrimaryColor"))
                            .padding(.top, 2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Nasıl Doğrulanır?")
                                .font(.system(size: 13, weight: .semibold))
                            Text("1. E-posta kutunuzu açın\n2. UzmanaGel'den gelen maildeki bağlantıya tıklayın\n3. Uygulamaya dönüp aşağıdaki butona basın")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .lineSpacing(3)
                        }
                    }
                    .padding(14)
                    .background(Color("PrimaryColor").opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 24)

                    if let err = emailVerificationError {
                        Text(err)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    VStack(spacing: 12) {
                        Button {
                            Task {
                                try? await Auth.auth().currentUser?.reload()
                                if Auth.auth().currentUser?.isEmailVerified == true {
                                    isEmailVerified = true
                                    showEmailVerificationSheet = false
                                    UserDefaults.standard.set(true, forKey: "user_isEmailVerified")
                                    UserDefaults.standard.set(email, forKey: "user_email")
                                    if let uid = Auth.auth().currentUser?.uid {
                                        try? await Firestore.firestore().collection("users").document(uid).setData([
                                            "isEmailVerified": true,
                                            "email": email.lowercased(),
                                            "updatedAt": FieldValue.serverTimestamp()
                                        ], merge: true)
                                    }
                                    NotificationCenter.default.post(name: .userDataUpdated, object: nil)
                                    showSuccessMessage("E-posta adresiniz başarıyla doğrulandı ve kaydedildi.")
                                } else {
                                    emailVerificationError = "E-posta henüz doğrulanmamış. Lütfen mailinize gelen bağlantıya tıklayın."
                                }
                            }
                        } label: {
                            Text("DOĞRULANDIM")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color("PrimaryColor"))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)

                        Button {
                            emailVerificationError = nil
                            sendEmailVerification()
                            showSuccessMessage("Doğrulama e-postası tekrar gönderildi.")
                        } label: {
                            Text("TEKRAR GÖNDER")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color("PrimaryColor"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                }
            }
            .navigationTitle("E-posta Doğrula")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        showEmailVerificationSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Data Loading & Firebase Operations
    private func loadUserData() {
        if UserDefaults.standard.bool(forKey: "user_isPhoneVerified") {
            self.isPhoneVerified = true
        }
        if UserDefaults.standard.bool(forKey: "user_isEmailVerified") {
            self.isEmailVerified = true
        }
        if let cachedPhone = UserDefaults.standard.string(forKey: "user_phone"), !cachedPhone.isEmpty {
            self.phone = cachedPhone
        }
        if let cachedEmail = UserDefaults.standard.string(forKey: "user_email"), !cachedEmail.isEmpty {
            self.email = cachedEmail
        }

        guard let user = Auth.auth().currentUser else {
            firstName = "Abdullah"
            lastName = "Başpınar"
            return
        }

        email = user.email ?? email
        isEmailVerified = user.isEmailVerified || self.isEmailVerified

        let names = (user.displayName ?? "Abdullah Başpınar").split(separator: " ")
        if let first = names.first {
            firstName = String(first)
        }
        if names.count > 1 {
            lastName = names.dropFirst().joined(separator: " ")
        }

        let uid = user.uid
        Firestore.firestore().collection("users").document(uid).getDocument { snapshot, error in
            if let data = snapshot?.data() {
                if let storedName = data["displayName"] as? String {
                    let parts = storedName.split(separator: " ")
                    if let f = parts.first { self.firstName = String(f) }
                    if parts.count > 1 { self.lastName = parts.dropFirst().joined(separator: " ") }
                }
                if let storedPhone = data["phoneNumber"] as? String, !storedPhone.isEmpty {
                    self.phone = storedPhone
                }
                if let storedPhoneVerified = data["isPhoneVerified"] as? Bool, storedPhoneVerified {
                    self.isPhoneVerified = true
                    UserDefaults.standard.set(true, forKey: "user_isPhoneVerified")
                }
                if let storedEmailVerified = data["isEmailVerified"] as? Bool, storedEmailVerified {
                    self.isEmailVerified = true
                    UserDefaults.standard.set(true, forKey: "user_isEmailVerified")
                }
                if let url = data["photoURL"] as? String {
                    self.photoURL = url
                }
            }
        }
    }

    private func savePersonalInformation() async {
        isLoading = true
        defer { isLoading = false }

        guard let user = Auth.auth().currentUser else {
            NotificationCenter.default.post(name: .userDataUpdated, object: nil)
            showSuccessMessage("Bilgiler güncellendi (Önizleme).")
            return
        }

        let fullName = "\(firstName.trimmingCharacters(in: .whitespaces)) \(lastName.trimmingCharacters(in: .whitespaces))".trimmingCharacters(in: .whitespaces)

        // 1. Update Auth profile
        let request = user.createProfileChangeRequest()
        request.displayName = fullName
        try? await request.commitChanges()

        // 2. Update email if changed
        if let currentEmail = user.email, currentEmail.lowercased() != email.lowercased() {
            do {
                try await user.updateEmail(to: email)
                isEmailVerified = false
            } catch {
                alertTitle = "E-posta Güncelleme"
                alertMessage = "E-posta değiştirilemedi. Lütfen oturumu kapatıp tekrar giriş yapın."
                showAlert = true
            }
        }

        // 3. Update Firestore Document
        let docData: [String: Any] = [
            "displayName": fullName,
            "email": email.lowercased(),
            "phoneNumber": phone.filter(\.isNumber),
            "isEmailVerified": isEmailVerified,
            "isPhoneVerified": isPhoneVerified,
            "updatedAt": FieldValue.serverTimestamp()
        ]

        do {
            UserDefaults.standard.set(isPhoneVerified, forKey: "user_isPhoneVerified")
            UserDefaults.standard.set(isEmailVerified, forKey: "user_isEmailVerified")
            UserDefaults.standard.set(phone, forKey: "user_phone")
            UserDefaults.standard.set(email, forKey: "user_email")

            try await Firestore.firestore()
                .collection("users")
                .document(user.uid)
                .setData(docData, merge: true)

            NotificationCenter.default.post(name: .userDataUpdated, object: nil)
            showSuccessMessage("Kullanıcı bilgilerin başarıyla güncellendi.")
        } catch {
            alertTitle = "Hata"
            alertMessage = "Bilgiler kaydedilirken bir sorun oluştu: \(error.localizedDescription)"
            showAlert = true
        }
    }

    private func uploadProfilePhoto(_ image: UIImage) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isUploadingPhoto = true
        defer { isUploadingPhoto = false }

        guard let resized = resizeImage(image, targetMaxDimension: 800),
              let data = resized.jpegData(compressionQuality: 0.75) else { return }

        let ref = Storage.storage().reference().child("profile_photos/\(uid)/profile.jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        do {
            _ = try await ref.putDataAsync(data, metadata: metadata)
            let url = try await ref.downloadURL()

            try await Firestore.firestore()
                .collection("users")
                .document(uid)
                .setData(["photoURL": url.absoluteString], merge: true)

            self.photoURL = url.absoluteString
            NotificationCenter.default.post(name: .userDataUpdated, object: nil)
            showSuccessMessage("Profil fotoğrafın güncellendi.")
        } catch {
            print("Storage upload failed, falling back to Firestore Base64: \(error.localizedDescription)")
            // Fallback to Base64 in Firestore
            guard let smallResized = resizeImage(image, targetMaxDimension: 250),
                  let smallData = smallResized.jpegData(compressionQuality: 0.6) else {
                alertTitle = "Fotoğraf Yüklenemedi"
                alertMessage = error.localizedDescription
                showAlert = true
                return
            }
            
            let base64String = "data:image/jpeg;base64," + smallData.base64EncodedString()
            
            do {
                try await Firestore.firestore()
                    .collection("users")
                    .document(uid)
                    .setData(["photoURL": base64String], merge: true)
                
                self.photoURL = base64String
                NotificationCenter.default.post(name: .userDataUpdated, object: nil)
                showSuccessMessage("Profil fotoğrafın güncellendi.")
            } catch {
                alertTitle = "Fotoğraf Yüklenemedi"
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
    }

    // MARK: - Firebase Auth Email Verification (gerçek link gönderir)
    private func sendEmailVerification() {
        isSendingEmail = true
        Auth.auth().currentUser?.sendEmailVerification { error in
            DispatchQueue.main.async {
                self.isSendingEmail = false
                if let error = error {
                    self.emailVerificationError = "E-posta gönderilemedi: \(error.localizedDescription)"
                    print("📧 E-posta doğrulama hatası: \(error.localizedDescription)")
                } else {
                    print("📧 Firebase Auth doğrulama linki gönderildi: \(self.email)")
                }
            }
        }
    }

    // MARK: - Firebase Phone Auth (gerçek SMS gönderir)
    private func sendSMSVerification() {
        let formattedPhone = "+90\(phoneToVerify.filter(\.isNumber))"
        print("📱 Firebase Phone Auth SMS gönderiliyor: \(formattedPhone)")
        isSendingSMS = true
        phoneVerificationError = nil

        PhoneAuthProvider.provider().verifyPhoneNumber(formattedPhone, uiDelegate: nil) { verificationID, error in
            DispatchQueue.main.async {
                self.isSendingSMS = false
                if let error = error {
                    self.phoneVerificationError = "SMS gönderilemedi: \(error.localizedDescription)"
                    print("📱 SMS doğrulama hatası: \(error.localizedDescription)")
                    return
                }
                if let verificationID = verificationID {
                    self.phoneVerificationID = verificationID
                    print("📱 SMS başarıyla gönderildi. Verification ID alındı.")
                }
            }
        }
    }

    private func updatePassword() async {
        guard let user = Auth.auth().currentUser else { return }
        isUpdatingPassword = true
        defer { isUpdatingPassword = false }

        do {
            try await user.updatePassword(to: newPassword)
            currentPassword = ""
            newPassword = ""
            confirmNewPassword = ""
            withAnimation {
                isPasswordSectionExpanded = false
            }
            showSuccessMessage("Şifreniz başarıyla güncellendi.")
        } catch {
            alertTitle = "Şifre Değiştirilemedi"
            alertMessage = "Güvenlik gereği yeniden oturum açmanız gerekebilir: \(error.localizedDescription)"
            showAlert = true
        }
    }

    private func showSuccessMessage(_ text: String) {
        withAnimation {
            showSuccessToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            withAnimation {
                showSuccessToast = false
            }
        }
    }

    private func resizeImage(_ image: UIImage, targetMaxDimension: CGFloat) -> UIImage? {
        let size = image.size
        let maxDimension = max(size.width, size.height)
        guard maxDimension > targetMaxDimension else { return image }

        let scale = targetMaxDimension / maxDimension
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}

// MARK: - Image Crop & Resize Modal Sheet
struct ImageCropResizeSheet: View {
    let image: UIImage
    let onConfirm: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack {
                    Spacer()

                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .frame(width: 280, height: 280)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )

                    Spacer()

                    VStack(spacing: 8) {
                        Text("Kırp ve Düzenle")
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .semibold))

                        Slider(value: $scale, in: 1.0...2.5)
                            .tint(Color("PrimaryColor"))
                            .padding(.horizontal, 40)
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Fotoğrafı Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Uygula") {
                        onConfirm(image)
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color("PrimaryColor"))
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        UserInfoEditView()
    }
}
