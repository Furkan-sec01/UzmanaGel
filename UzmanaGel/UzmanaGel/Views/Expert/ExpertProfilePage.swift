//
//  ExpertProfilePage.swift
//  UzmanaGel
//
//  Uzman profil sayfası (normal sayfa). Parça parça bilgi düzenleme.
//

import SwiftUI
import PhotosUI
import UIKit
import CoreLocation
import FirebaseStorage
import FirebaseFirestore
import UniformTypeIdentifiers

// MARK: - Tasarım sabitleri

private enum ProfileDesign {
    static let cardCorner: CGFloat = 16
    static let cardPadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 24
    static let rowSpacing: CGFloat = 12
}

// MARK: - Ana profil sayfası

struct ExpertProfilePage: View {
    let userId: String
    var onRefresh: () async -> Void

    @Environment(\.dismiss) private var dismiss
    private let userRepo = UserRepository()

    @State private var profile: ExpertProfile?
    @State private var isLoading = true
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var isUploadingPhoto = false
    @State private var isSubmittingForApproval = false

    var body: some View {
        Group {
            if isLoading {
                loadingView
            } else if let profile {
                profileContent(profile: profile)
            } else {
                errorView
            }
        }
        .background(Color("BackgroundColor"))
        .navigationTitle("Profilim")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color("PrimaryColor"))
                }
            }
        }
        .task { await loadProfile() }
        .onAppear { Task { await loadProfile() } }
        .onChange(of: photoPickerItem) { _, newItem in
            guard let newItem else { return }
            Task { await handlePhotoSelected(newItem) }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(Color("PrimaryColor"))
            Text("Profiliniz yükleniyor...")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 56))
                .foregroundColor(.secondary.opacity(0.8))
            Text("Profil yüklenemedi")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)
            Text("Lütfen tekrar deneyin.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Button("Tekrar dene") {
                Task { await loadProfile() }
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(Color("PrimaryColor"))
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func profileContent(profile: ExpertProfile) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: ProfileDesign.sectionSpacing) {
                profileHeader(profile: profile)
                completionBlock(profile: profile)
                customerPreviewSection(profile: profile)
                sectionList(profile: profile)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
    }

    /// Müşteriler seni nasıl görüyor — müşteri tarafındaki profil önizlemesi
    private func customerPreviewSection(profile: ExpertProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "eye.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color("PrimaryColor"))
                Text("Müşteriler seni nasıl görüyor")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)

            ExpertProfileCustomerPreview(profile: profile)
        }
    }

    private func profileHeader(profile: ExpertProfile) -> some View {
        VStack(spacing: 16) {
            PhotosPicker(
                selection: $photoPickerItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                ZStack(alignment: .bottomTrailing) {
                    if let urlString = profile.profileImageURL, let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            case .failure:
                                placeholderAvatar
                            @unknown default:
                                placeholderAvatar
                            }
                        }
                        .frame(width: 108, height: 108)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color("PrimaryColor").opacity(0.2), lineWidth: 2)
                        )
                    } else {
                        placeholderAvatar
                    }
                    ZStack {
                        Circle()
                            .fill(Color("BackgroundColor"))
                            .frame(width: 38, height: 38)
                            .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
                        if isUploadingPhoto {
                            ProgressView()
                                .scaleEffect(0.9)
                                .tint(Color("PrimaryColor"))
                        } else {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color("PrimaryColor"))
                        }
                    }
                    .offset(x: -2, y: -2)
                }
            }
            .buttonStyle(.plain)
            .disabled(isUploadingPhoto)

            VStack(spacing: 4) {
                Text(profile.displayName.isEmpty ? "Uzman" : profile.displayName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                if !profile.businessName.isEmpty {
                    Text(profile.businessName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                if profile.profileImageURL == nil && !isUploadingPhoto {
                    Text("Fotoğrafı değiştirmek için dokunun")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color("PrimaryColor").opacity(0.9))
                        .padding(.top, 2)
                }
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(ProfileDesign.cardCorner)
        .overlay(
            RoundedRectangle(cornerRadius: ProfileDesign.cardCorner)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }

    private var placeholderAvatar: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color("PrimaryColor").opacity(0.25), Color("PrimaryColor").opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 108, height: 108)
            Image(systemName: "person.fill")
                .font(.system(size: 44, weight: .light))
                .foregroundColor(Color("PrimaryColor").opacity(0.5))
        }
    }

    private func completionBlock(profile: ExpertProfile) -> some View {
        let pct = profile.profileCompletionPercentage
        let isComplete = profile.canOpenListing
        let statusLower = profile.status.lowercased()
        let isDraft = statusLower == "draft" || statusLower.isEmpty
        let isPending = statusLower == "pending" || statusLower == "beklemede"

        return VStack(spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Profil tamamlanma")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("%\(pct)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                    Text(pct >= 100 ? (isComplete ? "İlan açabilirsiniz" : (isPending ? "Onay bekleniyor" : "Onay için gönderin")) : "İlan açmak için %100 olmalı")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                }
                Spacer()
                ZStack(alignment: .center) {
                    Circle()
                        .stroke(Color(.tertiarySystemFill), lineWidth: 7)
                        .frame(width: 64, height: 64)
                    Circle()
                        .trim(from: 0, to: CGFloat(pct) / 100)
                        .stroke(
                            isComplete ? Color.green : Color("PrimaryColor"),
                            style: StrokeStyle(lineWidth: 7, lineCap: .round)
                        )
                        .frame(width: 64, height: 64)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.4), value: pct)
                    Text("\(pct)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                }
            }
            .padding(ProfileDesign.cardPadding)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(ProfileDesign.cardCorner)
            .overlay(
                RoundedRectangle(cornerRadius: ProfileDesign.cardCorner)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )

            if isComplete {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.green)
                    Text("Profiliniz tamam. İlan açabilirsiniz.")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Color.green.opacity(0.12))
                .cornerRadius(12)
            } else if pct >= 100 && isPending {
                HStack(spacing: 10) {
                    Image(systemName: "clock.badge.checkmark")
                        .font(.system(size: 18))
                        .foregroundColor(.orange)
                    Text("Başvurunuz inceleniyor. Onaylandıktan sonra ilan açabileceksiniz.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Color.orange.opacity(0.12))
                .cornerRadius(12)
            } else if pct >= 100 && isDraft {
                Button {
                    Task { await submitForApproval() }
                } label: {
                    HStack(spacing: 10) {
                        if isSubmittingForApproval {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 16))
                            Text("İncelemeye gönder")
                                .font(.system(size: 15, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color("PrimaryColor"))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .disabled(isSubmittingForApproval)
            }
        }
    }

    private func submitForApproval() async {
        guard !userId.isEmpty else { return }
        isSubmittingForApproval = true
        defer { isSubmittingForApproval = false }
        do {
            try await userRepo.submitExpertForApproval(uid: userId)
            await loadProfile()
            await onRefresh()
        } catch {
            // Hata durumunda kullanıcıya göstermek için state eklenebilir
        }
    }

    private func isBusinessProfessionalFilled(_ profile: ExpertProfile) -> Bool {
        !profile.businessName.isEmpty
            && !profile.serviceCategories.isEmpty
            && !profile.businessType.isEmpty
            && profile.experienceYears >= 0
            && !profile.educationLevel.isEmpty
            && !profile.schoolName.isEmpty
    }

    private func sectionList(profile: ExpertProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Profil bilgileri")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)

            VStack(spacing: ProfileDesign.rowSpacing) {
                sectionRow(
                    icon: "person.text.rectangle.fill",
                    title: "İşletme ve profesyonel bilgiler",
                    subtitle: "Şirket/şahıs, kategori, deneyim, vergi no, sertifika",
                    color: Color("PrimaryColor"),
                    isFilled: isBusinessProfessionalFilled(profile)
                ) {
                    ExpertBusinessProfessionalEditPage(userId: userId, profile: profile, onSave: { Task { await loadProfile(); await onRefresh() } })
                }

                sectionRow(
                    icon: "calendar.badge.clock",
                    title: "Çalışma detayları",
                    subtitle: "Şehir, günler, saatler, fiyat",
                    color: Color("TertiaryColor"),
                    isFilled: !profile.serviceCities.isEmpty && !profile.workingDays.isEmpty && !(profile.workingHoursStart ?? "").isEmpty && profile.minPrice != nil && !(profile.serviceType ?? "").isEmpty
                ) {
                    ExpertWorkingDetailsPage(userId: userId, profile: profile, onSave: { Task { await loadProfile(); await onRefresh() } })
                }

                sectionRow(
                    icon: "creditcard.fill",
                    title: "Banka bilgileri",
                    subtitle: "IBAN, hesap sahibi",
                    color: Color("PrimaryColor"),
                    isFilled: profile.bankName != nil && !(profile.bankName ?? "").isEmpty && profile.iban != nil && !(profile.iban ?? "").isEmpty
                ) {
                    ExpertBankDetailsPage(userId: userId, profile: profile, onSave: { Task { await loadProfile(); await onRefresh() } })
                }

                sectionRow(
                    icon: "mappin.and.ellipse",
                    title: "Adres ve Hakkında",
                    subtitle: "Adres, kısa tanıtım",
                    color: Color("TertiaryColor"),
                    isFilled: !(profile.address ?? "").isEmpty && !(profile.about ?? "").isEmpty
                ) {
                    ExpertAddressAboutPage(userId: userId, profile: profile, onSave: { Task { await loadProfile(); await onRefresh() } })
                }

                sectionRow(
                    icon: "person.text.rectangle.fill",
                    title: "Kimlik doğrulama",
                    subtitle: "Kimlik belgesi ön ve arka yüz",
                    color: Color("PrimaryColor"),
                    isFilled: !(profile.idFrontURL ?? "").isEmpty && !(profile.idBackURL ?? "").isEmpty
                ) {
                    ExpertIdVerificationPage(userId: userId, profile: profile, onSave: { Task { await loadProfile(); await onRefresh() } })
                }

                sectionRow(
                    icon: "photo.on.rectangle.angled",
                    title: "Portföy",
                    subtitle: "Önceki işlerinizden fotoğraflar",
                    color: Color("TertiaryColor"),
                    isFilled: !profile.portfolioImageURLs.isEmpty
                ) {
                    ExpertPortfolioPage(userId: userId, profile: profile, onSave: { Task { await loadProfile(); await onRefresh() } })
                }
            }
        }
    }

    private func sectionRow<D: View>(icon: String, title: String, subtitle: String, color: Color, isFilled: Bool, @ViewBuilder destination: () -> D) -> some View {
        NavigationLink(destination: destination()) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.14))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(color)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary)
                }
                Spacer()
                if isFilled {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.8))
            }
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(ProfileDesign.cardCorner)
            .overlay(
                RoundedRectangle(cornerRadius: ProfileDesign.cardCorner)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func loadProfile() async {
        guard !userId.isEmpty else { isLoading = false; return }
        isLoading = true
        defer { isLoading = false }
        do {
            profile = try await userRepo.fetchExpertProfile(uid: userId)
        } catch {
            profile = nil
        }
    }

    private func handlePhotoSelected(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data),
              let jpeg = image.jpegData(compressionQuality: 0.75) else { return }
        isUploadingPhoto = true
        defer { isUploadingPhoto = false }
        let ref = Storage.storage().reference().child("profile_photos/\(userId)/profile.jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        do {
            _ = try await ref.putDataAsync(jpeg, metadata: metadata)
            let url = try await ref.downloadURL()
            try await userRepo.updateExpertProfile(uid: userId, fields: ["profileImageURL": url.absoluteString])
            await loadProfile()
            await onRefresh()
        } catch {
            // could set error state
        }
    }
}

