//
//  ProfilePage.swift
//  UzmanaGel
//
//  Created by Abdullah B on 10.02.2026.
//

import SwiftUI
import PhotosUI
import UIKit
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

struct ProfilePage: View {

    @Environment(\.dismiss) private var dismiss

    @State private var fullName: String = "Abdullah Başpınar"
    @State private var email: String = "abdullah@gmail.com"
    @State private var phone: String = "5513432910"

    @State private var reservationsCount: Int = 0
    @State private var favoritesCount: Int = 0

    @State private var isEmailVerified: Bool = false
    @State private var isPhoneVerified: Bool = false

    @State private var showPhoneVerificationSheet: Bool = false
    @State private var showEmailVerificationSheet: Bool = false
    @State private var smsCodeInput: String = ""
    @State private var emailVerificationError: String?
    @State private var phoneVerificationError: String?
    @State private var phoneVerificationID: String = ""
    @State private var isSendingSMS: Bool = false
    @State private var isSendingEmail: Bool = false
    @State private var showSuccessToast: Bool = false
    @State private var toastMessage: String = ""

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var profileUIImage: UIImage?
    @State private var photoURL: String?
    @State private var isUploadingPhoto = false

    @State private var memberSince: String = ""
    @State private var showLogoutAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                header
                statsRow
                contactSection
                accountSection
                historySection
                preferencesSection
                securitySection
                logoutSection

