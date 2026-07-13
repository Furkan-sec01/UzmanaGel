//
//  ExpertHomepage.swift
//  UzmanaGel
//
//  Uzman girişi sonrası ana ekran.
//

import SwiftUI
import PhotosUI
import UIKit

struct ExpertHomepage: View {

    @EnvironmentObject var session: SessionViewModel

    @State private var profile: ExpertProfile?
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var showMenu = false
    @State private var expertProfilePath: [String] = []
    @State private var showCreateListingSheet = false
    @State private var listingCount = 0

    private let userRepo = UserRepository()
    private let serviceRepo = ServiceRepository()

    var body: some View {
        NavigationStack(path: $expertProfilePath) {
            ZStack(alignment: .bottomTrailing) {
                Color("BackgroundColor")
                    .ignoresSafeArea()

                if isLoading {
                    loadingView
                } else if let profile {
                    mainContent(profile: profile)
                } else {
                    errorView
                }

                if let profile, profile.canOpenListing {
                    createListingFAB
                }
            }
            .toolbarBackground(Color("PrimaryColor"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showMenu = true } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
            }
            .sheet(isPresented: $showMenu) {
                expertMenuSheet
            }
            .sheet(isPresented: $showCreateListingSheet) {
                if let uid = session.userId, let profile = profile {
                    ExpertCreateListingView(
                        uid: uid,
                        profile: profile,
                        onPublished: { showCreateListingSheet = false; Task { await loadProfile() } },
                        onDismiss: { showCreateListingSheet = false }
                    )
                }
            }
            .navigationDestination(for: String.self) { value in
                if value == "profile", let uid = session.userId {
                    ExpertProfilePage(userId: uid, onRefresh: { Task { await loadProfile() } })
                } else if value == "portfolio", let uid = session.userId, let profile {
                    ExpertPortfolioPage(userId: uid, profile: profile, onSave: { Task { await loadProfile() } })
                } else if value == "listings", let uid = session.userId, let profile {
                    ExpertListingsPage(uid: uid, profile: profile, onRefresh: { Task { await loadProfile() } })
                }
            }
            .task {
                await loadProfile()
            }
            .refreshable {
                await loadProfile()
            }
        }
    }

    private var createListingFAB: some View {
        Button {
            showCreateListingSheet = true
        } label: {
            ZStack {
                Circle()
                    .fill(Color("PrimaryColor"))
                    .frame(width: 58, height: 58)
                    .shadow(color: Color("PrimaryColor").opacity(0.4), radius: 10, x: 0, y: 4)
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 58, height: 58)
                    .blur(radius: 1)
                    .offset(y: -1)
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
        .padding(.trailing, 20)
        .padding(.bottom, 28)
    }
}

// MARK: - Design tokens

private enum ExpertHomeDesign {
    static let cardRadius: CGFloat = 18
    static let cardPadding: CGFloat = 18
    static let sectionSpacing: CGFloat = 24
    static let rowSpacing: CGFloat = 12
    static let iconSize: CGFloat = 44
    static let shadowRadius: CGFloat = 8
    static let shadowY: CGFloat = 4
}

// MARK: - Content

private extension ExpertHomepage {