// MARK: - Müşteri görünümü önizlemesi (uzmanın müşteriye nasıl göründüğü)

struct ExpertProfileCustomerPreview: View {
    let profile: ExpertProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                if let urlString = profile.profileImageURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        if case .success(let img) = phase {
                            img.resizable().scaledToFill()
                        } else {
                            Circle()
                                .fill(Color("PrimaryColor").opacity(0.2))
                                .overlay(Image(systemName: "person.fill").foregroundColor(Color("PrimaryColor").opacity(0.6)))
                        }
                    }
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color("PrimaryColor").opacity(0.2))
                        .frame(width: 56, height: 56)
                        .overlay(Image(systemName: "person.fill").font(.system(size: 24)).foregroundColor(Color("PrimaryColor").opacity(0.6)))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.displayName.isEmpty ? "Uzman" : profile.displayName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    if !profile.businessName.isEmpty {
                        Text(profile.businessName)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    if profile.experienceYears > 0 {
                        Text("\(profile.experienceYears) yıl deneyim")
                            .font(.system(size: 12))
                            .foregroundColor(Color("PrimaryColor"))
                    }
                }
                Spacer()
            }
            if !profile.serviceCategories.isEmpty {
                Text(profile.serviceCategories.prefix(3).joined(separator: " • "))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(ProfileDesign.cardCorner)
        .overlay(
            RoundedRectangle(cornerRadius: ProfileDesign.cardCorner)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - Adres ve Hakkında sayfası

struct ExpertAddressAboutPage: View {
    let userId: String
    let profile: ExpertProfile
    var onSave: () async -> Void

    @Environment(\.dismiss) private var dismiss
    private let userRepo = UserRepository()

    @State private var address = ""
    @State private var about = ""
    @State private var isSaving = false
    @State private var saveError: String?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Adres")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                    TextField("Çalışma adresiniz veya hizmet verdiğiniz bölge", text: $address, axis: .vertical)
                        .lineLimit(3...6)
                        .padding(14)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Hakkında")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                    TextField("Kendinizi ve hizmetlerinizi kısaca tanıtın", text: $about, axis: .vertical)
                        .lineLimit(4...8)
                        .padding(14)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                }
                if let err = saveError {
                    Text(err)
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                }
                Button {
                    Task { await save() }
                } label: {
                    HStack {
                        if isSaving { ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)) }
                        else { Text("Kaydet") }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color("PrimaryColor"))
                    .cornerRadius(14)
                }
                .buttonStyle(.plain)
                .disabled(isSaving)
            }
            .padding(20)
        }
        .background(Color("BackgroundColor"))
        .navigationTitle("Adres ve Hakkında")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            address = profile.address ?? ""
            about = profile.about ?? ""
        }
    }

    private func save() async {
        saveError = nil
        isSaving = true
        defer { isSaving = false }
        let addressTrimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        var fields: [String: Any] = [
            "address": addressTrimmed,
            "about": about.trimmingCharacters(in: .whitespacesAndNewlines)
        ]
        if !addressTrimmed.isEmpty {
            if let geo = await geocodeAddress(addressTrimmed) {
                fields["locationGeo"] = geo
            }
        }
        do {
            try await userRepo.updateExpertProfile(uid: userId, fields: fields)
            await onSave()
            dismiss()
        } catch {
            saveError = error.localizedDescription
        }
    }

    private func geocodeAddress(_ address: String) async -> GeoPoint? {
        await withCheckedContinuation { continuation in
            CLGeocoder().geocodeAddressString(address) { placemarks, _ in
                guard let coord = placemarks?.first?.location?.coordinate else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: GeoPoint(latitude: coord.latitude, longitude: coord.longitude))
            }
        }
    }
}