                Spacer(minLength: 24)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .background(Color("BackgroundColor"))
        .navigationTitle("Profil")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadPhotoURL()
            loadFavoritesCount()
            loadReservationsCount()
            loadUserData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .userDataUpdated)) { _ in
            loadPhotoURL()
            loadUserData()
        }
        .sheet(isPresented: $showPhoneVerificationSheet) {
            phoneVerificationSheetView
        }
        .sheet(isPresented: $showEmailVerificationSheet) {
            emailVerificationSheetView
        }
        .overlay(alignment: .top) {
            if showSuccessToast {
                successToastView
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }

            Task {
                isUploadingPhoto = true
                defer { isUploadingPhoto = false }

                guard let data = try? await newItem.loadTransferable(type: Data.self),
                      let uiImage = UIImage(data: data) else {
                    return
                }

                profileUIImage = uiImage
                await uploadProfilePhotoToFirebase(uiImage)
            }
        }
    }

    // MARK: - Header
    private var header: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color("PrimaryColor"), Color("PrimaryColor").opacity(0.75)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 235)

            // Decorative circles
            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 160)
                .offset(x: 130, y: -60)
            Circle()
                .fill(Color.white.opacity(0.04))
                .frame(width: 100)
                .offset(x: -120, y: 70)

            VStack(spacing: 10) {
                ZStack(alignment: .bottomTrailing) {
                    Group {
                        if let profileUIImage {
                            Image(uiImage: profileUIImage)
                                .resizable()
                                .scaledToFill()
                        } else if let photoURL, let url = URL(string: photoURL) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let img):
                                    img.resizable().scaledToFill()
                                default:
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .scaledToFill()
                                }
                            }
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFill()
                        }
                    }
                    .frame(width: 84, height: 84)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(Color.white, lineWidth: 2)
                    )
                    .overlay {
                        if isUploadingPhoto {
                            ProgressView()
                                .tint(.white)
                                .padding(10)
                                .background(Color.black.opacity(0.25))
                                .clipShape(Circle())
                        }
                    }

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                }

                Text(fullName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)

                HStack(spacing: 8) {
                    // Üyelik süresi badge
                    if !memberSince.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar.badge.checkmark")
                                .font(.system(size: 10))
                            Text(memberSince)
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.18))
                        .clipShape(Capsule())
                    }

                    // Düzenle butonu
                    NavigationLink(destination: UserInfoEditView()) {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                                .font(.system(size: 10))
                            Text("Düzenle")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.18))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Stats
    private var statsRow: some View {
        HStack(spacing: 12) {
            NavigationLink {
                MyReservationsPage()
            } label: {
                statCard(value: reservationsCount, title: "Rezervasyonlarım")
            }
            .buttonStyle(.plain)

            NavigationLink {
                FavoritesPage()
            } label: {
                statCard(value: favoritesCount, title: "Favorilerim")
            }
            .buttonStyle(.plain)
        }
    }

    private func statCard(value: Int, title: String) -> some View {
        VStack(spacing: 6) {
            Text("\(value)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color("Text"))

            Text(title)
                .font(.system(size: 12))
                .foregroundColor(Color("Text"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    // MARK: - Contact
    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("İLETİŞİM BİLGİLERİ")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)

            VStack(spacing: 0) {
                contactRow(
                    icon: "envelope",
                    title: email,
                    subtitle: "E-posta",
                    verified: isEmailVerified
                ) {
                    if !isEmailVerified {
                        emailVerificationError = nil
                        showEmailVerificationSheet = true
                        sendEmailVerification()
                    }
                }

                Divider().padding(.leading, 50)

                contactRow(
                    icon: "phone",
                    title: phoneFormatted(phone),
                    subtitle: "Telefon",
                    verified: isPhoneVerified
                ) {
                    if !isPhoneVerified {
                        smsCodeInput = ""
                        phoneVerificationError = nil
                        showPhoneVerificationSheet = true
                        sendSMSVerification()
                    }
                }
            }
            .background(Color("CardBackground"))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        }
    }

    private func contactRow(
        icon: String,
        title: String,
        subtitle: String,
        verified: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 8) {
            NavigationLink(destination: UserInfoEditView()) {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .foregroundColor(Color("TertiaryColor"))
                        .frame(width: 22)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 14, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .truncationMode(.middle)
                        Text(subtitle)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            if verified {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 11))
                    Text("DOĞRULANDI")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.green.opacity(0.14))
                .clipShape(Capsule())
                .fixedSize()
            } else {
                Button {
                    onTap()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 10))
                        Text("DOĞRULA")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .fixedSize()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - Account
    private var accountSection: some View {
        profileSection(title: "HESAP AYARLARI", icon: "person.fill") {
            navigationRow(icon: "person", tint: Color("TertiaryColor"), title: "Kullanıcı Bilgileri", destination: AnyView(UserInfoEditView()))
            divider()
            navigationRow(icon: "mappin.and.ellipse", tint: .red, title: "Adreslerim", destination: AnyView(AddressListView()))
            divider()
            navigationRow(icon: "creditcard.fill", tint: .blue, title: "Ödeme Yöntemleri", destination: AnyView(PaymentMethodsPage()))
        }
    }

    // MARK: - History & Favorites
    private var historySection: some View {
        profileSection(title: "GEÇMİŞ & FAVORİLER", icon: "clock.arrow.circlepath") {
            navigationRow(
                icon: "calendar.badge.clock",
                tint: .indigo,
                title: "Rezervasyonlarım",
                destination: AnyView(MyReservationsPage())
            )

            divider()

            navigationRow(
                icon: "heart.fill",
                tint: .red,
                title: "Favorilerim",
                destination: AnyView(FavoritesPage())
            )
        }
    }

    // MARK: - Preferences
    private var preferencesSection: some View {
        profileSection(title: "TERCİHLER", icon: "slider.horizontal.3") {
            navigationRow(icon: "slider.horizontal.3", tint: .purple, title: "Tercihler", destination: AnyView(PreferencesPage()))
        }
    }

    // MARK: - Security
    private var securitySection: some View {
        profileSection(title: "GÜVENLİK", icon: "shield.fill") {
            navigationRow(icon: "key.shield", tint: Color("TertiaryColor"), title: "Şifre Değiştir", destination: AnyView(ResetPasswordPage()))
        }
    }


    // MARK: - Logout
    private var logoutSection: some View {
        Button {
            showLogoutAlert = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 15))
                Text("Çıkış Yap")
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.red.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .alert("Çıkış Yap", isPresented: $showLogoutAlert) {
            Button("Çıkış Yap", role: .destructive) {
                try? Auth.auth().signOut()
                UserDefaults.standard.removeObject(forKey: "user_isPhoneVerified")
                UserDefaults.standard.removeObject(forKey: "user_isEmailVerified")
            }
            Button("İptal", role: .cancel) {}
        } message: {
            Text("Hesabınızdan çıkmak istediğinizden emin misiniz?")
        }
    }

    // MARK: - Reusable Section Builder
    private func profileSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(Color("PrimaryColor"))
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 0) {
                content()
            }
            .background(Color("CardBackground"))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        }
    }

    private func navigationRow(icon: String, tint: Color, title: String, destination: AnyView) -> some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(tint)
                    .frame(width: 30, height: 30)
                    .background(tint.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color("Text"))

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(14)
        }
        .buttonStyle(.plain)
    }

    private func divider() -> some View { Divider().padding(.leading, 56) }

    // MARK: - Firebase Helpers
    private func uploadProfilePhotoToFirebase(_ image: UIImage) async {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("UID bulunamadı")
            return
        }

        guard let data = image.jpegData(compressionQuality: 0.7) else {
            print("JPEG dönüşüm başarısız")
            return
        }

        let ref = Storage.storage()
            .reference()
            .child("profile_photos/\(uid)/profile.jpg")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        do {
            _ = try await ref.putDataAsync(data, metadata: metadata)
            let url = try await ref.downloadURL()

            try await Firestore.firestore()
                .collection("users")
                .document(uid)
                .setData([
                    "photoURL": url.absoluteString,
                    "updatedAt": FieldValue.serverTimestamp()
                ], merge: true)

            photoURL = url.absoluteString
        } catch {
            print("UPLOAD ERROR:", error.localizedDescription)
        }
    }

    private func loadPhotoURL() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("users")
            .document(uid)
            .getDocument { snapshot, error in
                if let error = error {
                    print("LOAD PHOTO ERROR:", error.localizedDescription)
                    return
                }

                if let url = snapshot?.data()?["photoURL"] as? String {
                    self.photoURL = url
                }
            }
    }

    private func loadFavoritesCount() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("favorites")
            .getDocuments { snap, error in
                if let error = error {
                    print("LOAD FAVORITES COUNT ERROR:", error.localizedDescription)
                    return
                }
                self.favoritesCount = snap?.documents.count ?? 0
            }
    }

    private func loadReservationsCount() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("reservations")
            .whereField("customerId", isEqualTo: uid)
            .getDocuments { snap, error in
                if let error = error {
                    print("LOAD RESERVATIONS COUNT ERROR:", error.localizedDescription)
                    return
                }

                self.reservationsCount = snap?.documents.count ?? 0
            }
    }

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

        if let user = Auth.auth().currentUser {
            email = user.email ?? email
            isEmailVerified = user.isEmailVerified || self.isEmailVerified
            if let displayName = user.displayName, !displayName.isEmpty {
                fullName = displayName
            }

            // Compute membership duration
            if let creationDate = user.metadata.creationDate {
                let components = Calendar.current.dateComponents([.month, .year], from: creationDate, to: Date())
                let months = (components.year ?? 0) * 12 + (components.month ?? 0)
                if months == 0 {
                    memberSince = "Yeni Üye"
                } else if months < 12 {
                    memberSince = "\(months) Ay Üye"
                } else {
                    let y = months / 12
                    memberSince = "\(y) Yıl Üye"
                }
            }

            let uid = user.uid
            Firestore.firestore().collection("users").document(uid).getDocument { snapshot, _ in
                if let data = snapshot?.data() {
                    if let storedName = data["displayName"] as? String, !storedName.isEmpty {
                        self.fullName = storedName
                    }
                    if let storedEmail = data["email"] as? String, !storedEmail.isEmpty {
                        self.email = storedEmail
                    }
                    if let storedEmailVerified = data["isEmailVerified"] as? Bool, storedEmailVerified {
                        self.isEmailVerified = true
                        UserDefaults.standard.set(true, forKey: "user_isEmailVerified")
                    }
                    if let storedPhoneVerified = data["isPhoneVerified"] as? Bool, storedPhoneVerified {
                        self.isPhoneVerified = true
                        UserDefaults.standard.set(true, forKey: "user_isPhoneVerified")
                    }
                    if let storedPhone = data["phoneNumber"] as? String, !storedPhone.isEmpty {
                        self.phone = storedPhone
                    }
                    if let storedPhotoURL = data["photoURL"] as? String {
                        self.photoURL = storedPhotoURL
                    }
                }
            }
        }
    }

    // MARK: - Verification Sheets
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

                        Text("+90 \(phone) numarasına\n6 haneli doğrulama kodu gönderildi.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    if isSendingSMS {
                        HStack(spacing: 10) {
                            ProgressView().tint(Color("PrimaryColor"))
                            Text("SMS gönderiliyor...")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }

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
                                    print("Phone link info: \(error.localizedDescription)")
                                }
                                isPhoneVerified = true
                                showPhoneVerificationSheet = false
                                UserDefaults.standard.set(true, forKey: "user_isPhoneVerified")
                                UserDefaults.standard.set(phone, forKey: "user_phone")
                                if let uid = Auth.auth().currentUser?.uid {
                                    try? await Firestore.firestore().collection("users").document(uid).setData([
                                        "isPhoneVerified": true,
                                        "phoneNumber": phone,
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
                    Button("İptal") { showPhoneVerificationSheet = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

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
                            ProgressView().tint(Color("PrimaryColor"))
                            Text("E-posta gönderiliyor...")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }

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
                    Button("İptal") { showEmailVerificationSheet = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var successToastView: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 20))
            Text(toastMessage.isEmpty ? "İşlem başarılı." : toastMessage)
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

    private func showSuccessMessage(_ text: String) {
        toastMessage = text
        withAnimation {
            showSuccessToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            withAnimation {
                showSuccessToast = false
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
                } else {
                    print("📧 Firebase Auth doğrulama linki gönderildi: \(self.email)")
                }
            }
        }
    }

    // MARK: - Firebase Phone Auth (gerçek SMS gönderir)
    private func sendSMSVerification() {
        let digits = phone.filter(\.isNumber)
        let formattedPhone = "+90" + digits
        print("📱 Firebase Phone Auth SMS gönderiliyor: \(formattedPhone)")
        isSendingSMS = true
        phoneVerificationError = nil

        PhoneAuthProvider.provider().verifyPhoneNumber(formattedPhone, uiDelegate: nil) { verificationID, error in
            DispatchQueue.main.async {
                self.isSendingSMS = false
                if let error = error {
                    self.phoneVerificationError = "SMS gönderilemedi: \(error.localizedDescription)"
                    return
                }
                if let verificationID = verificationID {
                    self.phoneVerificationID = verificationID
                    print("📱 SMS başarıyla gönderildi. Verification ID alındı.")
                }
            }
        }
    }

    // MARK: - Helpers
    private func phoneFormatted(_ raw: String) -> String {
        let d = raw.filter(\.isNumber)
        guard d.count == 10 else { return raw }
        return "\(d.prefix(3)) \(d.dropFirst(3).prefix(3)) \(d.dropFirst(6).prefix(2)) \(d.dropFirst(8).prefix(2))"
    }
}

#Preview {
    NavigationStack {
        ProfilePage()
    }
}