    func mainContent(profile: ExpertProfile) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: ExpertHomeDesign.sectionSpacing) {
                headerCard(profile: profile)
                if listingCount == 0 {
                    profileCompletionCard(profile: profile)
                }
                statusBanner(status: profile.status)
                quickActionsSection(profile: profile)
                Spacer().frame(height: 28)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 100)
        }
    }

    func profileCompletionCard(profile: ExpertProfile) -> some View {
        let pct = profile.profileCompletionPercentage
        let canOpen = profile.canOpenListing
        return VStack(alignment: .leading, spacing: ExpertHomeDesign.rowSpacing) {
            HStack(spacing: 16) {
                ZStack(alignment: .center) {
                    Circle()
                        .stroke(Color(.tertiarySystemFill), lineWidth: 5)
                        .frame(width: 56, height: 56)
                    Circle()
                        .trim(from: 0, to: CGFloat(pct) / 100)
                        .stroke(canOpen ? Color.green : Color("PrimaryColor"), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .frame(width: 56, height: 56)
                        .rotationEffect(.degrees(-90))
                    Text("\(pct)%")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Profil tamamlanma")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(canOpen ? "Tamamlandı" : "%\(pct) dolu")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.primary)
                }
                Spacer()
                Image(systemName: canOpen ? "checkmark.seal.fill" : "person.text.rectangle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(canOpen ? .green : Color("PrimaryColor").opacity(0.8))
            }
            .padding(ExpertHomeDesign.cardPadding)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: ExpertHomeDesign.cardRadius, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: ExpertHomeDesign.shadowRadius, x: 0, y: ExpertHomeDesign.shadowY)

            if canOpen {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.green)
                    Text("Profiliniz tamam. İlan açabilirsiniz.")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color("PrimaryColor").opacity(0.8))
                    Text("İlan açmak için çalışma detayları, banka bilgileri ve adres bilgilerinizi Profilim sayfasından tamamlayın.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color("PrimaryColor").opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    func headerCard(profile: ExpertProfile) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color("TertiaryColor").opacity(0.35), Color("PrimaryColor").opacity(0.25)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)

                if let urlString = profile.profileImageURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img): img.resizable().scaledToFill()
                        default: Image(systemName: "person.circle.fill").font(.system(size: 32)).foregroundColor(.white.opacity(0.9))
                        }
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.9))
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Hoş geldin")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)

                Text(profile.displayName.isEmpty ? "Uzman" : profile.displayName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                if !profile.businessName.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 11))
                        Text(profile.businessName)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(Color("PrimaryColor"))
                }
            }

            Spacer()
        }
        .padding(ExpertHomeDesign.cardPadding)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: ExpertHomeDesign.cardRadius, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: ExpertHomeDesign.shadowRadius, x: 0, y: ExpertHomeDesign.shadowY)
    }

    func statusBanner(status: String) -> some View {
        let (icon, text, _, fgColor) = statusStyle(status)

        return HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(fgColor)
                .frame(width: 40, height: 40)
                .background(fgColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("Başvuru durumu")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                Text(text)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(fgColor)
            }

            Spacer()
        }
        .padding(ExpertHomeDesign.cardPadding)
        .background(fgColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: ExpertHomeDesign.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: ExpertHomeDesign.cardRadius, style: .continuous)
                .stroke(fgColor.opacity(0.25), lineWidth: 1)
        )
    }

    func statusStyle(_ status: String) -> (icon: String, text: String, bg: Color, fg: Color) {
        let lower = status.lowercased()
        if lower == "approved" || lower == "onaylandı" {
            return ("checkmark.circle.fill", "Onaylandı", Color.green, Color.green)
        }
        if lower == "rejected" || lower == "reddedildi" {
            return ("xmark.circle.fill", "Reddedildi", Color.red, Color.red)
        }
        return ("clock.badge.checkmark", "İnceleme aşamasında", Color.orange, Color.orange)
    }

    func quickActionsSection(profile: ExpertProfile) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 15))
                    .foregroundColor(Color("PrimaryColor"))
                Text("Hızlı Erişim")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.primary)
            }

            VStack(spacing: ExpertHomeDesign.rowSpacing) {
                Button {
                    showMenu = false
                    expertProfilePath.append("listings")
                } label: {
                    actionRowContent(
                        icon: "doc.text.fill",
                        title: "İlanlarım",
                        subtitle: listingCount == 0 ? "İlanlarınızı yönetin" : "\(listingCount) ilan",
                        color: Color("PrimaryColor"),
                        badge: listingCount > 0 ? "\(listingCount)" : nil
                    )
                }
                .buttonStyle(.plain)

                Button {
                    showMenu = false
                    expertProfilePath.append("profile")
                } label: {
                    actionRowContent(
                        icon: "person.crop.rectangle.fill",
                        title: "Profilim",
                        subtitle: "Kişisel ve iş bilgileri",
                        color: Color("TertiaryColor")
                    )
                }
                .buttonStyle(.plain)

                NavigationLink(value: "portfolio") {
                    actionRowContent(
                        icon: "photo.on.rectangle.angled",
                        title: "Portföy",
                        subtitle: profile.portfolioImageURLs.isEmpty ? "Örnek işlerinizi ekleyin" : "\(profile.portfolioImageURLs.count) fotoğraf",
                        color: Color("PrimaryColor")
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func actionRowContent(icon: String, title: String, subtitle: String, color: Color, badge: String? = nil) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
                .frame(width: ExpertHomeDesign.iconSize, height: ExpertHomeDesign.iconSize)
                .background(color.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            if let badge = badge, !badge.isEmpty {
                Text(badge)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color("PrimaryColor"))
                    .clipShape(Capsule())
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary.opacity(0.8))
        }
        .padding(ExpertHomeDesign.cardPadding)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: ExpertHomeDesign.cardRadius, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 6, x: 0, y: 2)
    }

    var expertMenuSheet: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Menü")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)
                    Text("Hesap ayarları ve hızlı erişim")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button { showMenu = false } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            VStack(spacing: 8) {
                menuRow(icon: "person.circle.fill", title: "Profilim", subtitle: "Bilgilerinizi düzenleyin") {
                    showMenu = false
                    expertProfilePath.append("profile")
                }
                menuRow(icon: "doc.text.fill", title: "İlanlarım", subtitle: listingCount == 0 ? "İlanlarınızı yönetin" : "\(listingCount) ilan") {
                    showMenu = false
                    expertProfilePath.append("listings")
                }
                Divider().padding(.horizontal, 20)
                menuRow(icon: "rectangle.portrait.and.arrow.right", title: "Çıkış Yap", subtitle: "Hesabınızdan çıkış yapın", isDestructive: true) {
                    showMenu = false
                    session.signOut()
                }
            }
            .padding(.bottom, 24)

            Spacer()
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func menuRow(icon: String, title: String, subtitle: String, isDestructive: Bool = false, action: @escaping () -> Void) -> some View {
        let color = isDestructive ? Color.red : Color("PrimaryColor")
        return Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(isDestructive ? 0.1 : 0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isDestructive ? .red : .primary)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.7))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(.secondarySystemBackground).opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
    }

    var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.3)
                .tint(Color("PrimaryColor"))
            Text("Yükleniyor...")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var errorView: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 52))
                .foregroundStyle(.orange.opacity(0.9))
            Text(loadError ?? "Profil yüklenemedi")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                Task { await loadProfile() }
            } label: {
                Text("Tekrar Dene")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(Color("PrimaryColor"))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Load

private extension ExpertHomepage {

    func loadProfile() async {
        guard let uid = session.userId else {
            isLoading = false
            loadError = "Oturum bulunamadı."
            return
        }

        isLoading = true
        loadError = nil

        do {
            if let p = try await userRepo.fetchExpertProfile(uid: uid) {
                profile = p
            }
            let services = try await serviceRepo.fetchAllServicesByProviderId(uid)
            listingCount = services.count
            if profile == nil {
                let user = try await userRepo.fetchUser(uid: uid)
                profile = ExpertProfile(
                    id: uid,
                    displayName: user.displayName,
                    email: user.email,
                    phoneNumber: user.phoneNumber ?? "",
                    businessName: "",
                    serviceCategories: [],
                    businessType: "",
                    taxNumber: nil,
                    experienceYears: 0,
                    expertiseAreas: [],
                    certificateURLs: [],
                    educationLevel: "",
                    schoolName: "",
                    status: "Pending",
                    createdAt: nil,
                    profileImageURL: nil,
                    serviceCities: [],
                    workingDays: [],
                    workingHoursStart: nil,
                    workingHoursEnd: nil,
                    minPrice: nil,
                    maxPrice: nil,
                    serviceType: nil,
                    bankName: nil,
                    iban: nil,
                    accountHolderName: nil,
                    portfolioImageURLs: [],
                    address: nil,
                    about: nil,
                    locationGeo: nil
                )
            }
        } catch {
            loadError = "Bağlantı hatası. Tekrar deneyin."
        }

        isLoading = false
    }
}

// MARK: - Şehir seçim sayfası (çoklu)

struct ExpertCityPickerSheet: View {
    @Binding var selectedCities: Set<String>
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var cityNames: [String] { turkishCities.map(\.name) }
    private var filteredCityNames: [String] {
        if searchText.isEmpty { return cityNames }
        return cityNames.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredCityNames, id: \.self) { city in
                    Button {
                        if selectedCities.contains(city) {
                            selectedCities = selectedCities.filter { $0 != city }
                        } else {
                            var next = selectedCities
                            next.insert(city)
                            selectedCities = next
                        }
                    } label: {
                        HStack {
                            Text(city)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedCities.contains(city) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color("PrimaryColor"))
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Şehir ara")
            .navigationTitle("Şehir seçin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Tamam") { dismiss() }
                        .foregroundColor(Color("PrimaryColor"))
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - İlan aç (müşterilerin services’te gördüğü bilgilerle yayınlama)

struct ExpertCreateListingView: View {
    let uid: String
    let profile: ExpertProfile
    var onPublished: () -> Void
    var onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss
    private let serviceRepo = ServiceRepository()
    private let storageUpload = StorageUploadService()

    @State private var title = ""
    @State private var selectedCategory = ""
    @State private var duration = ""
    @State private var priceText = ""
    @State private var descriptionText = ""
    @State private var selectedCity = ""
    @State private var listingImageURL: String?
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var isUploadingImage = false
    @State private var isPublishing = false
    @State private var errorMessage: String?
    @State private var showSuccess = false

    private var categories: [String] { profile.serviceCategories.isEmpty ? ["Yazılım", "Tadilat", "Temizlik", "Nakliyat", "Diğer"] : profile.serviceCategories }
    private var cities: [String] { profile.serviceCities.isEmpty ? ["Ankara", "İstanbul", "İzmir"] : profile.serviceCities }
    private let durationOptions = ["30 dk", "1 saat", "2 saat", "Yarım gün", "Tam gün", "Proje bazlı"]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // İlan görseli
                    createSection(title: "İlan görseli", icon: "photo.on.rectangle.angled") {
                        VStack(alignment: .leading, spacing: 12) {
                            if let urlString = listingImageURL, let url = URL(string: urlString) {
                                ZStack(alignment: .topTrailing) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let img): img.resizable().scaledToFill()
                                        default: Color(.secondarySystemBackground).overlay(ProgressView())
                                        }
                                    }
                                    .frame(height: 160)
                                    .frame(maxWidth: .infinity)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    Button {
                                        listingImageURL = nil
                                        photoPickerItem = nil
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundStyle(.white)
                                            .shadow(radius: 2)
                                    }
                                    .padding(8)
                                }
                            } else {
                                PhotosPicker(
                                    selection: $photoPickerItem,
                                    matching: .images,
                                    photoLibrary: .shared()
                                ) {
                                    HStack(spacing: 10) {
                                        if isUploadingImage {
                                            ProgressView().scaleEffect(0.9).tint(Color("PrimaryColor"))
                                        } else {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 28))
                                                .foregroundColor(Color("PrimaryColor"))
                                        }
                                        Text(listingImageURL == nil ? "İlan için fotoğraf ekle" : "Fotoğrafı değiştir")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(Color("PrimaryColor"))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 120)
                                    .background(Color("PrimaryColor").opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                                .buttonStyle(.plain)
                                .disabled(isUploadingImage)
                            }
                        }
                    }

                    // Temel bilgiler
                    createSection(title: "Temel bilgiler", icon: "doc.text") {
                        VStack(alignment: .leading, spacing: 16) {
                            fieldRow("İlan başlığı", icon: "textformat") {
                                TextField("Örn: Ev tadilatı, mobil uygulama", text: $title)
                                    .textFieldStyle(.plain)
                                    .padding(12)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(10)
                                    .autocorrectionDisabled()
                            }
                            fieldRow("Kategori", icon: "folder") {
                                Picker("Kategori", selection: $selectedCategory) {
                                    Text("Seçin").tag("")
                                    ForEach(categories, id: \.self) { Text($0).tag($0) }
                                }
                                .pickerStyle(.menu)
                                .onAppear { if selectedCategory.isEmpty, let first = categories.first { selectedCategory = first } }
                            }
                        }
                    }

                    // Fiyat ve süre
                    createSection(title: "Fiyat ve süre", icon: "clock.badge.checkmark") {
                        VStack(alignment: .leading, spacing: 16) {
                            fieldRow("Süre", icon: "clock") {
                                Picker("Süre", selection: $duration) {
                                    Text("Seçin").tag("")
                                    ForEach(durationOptions, id: \.self) { Text($0).tag($0) }
                                }
                                .pickerStyle(.menu)
                            }
                            fieldRow("Fiyat (₺)", icon: "turkishlirasign") {
                                TextField("Örn: 500", text: $priceText)
                                    .keyboardType(.numberPad)
                                    .padding(12)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(10)
                            }
                        }
                    }

                    // Konum ve açıklama
                    createSection(title: "Konum ve açıklama", icon: "mappin.circle") {
                        VStack(alignment: .leading, spacing: 16) {
                            fieldRow("Şehir", icon: "location") {
                                Picker("Şehir", selection: $selectedCity) {
                                    Text("Seçin").tag("")
                                    ForEach(cities, id: \.self) { Text($0).tag($0) }
                                }
                                .pickerStyle(.menu)
                                .onAppear { if selectedCity.isEmpty, let first = cities.first { selectedCity = first } }
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Açıklama")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.secondary)
                                TextField("Hizmetinizi kısaca tanıtın", text: $descriptionText, axis: .vertical)
                                    .lineLimit(4...8)
                                    .padding(12)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(10)
                                    .autocorrectionDisabled()
                            }
                        }
                    }

                    if let err = errorMessage {
                        Text(err)
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                            .padding(.horizontal, 4)
                    }

                    Button {
                        Task { await publish() }
                    } label: {
                        HStack(spacing: 8) {
                            if isPublishing {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                Text("İlanı Yayınla")
                            }
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(canPublish ? Color("PrimaryColor") : Color.gray.opacity(0.6))
                        .cornerRadius(14)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canPublish || isPublishing)
                    .padding(.top, 8)
                }
                .padding(20)
            }
            .background(Color("BackgroundColor"))
            .navigationTitle("Yeni İlan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") {
                        onDismiss()
                        dismiss()
                    }
                    .foregroundColor(Color("PrimaryColor"))
                }
            }
            .alert("İlan Yayınlandı", isPresented: $showSuccess) {
                Button("Tamam") {
                    onPublished()
                    dismiss()
                }
            } message: {
                Text("İlanınız müşteriler tarafında görünecektir.")
            }
            .onChange(of: photoPickerItem) { _, newItem in
                guard let newItem else { return }
                Task { await uploadListingPhoto(newItem) }
            }
        }
    }

    private func createSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color("PrimaryColor"))
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
            content()
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                )
        }
    }

    private func fieldRow<Content: View>(_ label: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
            content()
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.secondary)
    }

    private var canPublish: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !selectedCategory.isEmpty
            && !duration.isEmpty
            && (Int(priceText) ?? 0) > 0
            && !selectedCity.isEmpty
            && !descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func uploadListingPhoto(_ item: PhotosPickerItem) async {
        isUploadingImage = true
        defer { isUploadingImage = false }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        do {
            listingImageURL = try await storageUpload.uploadListingImage(image: image, uid: uid)
        } catch {
            errorMessage = "Fotoğraf yüklenemedi: \(error.localizedDescription)"
        }
    }

    private func publish() async {
        errorMessage = nil
        isPublishing = true
        defer { isPublishing = false }
        let price = Int(priceText) ?? 0
        guard price > 0 else {
            errorMessage = "Geçerli bir fiyat girin."
            return
        }
        do {
            _ = try await serviceRepo.publishExpertListing(
                providerId: uid,
                profile: profile,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                category: selectedCategory,
                duration: duration,
                price: price,
                description: descriptionText.trimmingCharacters(in: .whitespacesAndNewlines),
                city: selectedCity,
                imageURL: listingImageURL ?? profile.profileImageURL
            )
            showSuccess = true
        } catch {
            errorMessage = "Yayınlama hatası: \(error.localizedDescription)"
        }
    }
}

#Preview {
    ExpertHomepage()
        .environmentObject(SessionViewModel())
}