// MARK: - Kimlik doğrulama (ön ve arka yüz)

struct ExpertIdVerificationPage: View {
    let userId: String
    let profile: ExpertProfile
    var onSave: () async -> Void

    @Environment(\.dismiss) private var dismiss
    private let userRepo = UserRepository()
    private let storageUpload = StorageUploadService()

    @State private var idFrontImage: UIImage?
    @State private var idBackImage: UIImage?
    @State private var idFrontPickerItem: PhotosPickerItem?
    @State private var idBackPickerItem: PhotosPickerItem?
    @State private var showCameraFront = false
    @State private var showCameraBack = false
    @State private var clearedFront = false
    @State private var clearedBack = false
    @State private var isSaving = false
    @State private var saveError: String?

    private var effectiveFrontURL: String? {
        if clearedFront { return nil }
        return profile.idFrontURL
    }
    private var effectiveBackURL: String? {
        if clearedBack { return nil }
        return profile.idBackURL
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Kimlik belgenizin ön ve arka yüzünün net fotoğraflarını yükleyin.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)

                    idCardBlock(
                        title: "Kimlik ön yüz",
                        icon: "creditcard",
                        image: idFrontImage,
                        imageURL: effectiveFrontURL,
                        pickerItem: $idFrontPickerItem,
                        onRemove: { idFrontImage = nil; idFrontPickerItem = nil; clearedFront = true },
                        onCamera: { showCameraFront = true }
                    )

                    idCardBlock(
                        title: "Kimlik arka yüz",
                        icon: "creditcard.fill",
                        image: idBackImage,
                        imageURL: effectiveBackURL,
                        pickerItem: $idBackPickerItem,
                        onRemove: { idBackImage = nil; idBackPickerItem = nil; clearedBack = true },
                        onCamera: { showCameraBack = true }
                    )

