//
//  ExpertListingsPage.swift
//  UzmanaGel
//
//  Uzman ilan yönetimi: listele, düzenle, sil.
//

import SwiftUI

// MARK: - Design

private enum ListingsDesign {
    static let cardRadius: CGFloat = 16
    static let cardPadding: CGFloat = 16
    static let thumbSize: CGFloat = 72
    static let shadowRadius: CGFloat = 6
}

struct ExpertListingsPage: View {
    let uid: String
    let profile: ExpertProfile
    var onRefresh: () async -> Void

    @Environment(\.dismiss) private var dismiss
    private let serviceRepo = ServiceRepository()

    @State private var services: [Service] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var serviceToEdit: Service?
    @State private var serviceToDelete: Service?
    @State private var deleteConfirm = false

    private var categories: [String] { profile.serviceCategories.isEmpty ? ["Yazılım", "Tadilat", "Temizlik", "Nakliyat", "Diğer"] : profile.serviceCategories }
    private var cities: [String] { profile.serviceCities.isEmpty ? ["Ankara", "İstanbul", "İzmir"] : profile.serviceCities }
    private let durationOptions = ["30 dk", "1 saat", "2 saat", "Yarım gün", "Tam gün", "Proje bazlı"]

    var body: some View {
        Group {
            if isLoading {
                VStack(spacing: 20) {
                    ProgressView().scaleEffect(1.3).tint(Color("PrimaryColor"))
                    Text("İlanlar yükleniyor...")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if services.isEmpty {
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        headerSection
                        LazyVStack(spacing: 14) {
                            ForEach(services) { svc in
                                listingCard(svc)
                            }
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 32)
                }
            }
        }
        .background(Color("BackgroundColor"))
        .navigationTitle("İlanlarım")
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
        .task { await loadServices() }
        .refreshable { await loadServices() }
        .sheet(item: $serviceToEdit) { svc in
            ExpertEditListingView(
                service: svc,
                profile: profile,
                categories: categories,
                cities: cities,
                durationOptions: durationOptions,
                onSave: { Task { await loadServices(); await onRefresh(); serviceToEdit = nil } },
                onDismiss: { serviceToEdit = nil }
            )
        }
        .alert("İlanı sil", isPresented: $deleteConfirm) {
            Button("İptal", role: .cancel) { serviceToDelete = nil }
            Button("Sil", role: .destructive) {
                guard let svc = serviceToDelete else { return }
                Task { await deleteService(svc); serviceToDelete = nil }
            }
        } message: {
            if let svc = serviceToDelete {
                Text("\"\(svc.title)\" ilanı silinecek. Bu işlem geri alınamaz.")
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("Yayındaki ilanlar")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                Text("· \(services.count) ilan")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color("PrimaryColor").opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 44))
                    .foregroundColor(Color("PrimaryColor"))
            }
            VStack(spacing: 8) {
                Text("Henüz ilanınız yok")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                Text("Sağ alttaki + butonu ile yeni ilan açabilir,\nmüşterilere hizmetlerinizi sunabilirsiniz.")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func listingCard(_ svc: Service) -> some View {
        HStack(alignment: .center, spacing: 14) {
            listingThumbnail(svc)
            VStack(alignment: .leading, spacing: 6) {
                Text(svc.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                Text(svc.category)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                HStack(spacing: 8) {
                    Text("₺\(svc.price)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color("TertiaryColor"))
                    Text("·")
                        .foregroundColor(.secondary)
                    Text(svc.duration)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            Spacer(minLength: 8)
            VStack(spacing: 12) {
                Button {
                    serviceToEdit = svc
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color("PrimaryColor"))
                }
                .buttonStyle(.plain)
                Button {
                    serviceToDelete = svc
                    deleteConfirm = true
                } label: {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.red.opacity(0.9))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(ListingsDesign.cardPadding)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: ListingsDesign.cardRadius, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: ListingsDesign.shadowRadius, x: 0, y: 2)
    }

    private func listingThumbnail(_ svc: Service) -> some View {
        Group {
            if !svc.image.isEmpty, let url = URL(string: svc.image) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img): img.resizable().scaledToFill()
                    default: imagePlaceholder
                    }
                }
            } else {
                imagePlaceholder
            }
        }
        .frame(width: ListingsDesign.thumbSize, height: ListingsDesign.thumbSize)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var imagePlaceholder: some View {
        ZStack {
            Color("PrimaryColor").opacity(0.12)
            Image(systemName: "photo")
                .font(.system(size: 26))
                .foregroundColor(Color("PrimaryColor").opacity(0.6))
        }
    }

    private func loadServices() async {
        isLoading = true
        errorMessage = nil
        do {
            services = try await serviceRepo.fetchAllServicesByProviderId(uid)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func deleteService(_ svc: Service) async {
        do {
            try await serviceRepo.deleteService(serviceId: svc.serviceId)
            await loadServices()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - İlan düzenle

private enum EditListingDesign {
    static let cardRadius: CGFloat = 14
    static let sectionSpacing: CGFloat = 20
}

struct ExpertEditListingView: View {
    let service: Service
    let profile: ExpertProfile
    let categories: [String]
    let cities: [String]
    let durationOptions: [String]
    var onSave: () -> Void
    var onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss
    private let serviceRepo = ServiceRepository()

    @State private var title: String = ""
    @State private var selectedCategory: String = ""
    @State private var duration: String = ""
    @State private var priceText: String = ""
    @State private var descriptionText: String = ""
    @State private var selectedCity: String = ""
    @State private var listingImageURL: String?
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: EditListingDesign.sectionSpacing) {
                    if let urlString = listingImageURL, let url = URL(string: urlString) {
                        editSection(title: "İlan görseli", icon: "photo") {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let img): img.resizable().scaledToFill()
                                default: Color(.secondarySystemBackground).overlay(ProgressView())
                                }
                            }
                            .frame(height: 140)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }

                    editSection(title: "Temel bilgiler", icon: "doc.text") {
                        VStack(alignment: .leading, spacing: 14) {
                            fieldRow("İlan başlığı") {
                                TextField("Başlık", text: $title)
                                    .padding(12)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(10)
                            }
                            fieldRow("Kategori") {
                                Picker("Kategori", selection: $selectedCategory) {
                                    ForEach(categories, id: \.self) { Text($0).tag($0) }
                                }
                                .pickerStyle(.menu)
                            }
                        }
                    }

                    editSection(title: "Fiyat ve süre", icon: "clock.badge.checkmark") {
                        VStack(alignment: .leading, spacing: 14) {
                            fieldRow("Süre") {
                                Picker("Süre", selection: $duration) {
                                    ForEach(durationOptions, id: \.self) { Text($0).tag($0) }
                                }
                                .pickerStyle(.menu)
                            }
                            fieldRow("Fiyat (₺)") {
                                TextField("Fiyat", text: $priceText)
                                    .keyboardType(.numberPad)
                                    .padding(12)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(10)
                            }
                        }
                    }

                    editSection(title: "Konum ve açıklama", icon: "mappin.circle") {
                        VStack(alignment: .leading, spacing: 14) {
                            fieldRow("Şehir") {
                                Picker("Şehir", selection: $selectedCity) {
                                    ForEach(cities, id: \.self) { Text($0).tag($0) }
                                }
                                .pickerStyle(.menu)
                            }
                            fieldRow("Açıklama") {
                                TextField("Açıklama", text: $descriptionText, axis: .vertical)
                                    .lineLimit(4...8)
                                    .padding(12)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(10)
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
                        Task { await save() }
                    } label: {
                        HStack(spacing: 8) {
                            if isSaving {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                Text("Değişiklikleri Kaydet")
                            }
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color("PrimaryColor"))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(isSaving)
                    .padding(.top, 4)
                }
                .padding(20)
                .padding(.bottom, 32)
            }
            .background(Color("BackgroundColor"))
            .navigationTitle("İlanı Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { onDismiss(); dismiss() }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color("PrimaryColor"))
                }
            }
            .onAppear {
                title = service.title
                selectedCategory = service.category
                duration = service.duration
                priceText = "\(service.price)"
                descriptionText = service.description
                selectedCity = service.city
                listingImageURL = service.image.isEmpty ? nil : service.image
            }
        }
    }

    private func editSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color("PrimaryColor"))
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
            }
            content()
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: EditListingDesign.cardRadius, style: .continuous))
        }
    }

    private func fieldRow<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
            content()
        }
    }

    private func save() async {
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }
        let price = Int(priceText) ?? 0
        guard price > 0 else {
            errorMessage = "Geçerli bir fiyat girin."
            return
        }
        do {
            try await serviceRepo.updateService(serviceId: service.serviceId, fields: [
                "title": title.trimmingCharacters(in: .whitespacesAndNewlines),
                "category": selectedCategory,
                "duration": duration,
                "price": price,
                "description": descriptionText.trimmingCharacters(in: .whitespacesAndNewlines),
                "city": selectedCity,
                "image": listingImageURL ?? service.image
            ])
            onSave()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