                    if let err = saveError {
                        Text(err)
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                            .padding(.horizontal, 4)
                    }
                    Spacer().frame(height: 100)
                }
                .padding(20)
            }
            .background(Color("BackgroundColor"))

            Button {
                Task { await save() }
            } label: {
                HStack(spacing: 8) {
                    if isSaving {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                        Text("Kaydet")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(canSave ? Color("PrimaryColor") : Color.gray.opacity(0.6))
                .cornerRadius(14)
            }
            .buttonStyle(.plain)
            .disabled(!canSave || isSaving)
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .navigationTitle("Kimlik doğrulama")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: idFrontPickerItem) { _, item in
            Task {
                guard let item else { return }
                if let data = try? await item.loadTransferable(type: Data.self), let img = UIImage(data: data) {
                    await MainActor.run { idFrontImage = img }
                }
            }
        }
        .onChange(of: idBackPickerItem) { _, item in
            Task {
                guard let item else { return }
                if let data = try? await item.loadTransferable(type: Data.self), let img = UIImage(data: data) {
                    await MainActor.run { idBackImage = img }
                }
            }
        }
        .fullScreenCover(isPresented: $showCameraFront) {
            CameraImagePicker(
                onImagePicked: { idFrontImage = $0; showCameraFront = false },
                onCancel: { showCameraFront = false }
            )
        }
        .fullScreenCover(isPresented: $showCameraBack) {
            CameraImagePicker(
                onImagePicked: { idBackImage = $0; showCameraBack = false },
                onCancel: { showCameraBack = false }
            )
        }
    }

    private var canSave: Bool {
        let hasFront = idFrontImage != nil || (effectiveFrontURL != nil && !effectiveFrontURL!.isEmpty)
        let hasBack = idBackImage != nil || (effectiveBackURL != nil && !effectiveBackURL!.isEmpty)
        return hasFront && hasBack
    }

    private func idCardBlock(
        title: String,
        icon: String,
        image: UIImage?,
        imageURL: String?,
        pickerItem: Binding<PhotosPickerItem?>,
        onRemove: @escaping () -> Void,
        onCamera: @escaping () -> Void
    ) -> some View {
        let hasImage = image != nil || (imageURL != nil && !imageURL!.isEmpty)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(Color("PrimaryColor"))
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                if hasImage {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.green)
                }
            }

            if let img = image {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    Button(action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 3)
                    }
                    .padding(8)
                }
            } else if let urlString = imageURL, !urlString.isEmpty, let url = URL(string: urlString) {
                ZStack(alignment: .topTrailing) {
                    AsyncImage(url: url) { phase in
                        if let img = phase.image {
                            img.resizable().scaledToFit()
                        } else {
                            Rectangle()
                                .fill(Color(.tertiarySystemBackground))
                                .overlay(ProgressView())
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    Button(action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 3)
                    }
                    .padding(8)
                }
            } else {
                HStack(spacing: 12) {
                    PhotosPicker(selection: pickerItem, matching: .images) {
                        idCardButtonLabel(icon: "photo.on.rectangle.angled", title: "Galeriden seç")
                    }
                    Button(action: onCamera) {
                        idCardButtonLabel(icon: "camera.fill", title: "Kamera ile çek")
                    }
                    .buttonStyle(.plain)
                }
            }

            if hasImage {
                HStack(spacing: 12) {
                    PhotosPicker(selection: pickerItem, matching: .images) {
                        HStack(spacing: 6) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 14))
                            Text("Galeriden değiştir")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(Color("PrimaryColor"))
                    }
                    Button(action: onCamera) {
                        HStack(spacing: 6) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14))
                            Text("Yeniden çek")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(Color("PrimaryColor"))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(hasImage ? Color.green.opacity(0.3) : Color.black.opacity(0.06), lineWidth: 1)
        )
    }

    private func idCardButtonLabel(icon: String, title: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color("PrimaryColor"))
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color("PrimaryColor"))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .background(Color("PrimaryColor").opacity(0.08))
        .cornerRadius(12)
    }

    private func save() async {
        saveError = nil
        guard canSave else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            var frontURL: String? = clearedFront ? nil : profile.idFrontURL
            var backURL: String? = clearedBack ? nil : profile.idBackURL
            if let img = idFrontImage, let data = img.jpegData(compressionQuality: 0.85) {
                frontURL = try await storageUpload.uploadVerificationDocument(data: data, type: .idCardFront, fileExtension: "jpg", uid: userId)
            }
            if let img = idBackImage, let data = img.jpegData(compressionQuality: 0.85) {
                backURL = try await storageUpload.uploadVerificationDocument(data: data, type: .idCardBack, fileExtension: "jpg", uid: userId)
            }
            try await userRepo.updateExpertProfile(uid: userId, fields: [
                "idFrontURL": frontURL ?? "",
                "idBackURL": backURL ?? ""
            ])
            await onSave()
            dismiss()
        } catch {
            saveError = error.localizedDescription
        }
    }
}

// MARK: - Portföy sayfası (önceki işlerden fotoğraflar)

struct ExpertPortfolioPage: View {
    let userId: String
    let profile: ExpertProfile
    var onSave: () async -> Void

    @Environment(\.dismiss) private var dismiss
    private let userRepo = UserRepository()
    private let storageUpload = StorageUploadService()

    @State private var portfolioURLs: [String] = []
    @State private var photoPickerItems: [PhotosPickerItem] = []
    @State private var isSaving = false
    @State private var isUploading = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Önceki işlerinizden fotoğraflar ekleyin. Müşteriler bu görselleri görebilir.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)

                if !portfolioURLs.isEmpty {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                        ForEach(portfolioURLs.indices, id: \.self) { index in
                            ZStack(alignment: .topTrailing) {
                                if let url = URL(string: portfolioURLs[index]) {
                                    AsyncImage(url: url) { phase in
                                        if case .success(let img) = phase {
                                            img.resizable().scaledToFill()
                                        } else {
                                            Rectangle().fill(Color(.tertiarySystemFill))
                                        }
                                    }
                                    .frame(height: 120)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                Button {
                                    portfolioURLs.remove(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundStyle(.white, .black.opacity(0.6))
                                }
                                .padding(6)
                            }
                        }
                    }
                }

                PhotosPicker(
                    selection: $photoPickerItems,
                    maxSelectionCount: 20 - portfolioURLs.count,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    HStack(spacing: 10) {
                        if isUploading {
                            ProgressView()
                                .scaleEffect(0.9)
                                .tint(Color("PrimaryColor"))
                        } else {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(Color("PrimaryColor"))
                        }
                        Text(portfolioURLs.isEmpty ? "Fotoğraf ekle" : "Daha fazla ekle")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color("PrimaryColor"))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color("PrimaryColor").opacity(0.1))
                    .cornerRadius(14)
                }
                .disabled(isUploading || portfolioURLs.count >= 20)
                .onChange(of: photoPickerItems) { _, newItems in
                    Task { await processNewPhotos(newItems) }
                }

                if let err = errorMessage {
                    Text(err)
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                }

                Button {
                    Task { await savePortfolio() }
                } label: {
                    HStack {
                        if isSaving { ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)) }
                        else { Text("Kaydet") }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color("PrimaryColor"))
                    .cornerRadius(14)
                }
                .buttonStyle(.plain)
                .disabled(isSaving)
            }
            .padding(20)
        }
        .background(Color("BackgroundColor"))
        .navigationTitle("Portföy")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            portfolioURLs = profile.portfolioImageURLs
        }
    }

    private func processNewPhotos(_ items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }
        isUploading = true
        errorMessage = nil
        defer { isUploading = false }
        var newURLs: [String] = []
        for item in items {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else { continue }
            do {
                let url = try await storageUpload.uploadPortfolio(image: image, uid: userId)
                newURLs.append(url)
            } catch {
                errorMessage = "Yükleme hatası: \(error.localizedDescription)"
                return
            }
        }
        portfolioURLs.append(contentsOf: newURLs)
        photoPickerItems = []
    }

    private func savePortfolio() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            try await userRepo.updateExpertProfile(uid: userId, fields: ["portfolioImageURLs": portfolioURLs])
            await onSave()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - İşletme ve profesyonel bilgiler (düzenlenebilir)

struct ExpertBusinessProfessionalEditPage: View {
    let userId: String
    let profile: ExpertProfile
    var onSave: () async -> Void

    @Environment(\.dismiss) private var dismiss
    private let userRepo = UserRepository()
    private let storageUpload = StorageUploadService()

    @State private var businessName = ""
    @State private var businessTypeRaw = "sahis"
    @State private var selectedCategories: Set<String> = []
    @State private var taxNumber = ""
    @State private var experienceYearsText = ""
    @State private var educationLevelRaw = EducationLevel.bachelor.rawValue
    @State private var schoolName = ""
    @State private var selectedExpertiseAreas: Set<String> = []
    @State private var categorySearchText = ""
    @State private var isCategoryExpanded = false
    @State private var certificatePickerItems: [PhotosPickerItem] = []
    @State private var certificateImages: [UIImage] = []
    @State private var certificatePDFs: [Data] = []
    @State private var showPDFImporter = false
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var showSuccess = false

    private var existingCertificateURLs: [String] { profile.certificateURLs }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    businessSection
                    professionalSection
                    certificateSection
                    if let err = saveError {
                        Text(err)
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                            .padding(.horizontal, 4)
                    }
                    Spacer().frame(height: 100)
                }
                .padding(20)
            }
            .background(Color("BackgroundColor"))
            saveButton
        }
        .navigationTitle("İşletme ve profesyonel bilgiler")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { bindFromProfile() }
        .onChange(of: certificatePickerItems) { _, _ in loadCertificateImages() }
        .fileImporter(isPresented: $showPDFImporter, allowedContentTypes: [.pdf], allowsMultipleSelection: false) { result in
            guard case .success(let urls) = result, let url = urls.first, url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            if let data = try? Data(contentsOf: url) { certificatePDFs.append(data) }
        }
        .overlay { if showSuccess { successToast } }
    }

    private var businessSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("İşletme bilgileri")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            VStack(spacing: 12) {
                fieldRow(icon: "building.2", label: "İşletme adı") {
                    TextField("İşletme adı", text: $businessName)
                        .textInputAutocapitalization(.words)
                }
                businessTypeRow
                categoryPickerRow
                fieldRow(icon: "number", label: "Vergi numarası (opsiyonel)") {
                    TextField("Vergi numarası", text: $taxNumber)
                        .keyboardType(.numberPad)
                }
            }
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(ProfileDesign.cardCorner)
        }
    }

    private var businessTypeRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("İşletme türü")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
            HStack(spacing: 12) {
                ForEach([("sahis", "Şahıs", "person.fill"), ("sirket", "Şirket", "building.fill")], id: \.0) { raw, title, icon in
                    Button {
                        businessTypeRaw = raw
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: icon)
                                .font(.system(size: 14))
                            Text(title)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(businessTypeRaw == raw ? .white : Color("PrimaryColor"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(businessTypeRaw == raw ? Color("PrimaryColor") : Color(.tertiarySystemBackground))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var categoryPickerRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isCategoryExpanded.toggle()
                    if !isCategoryExpanded { categorySearchText = "" }
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "chevron.down.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color("PrimaryColor"))
                        .rotationEffect(.degrees(isCategoryExpanded ? 180 : 0))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Hizmet kategorileri")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        Text(selectedCategories.isEmpty ? "Kategori seçin" : "\(selectedCategories.count) kategorisi seçildi")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if !selectedCategories.isEmpty {
                        Text("\(selectedCategories.count)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color("PrimaryColor"))
                            .clipShape(Capsule())
                    }
                }
                .padding(14)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(14)
            }
            .buttonStyle(.plain)
            if isCategoryExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    TextField("Kategori ara...", text: $categorySearchText)
                        .font(.system(size: 14))
                        .padding(12)
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(10)
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 6) {
                            ForEach(filteredCategories) { cat in
                                Button {
                                    if selectedCategories.contains(cat.name) {
                                        selectedCategories.remove(cat.name)
                                    } else {
                                        selectedCategories.insert(cat.name)
                                    }
                                } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: cat.icon)
                                            .font(.system(size: 16))
                                            .foregroundColor(selectedCategories.contains(cat.name) ? .white : Color("PrimaryColor"))
                                            .frame(width: 28)
                                        Text(cat.name)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(selectedCategories.contains(cat.name) ? .white : .primary)
                                        Spacer()
                                        Image(systemName: selectedCategories.contains(cat.name) ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 20))
                                            .foregroundColor(selectedCategories.contains(cat.name) ? .white : .secondary)
                                    }
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 12)
                                    .background(selectedCategories.contains(cat.name) ? Color("PrimaryColor") : Color(.tertiarySystemBackground))
                                    .cornerRadius(10)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .frame(maxHeight: 220)
                }
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(14)
                .padding(.top, 8)
            }
        }
    }

    private var filteredCategories: [ServiceCategory] {
        let q = categorySearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return ServiceCategory.allCategories }
        return ServiceCategory.allCategories.filter { $0.name.lowercased().contains(q) }
    }

    private var professionalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Profesyonel bilgiler")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            VStack(spacing: 12) {
                fieldRow(icon: "calendar", label: "Deneyim yılı") {
                    TextField("Örn: 5", text: $experienceYearsText)
                        .keyboardType(.numberPad)
                }
                educationRow
                fieldRow(icon: "building.columns", label: "Okul / kurum adı") {
                    TextField("Okul veya kurum adı", text: $schoolName)
                        .textInputAutocapitalization(.words)
                }
                expertiseRow
            }
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(ProfileDesign.cardCorner)
        }
    }

    private var educationRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Eğitim düzeyi")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(EducationLevel.allCases, id: \.rawValue) { level in
                        Button {
                            educationLevelRaw = level.rawValue
                        } label: {
                            Text(level.rawValue)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(educationLevelRaw == level.rawValue ? .white : .primary)
                                .padding(.horizontal, 14)
                                .frame(height: 36)
                                .background(educationLevelRaw == level.rawValue ? Color("PrimaryColor") : Color(.tertiarySystemBackground))
                                .cornerRadius(18)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var expertiseRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Uzmanlık alanları")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
            if selectedCategories.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 13))
                        .foregroundColor(.orange)
                    Text("Önce hizmet kategorisi seçin")
                        .font(.system(size: 13))
                        .foregroundColor(.orange)
                }
                .padding(.vertical, 8)
            } else {
                let areas = ExpertiseArea.areas(for: selectedCategories)
                FlowLayout(spacing: 6) {
                    ForEach(areas) { area in
                        Button {
                            if selectedExpertiseAreas.contains(area.name) {
                                selectedExpertiseAreas.remove(area.name)
                            } else {
                                selectedExpertiseAreas.insert(area.name)
                            }
                        } label: {
                            Text(area.name)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(selectedExpertiseAreas.contains(area.name) ? .white : .primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selectedExpertiseAreas.contains(area.name) ? Color("PrimaryColor") : Color(.tertiarySystemBackground))
                                .cornerRadius(16)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var certificateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sertifikalar (opsiyonel)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            if !existingCertificateURLs.isEmpty {
                Text("\(existingCertificateURLs.count) sertifika kayıtlı")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            if !certificateImages.isEmpty || !certificatePDFs.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(certificateImages.indices, id: \.self) { i in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: certificateImages[i])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                Button {
                                    certificateImages.remove(at: i)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white)
                                        .shadow(radius: 2)
                                }
                                .offset(x: 4, y: -4)
                            }
                        }
                        ForEach(certificatePDFs.indices, id: \.self) { i in
                            ZStack(alignment: .topTrailing) {
                                VStack(spacing: 4) {
                                    Image(systemName: "doc.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color("PrimaryColor"))
                                    Text("PDF \(i + 1)")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                .frame(width: 80, height: 80)
                                .background(Color("PrimaryColor").opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                Button {
                                    certificatePDFs.remove(at: i)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white)
                                        .shadow(radius: 2)
                                }
                                .offset(x: 4, y: -4)
                            }
                        }
                    }
                }
            }
            HStack(spacing: 10) {
                PhotosPicker(selection: $certificatePickerItems, maxSelectionCount: 10, matching: .images) {
                    labelWithIcon(icon: "photo.badge.plus", title: "Fotoğraf ekle")
                }
                Button {
                    showPDFImporter = true
                } label: {
                    labelWithIcon(icon: "doc.badge.plus", title: "PDF ekle")
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(ProfileDesign.cardCorner)
    }

    private func labelWithIcon(icon: String, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
            Text(title)
                .font(.system(size: 14, weight: .semibold))
        }
        .foregroundColor(Color("PrimaryColor"))
        .frame(maxWidth: .infinity)
        .frame(height: 46)
        .background(Color("PrimaryColor").opacity(0.08))
        .cornerRadius(12)
    }

    private func fieldRow<Content: View>(icon: String, label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(Color("PrimaryColor"))
                    .frame(width: 24)
                content()
                    .font(.system(size: 15))
            }
            .padding(12)
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(12)
        }
    }

    private var saveButton: some View {
        Button {
            Task { await save() }
        } label: {
            HStack(spacing: 8) {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                    Text("Kaydet")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(canSave ? Color("PrimaryColor") : Color.gray)
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
        .disabled(!canSave || isSaving)
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }

    private var canSave: Bool {
        !businessName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !selectedCategories.isEmpty
            && !businessTypeRaw.isEmpty
            && (Int(experienceYearsText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0) >= 0
            && !educationLevelRaw.isEmpty
            && !schoolName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var successToast: some View {
        Text("Kaydedildi")
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.green)
            .cornerRadius(12)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { showSuccess = false }
            }
    }

    private func bindFromProfile() {
        businessName = profile.businessName
        businessTypeRaw = profile.businessType.isEmpty ? "sahis" : profile.businessType
        selectedCategories = Set(profile.serviceCategories)
        taxNumber = profile.taxNumber ?? ""
        experienceYearsText = profile.experienceYears > 0 ? "\(profile.experienceYears)" : ""
        educationLevelRaw = profile.educationLevel.isEmpty ? EducationLevel.bachelor.rawValue : profile.educationLevel
        schoolName = profile.schoolName
        selectedExpertiseAreas = Set(profile.expertiseAreas)
    }

    private func loadCertificateImages() {
        Task {
            var images: [UIImage] = []
            for item in certificatePickerItems {
                if let data = try? await item.loadTransferable(type: Data.self), let img = UIImage(data: data) {
                    images.append(img)
                }
            }
            await MainActor.run { certificateImages = images }
        }
    }

    private func save() async {
        saveError = nil
        guard canSave else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            var newURLs: [String] = []
            for img in certificateImages {
                let url = try await storageUpload.uploadCertificate(image: img, quality: 0.85, uid: userId)
                newURLs.append(url)
            }
            for pdfData in certificatePDFs {
                let url = try await storageUpload.uploadCertificate(data: pdfData, fileExtension: "pdf", uid: userId)
                newURLs.append(url)
            }
            let allCertURLs = existingCertificateURLs + newURLs
            let years = Int(experienceYearsText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
            var fields: [String: Any] = [
                "businessName": businessName.trimmingCharacters(in: .whitespacesAndNewlines),
                "businessType": businessTypeRaw,
                "serviceCategories": Array(selectedCategories),
                "taxNumber": taxNumber.trimmingCharacters(in: .whitespacesAndNewlines),
                "experienceYears": years,
                "educationLevel": educationLevelRaw,
                "schoolName": schoolName.trimmingCharacters(in: .whitespacesAndNewlines),
                "expertiseAreas": Array(selectedExpertiseAreas),
                "certificateURLs": allCertURLs
            ]
            try await userRepo.updateExpertProfile(uid: userId, fields: fields)
            showSuccess = true
            await onSave()
            dismiss()
        } catch {
            saveError = error.localizedDescription
        }
    }
}

// MARK: - Kişisel bilgiler (sadece görüntüleme)

struct ExpertPersonalInfoView: View {
    let profile: ExpertProfile

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                sectionBlock(title: "İletişim", icon: "person.crop.circle") {
                    infoRow(icon: "person.fill", "Ad Soyad", profile.displayName)
                    infoRow(icon: "envelope.fill", "E-posta", profile.email)
                    infoRow(icon: "phone.fill", "Telefon", formatPhone(profile.phoneNumber))
                }

                sectionBlock(title: "İşletme", icon: "building.2") {
                    infoRow(icon: "briefcase.fill", "İşletme Adı", profile.businessName)
                    infoRow(icon: "doc.text", "İşletme Türü", profile.businessType == "sahis" ? "Şahıs" : (profile.businessType == "sirket" ? "Şirket" : (profile.businessType.isEmpty ? "—" : profile.businessType)))
                    if let t = profile.taxNumber, !t.isEmpty {
                        infoRow(icon: "number", "Vergi No", t)
                    }
                }

                sectionBlock(title: "Eğitim & Deneyim", icon: "graduationcap") {
                    infoRow(icon: "calendar", "Deneyim", "\(profile.experienceYears) yıl")
                    infoRow(icon: "book.fill", "Eğitim", profile.educationLevel.isEmpty ? "—" : profile.educationLevel)
                    infoRow(icon: "building.columns", "Okul / Kurum", profile.schoolName.isEmpty ? "—" : profile.schoolName)
                }

                if !profile.serviceCategories.isEmpty {
                    sectionBlock(title: "Hizmet kategorileri", icon: "folder.fill") {
                        FlowLayout(spacing: 8) {
                            ForEach(profile.serviceCategories, id: \.self) { cat in
                                Text(cat)
                                    .font(.system(size: 13, weight: .medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color("PrimaryColor").opacity(0.12))
                                    .foregroundColor(Color("PrimaryColor"))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Color("BackgroundColor"))
        .navigationTitle("Kişisel bilgiler")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionBlock<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color("PrimaryColor"))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)
            VStack(spacing: 0) {
                content()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(ProfileDesign.cardCorner)
            .overlay(
                RoundedRectangle(cornerRadius: ProfileDesign.cardCorner)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
        }
    }

    private func infoRow(icon: String, _ title: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color("PrimaryColor").opacity(0.8))
                .frame(width: 22, alignment: .center)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                Text(value.isEmpty ? "—" : value)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
            }
            Spacer()
        }
        .padding(.vertical, 10)
    }

    private func formatPhone(_ raw: String) -> String {
        let d = raw.filter(\.isNumber)
        guard d.count >= 10 else { return raw }
        return "+90 \(d.prefix(3)) \(d.dropFirst(3).prefix(3)) \(d.suffix(4))"
    }
}

// MARK: - Çalışma detayları sayfası (günler + saatler + şehir + fiyat + tür)

struct ExpertWorkingDetailsPage: View {
    let userId: String
    let profile: ExpertProfile
    var onSave: () async -> Void

    @Environment(\.dismiss) private var dismiss
    private let userRepo = UserRepository()

    @State private var serviceCities: Set<String> = []
    @State private var workingDays: Set<String> = []
    @State private var workingHoursStart = ""
    @State private var workingHoursEnd = ""
    @State private var minPriceText = ""
    @State private var maxPriceText = ""
    @State private var serviceType = ""
    @State private var isSaving = false
    @State private var showCityPicker = false
    @State private var saveError: String?
    @State private var showSuccess = false

    private let dayOptions: [(id: String, title: String)] = [
        ("1", "Pzt"), ("2", "Sal"), ("3", "Çar"), ("4", "Per"),
        ("5", "Cum"), ("6", "Cmt"), ("7", "Paz")
    ]
    private let serviceTypeOptions = [(id: "hourly", title: "Saatlik"), (id: "project", title: "Proje bazlı")]

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    regionSection
                    workingScheduleSection
                    priceSection
                    serviceTypeSection
                    if let err = saveError {
                        errorBanner(err)
                    }
                    Spacer().frame(height: 100)
                }
                .padding(20)
            }
            .background(Color("BackgroundColor"))

            saveButton
        }
        .navigationTitle("Çalışma detayları")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { bindFromProfile() }
        .sheet(isPresented: $showCityPicker) {
            ExpertCityPickerSheet(selectedCities: $serviceCities)
        }
        .overlay {
            if showSuccess {
                successToast
            }
        }
    }

    private var regionSection: some View {
        workingSection(title: "Hizmet bölgesi", icon: "mappin.circle.fill") {
            Button {
                showCityPicker = true
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color("PrimaryColor"))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(serviceCities.isEmpty ? "Şehir seçin" : "\(serviceCities.count) şehir seçildi")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(serviceCities.isEmpty ? .secondary : .primary)
                        if !serviceCities.isEmpty {
                            Text(Array(serviceCities).sorted().prefix(3).joined(separator: ", ") + (serviceCities.count > 3 ? "..." : ""))
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
    }

    private var workingScheduleSection: some View {
        workingSection(title: "Çalışma programı", icon: "calendar") {
            VStack(alignment: .leading, spacing: 14) {
                Text("Çalıştığınız günler")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                FlowLayout(spacing: 10) {
                    ForEach(dayOptions, id: \.id) { opt in
                        Button {
                            if workingDays.contains(opt.id) {
                                var next = workingDays
                                next.remove(opt.id)
                                workingDays = next
                            } else {
                                var next = workingDays
                                next.insert(opt.id)
                                workingDays = next
                            }
                        } label: {
                            Text(opt.title)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(workingDays.contains(opt.id) ? .white : .primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(workingDays.contains(opt.id) ? Color("PrimaryColor") : Color(.tertiarySystemBackground))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                HStack(spacing: 12) {
                    floatingLabelField(label: "Başlangıç", placeholder: "09:00", text: $workingHoursStart)
                    floatingLabelField(label: "Bitiş", placeholder: "18:00", text: $workingHoursEnd)
                }
            }
        }
    }

    private var priceSection: some View {
        workingSection(title: "Ücret aralığı", icon: "turkishlirasign.circle.fill") {
                HStack(spacing: 12) {
                    floatingLabelField(label: "Min. (₺)", placeholder: "0", text: $minPriceText, keyboard: .numberPad)
                    floatingLabelField(label: "Maks. (₺)", placeholder: "0", text: $maxPriceText, keyboard: .numberPad)
                }
        }
    }

    private var serviceTypeSection: some View {
        workingSection(title: "Hizmet türü", icon: "clock.fill") {
            HStack(spacing: 12) {
                ForEach(serviceTypeOptions, id: \.id) { opt in
                    Button {
                        serviceType = opt.id
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: opt.id == "hourly" ? "clock" : "square.stack.3d.up")
                                .font(.system(size: 16, weight: .medium))
                            Text(opt.title)
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(serviceType == opt.id ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(serviceType == opt.id ? Color("PrimaryColor") : Color(.tertiarySystemBackground))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func workingSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color("PrimaryColor"))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(ProfileDesign.cardCorner)
        .overlay(
            RoundedRectangle(cornerRadius: ProfileDesign.cardCorner)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }

    private func floatingLabelField(label: String, placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .numbersAndPunctuation) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .font(.system(size: 16, weight: .medium))
                .padding(14)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(12)
        }
        .frame(maxWidth: .infinity)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.red)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }

    private var saveButton: some View {
        Button {
            Task { await save() }
        } label: {
            HStack(spacing: 8) {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                    Text("Kaydet")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(isSaving ? Color("PrimaryColor").opacity(0.7) : Color("PrimaryColor"))
            .cornerRadius(16)
            .shadow(color: Color("PrimaryColor").opacity(0.35), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(isSaving)
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .padding(.top, 12)
        .background(
            LinearGradient(
                colors: [Color("BackgroundColor").opacity(0), Color("BackgroundColor")],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var successToast: some View {
        VStack {
            Spacer()
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                Text("Kaydedildi")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.green)
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
            .padding(.bottom, 120)
        }
        .allowsHitTesting(false)
    }

    private func bindFromProfile() {
        serviceCities = Set(profile.serviceCities)
        workingDays = Set(profile.workingDays)
        workingHoursStart = profile.workingHoursStart ?? ""
        workingHoursEnd = profile.workingHoursEnd ?? ""
        minPriceText = profile.minPrice.map { "\($0)" } ?? ""
        maxPriceText = profile.maxPrice.map { "\($0)" } ?? ""
        serviceType = profile.serviceType ?? ""
    }

    private func save() async {
        saveError = nil
        isSaving = true
        defer { isSaving = false }
        var fields: [String: Any] = [
            "serviceCities": Array(serviceCities),
            "workingDays": Array(workingDays),
            "workingHoursStart": workingHoursStart.trimmingCharacters(in: .whitespacesAndNewlines),
            "workingHoursEnd": workingHoursEnd.trimmingCharacters(in: .whitespacesAndNewlines),
            "serviceType": serviceType.trimmingCharacters(in: .whitespacesAndNewlines)
        ]
        if let minP = Int(minPriceText.trimmingCharacters(in: .whitespacesAndNewlines)), minP >= 0 { fields["minPrice"] = minP }
        if let maxP = Int(maxPriceText.trimmingCharacters(in: .whitespacesAndNewlines)), maxP >= 0 { fields["maxPrice"] = maxP }
        do {
            try await userRepo.updateExpertProfile(uid: userId, fields: fields)
            await MainActor.run {
                showSuccess = true
            }
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            await onSave()
            await MainActor.run {
                dismiss()
            }
        } catch {
            saveError = error.localizedDescription
        }
    }
}

// MARK: - Banka bilgileri sayfası

struct ExpertBankDetailsPage: View {
    let userId: String
    let profile: ExpertProfile
    var onSave: () async -> Void

    @Environment(\.dismiss) private var dismiss
    private let userRepo = UserRepository()

    @State private var bankName = ""
    @State private var iban = ""
    @State private var accountHolderName = ""
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var showSuccess = false

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    securityNoteCard
                    formCard
                    if let err = saveError {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(err)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.red)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                    }
                    Spacer().frame(height: 100)
                }
                .padding(20)
            }
            .background(Color("BackgroundColor"))

            saveButton
        }
        .navigationTitle("Banka bilgileri")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            bankName = profile.bankName ?? ""
            iban = profile.iban ?? ""
            accountHolderName = profile.accountHolderName ?? ""
        }
        .overlay {
            if showSuccess {
                bankSuccessToast
            }
        }
    }

    private var securityNoteCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Güvenli saklama")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                Text("Banka bilgileriniz şifrelenir ve yalnızca ödeme işlemleri için kullanılır.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(ProfileDesign.cardCorner)
        .overlay(
            RoundedRectangle(cornerRadius: ProfileDesign.cardCorner)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            bankField(label: "Banka adı", placeholder: "Örn: Ziraat Bankası", text: $bankName)
            bankField(label: "IBAN", placeholder: "TR00 0000 0000 0000 0000 0000 00", text: $iban, keyboardType: .asciiCapable)
            bankField(label: "Hesap sahibi adı", placeholder: "Ad Soyad", text: $accountHolderName)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(ProfileDesign.cardCorner)
        .overlay(
            RoundedRectangle(cornerRadius: ProfileDesign.cardCorner)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }

    private func bankField(label: String, placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
            TextField(placeholder, text: text)
                .font(.system(size: 16, weight: .medium))
                .keyboardType(keyboardType)
                .autocorrectionDisabled(keyboardType == .asciiCapable)
                .padding(14)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(12)
        }
    }

    private var saveButton: some View {
        Button {
            Task { await save() }
        } label: {
            HStack(spacing: 8) {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                    Text("Kaydet")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(isSaving ? Color("PrimaryColor").opacity(0.7) : Color("PrimaryColor"))
            .cornerRadius(16)
            .shadow(color: Color("PrimaryColor").opacity(0.35), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(isSaving)
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .padding(.top, 12)
        .background(
            LinearGradient(
                colors: [Color("BackgroundColor").opacity(0), Color("BackgroundColor")],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var bankSuccessToast: some View {
        VStack {
            Spacer()
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                Text("Kaydedildi")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.green)
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
            .padding(.bottom, 120)
        }
        .allowsHitTesting(false)
    }

    private func save() async {
        saveError = nil
        isSaving = true
        defer { isSaving = false }
        let fields: [String: Any] = [
            "bankName": bankName.trimmingCharacters(in: .whitespacesAndNewlines),
            "iban": iban.trimmingCharacters(in: .whitespacesAndNewlines),
            "accountHolderName": accountHolderName.trimmingCharacters(in: .whitespacesAndNewlines)
        ]
        do {
            try await userRepo.updateExpertProfile(uid: userId, fields: fields)
            await MainActor.run { showSuccess = true }
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            await onSave()
            await MainActor.run { dismiss() }
        } catch {
            saveError = error.localizedDescription
        }
    }
}
