//
//  ProviderReviewsPage.swift
//  UzmanaGel
//
//  Created by Antigravity on 22.07.2026.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ProviderReviewsPage: View {
    let providerId: String
    let providerName: String
    let serviceTitle: String
    
    @StateObject private var viewModel: ProviderReviewsViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Fotoğraf Galerisi Modal için State
    @State private var galleryPhotos: [String] = []
    @State private var galleryIndex: Int = 0
    @State private var showGallery = false
    
    // Yanıt ve Bildirim Modalları için State
    @State private var respondingReview: Review?
    @State private var reportingReview: Review?
    @State private var showWriteReviewSheet = false
    
    init(providerId: String, providerName: String = "", serviceTitle: String = "") {
        self.providerId = providerId
        self.providerName = providerName
        self.serviceTitle = serviceTitle
        _viewModel = StateObject(wrappedValue: ProviderReviewsViewModel(providerId: providerId))
    }
    
    var body: some View {
        ZStack {
            Color("BackgroundColor").ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Puan Özeti, Dağılım Çubukları ve Kategori Ortalamaları
                    summarySection
                    
                    // Sıralama & Filtreleme ve Anonimleştirme Ayarı
                    filterAndSortSection
                    
                    // Yorumlar Listesi
                    if viewModel.isLoading {
                        ProgressView("Yorumlar yükleniyor...".localized)
                            .padding(.top, 40)
                    } else if let err = viewModel.errorMessage {
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.orange)
                            Text("Yorumlar Yüklenemedi")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color("Text"))
                            Text(err)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("CardBackground"))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.top, 20)
                    } else if viewModel.filteredReviews.isEmpty {
                        emptyStateSection
                    } else {
                        reviewsListSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .padding(.bottom, 40)
            }
            .refreshable {
                await viewModel.loadReviews()
            }
        }
        .navigationTitle(providerName.isEmpty ? "Değerlendirmeler".localized : "\(providerName) Yorumları")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadReviews()
        }
        .sheet(isPresented: $showGallery) {
            ReviewPhotoGalleryView(photos: galleryPhotos, selectedIndex: galleryIndex)
        }
        .sheet(item: $respondingReview) { review in
            ProviderResponseSheet(review: review) { response in
                await viewModel.submitResponse(review: review, responseText: response)
            }
        }
        .sheet(item: $reportingReview) { review in
            ReviewReportSheet(review: review) { category, description in
                await viewModel.report(review: review, category: category, description: description)
            }
        }
        .sheet(isPresented: $showWriteReviewSheet) {
            ReviewSubmissionSheet(
                bookingId: "",
                serviceTitle: serviceTitle.isEmpty ? nil : serviceTitle,
                providerId: providerId,
                providerName: providerName.isEmpty ? "Uzman" : providerName,
                customerId: Auth.auth().currentUser?.uid ?? "",
                customerName: "Müşteri"
            ) { _ in
                Task {
                    await viewModel.loadReviews()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showWriteReviewSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.pencil")
                        Text("Değerlendir".localized)
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color("PrimaryColor"))
                }
            }
        }
    }
    
    // MARK: - Summary Section
    private var summarySection: some View {
        VStack(spacing: 20) {
            // Üst Kısım: Genel Ortalamalar ve Yıldızlar
            HStack(alignment: .center, spacing: 24) {
                VStack(spacing: 4) {
                    Text(String(format: "%.1f", viewModel.summary.averageScore))
                        .font(.system(size: 46, weight: .black))
                        .foregroundColor(Color("Text"))
                    
                    HStack(spacing: 3) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= Int(viewModel.summary.averageScore.rounded()) ? "star.fill" : "star")
                                .font(.system(size: 14))
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Text("\(viewModel.summary.totalCount) yorum".localized)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .frame(width: 120)
                
                Divider()
                    .frame(height: 90)
                
                // Sağ Kısım: 5 Yıldız Dağılım Çubukları (Distribution Chart)
                VStack(spacing: 6) {
                    ForEach((1...5).reversed(), id: \.self) { star in
                        HStack(spacing: 8) {
                            Text("\(star) yıldız".localized)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(width: 44, alignment: .leading)
                            
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .fill(Color.secondary.opacity(0.15))
                                    
                                    let count = viewModel.summary.starDistribution[star] ?? 0
                                    let total = max(1, viewModel.summary.totalCount)
                                    let ratio = CGFloat(count) / CGFloat(total)
                                    
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .fill(LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing))
                                        .frame(width: geo.size.width * ratio)
                                }
                            }
                            .frame(height: 8)
                            
                            Text("\(viewModel.summary.starDistribution[star] ?? 0)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color("Text"))
                                .frame(width: 24, alignment: .trailing)
                        }
                    }
                }
            }
            
            // Alt Kısım: Kategori Ortalamaları Bar Charts
            if !viewModel.summary.categoryAverages.isEmpty && viewModel.summary.totalCount > 0 {
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Kategori Ortalamaları".localized)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color("Text"))
                    
                    VStack(spacing: 10) {
                        ForEach(ReviewCategory.allCases) { cat in
                            let avg = viewModel.summary.categoryAverages[cat.rawValue] ?? viewModel.summary.averageScore
                            HStack(spacing: 10) {
                                Text(cat.displayName)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .frame(width: 110, alignment: .leading)
                                
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                                            .fill(Color.secondary.opacity(0.15))
                                        
                                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                                            .fill(LinearGradient(colors: [Color("PrimaryColor"), Color("PrimaryColor").opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                                            .frame(width: geo.size.width * CGFloat(min(avg, 5.0) / 5.0))
                                    }
                                }
                                .frame(height: 8)
                                
                                Text(String(format: "%.1f", avg))
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color("Text"))
                                    .frame(width: 28, alignment: .trailing)
                            }
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - Filter and Sort Section
    private var filterAndSortSection: some View {
        VStack(spacing: 12) {
            HStack {
                // Filtre Çipleri
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ReviewFilterOption.allCases) { opt in
                            Button {
                                withAnimation { viewModel.selectedFilter = opt }
                            } label: {
                                Text(opt.localized)
                                    .font(.system(size: 13, weight: viewModel.selectedFilter == opt ? .bold : .medium))
                                    .foregroundColor(viewModel.selectedFilter == opt ? .white : Color("Text"))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(viewModel.selectedFilter == opt ? Color("PrimaryColor") : Color("CardBackground"))
                                    .clipShape(Capsule())
                                    .shadow(color: viewModel.selectedFilter == opt ? Color("PrimaryColor").opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Spacer()
                
                // Sıralama Menüsü
                Menu {
                    Picker("Sıralama", selection: $viewModel.selectedSort) {
                        ForEach(ReviewSortOption.allCases) { sort in
                            Text(sort.localized).tag(sort)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 12))
                        Text(viewModel.selectedSort.localized)
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(Color("PrimaryColor"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color("PrimaryColor").opacity(0.12))
                    .clipShape(Capsule())
                }
            }
            
            // Gizlilik (Anonim İsim) Ayarı Topgle çubuğu
            HStack {
                Image(systemName: "shield.fill")
                    .font(.system(size: 13))
                    .foregroundColor(Color("PrimaryColor"))
                Text("Müşteri isimlerini gizle (Örn: B***** A.)".localized)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Spacer()
                Toggle("", isOn: $viewModel.isAnonymizedOption)
                    .labelsHidden()
                    .tint(Color("PrimaryColor"))
                    .scaleEffect(0.8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color("CardBackground").opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
    
    // MARK: - Reviews List
    private var reviewsListSection: some View {
        LazyVStack(spacing: 16) {
            ForEach(viewModel.filteredReviews) { review in
                ReviewCardView(
                    review: review,
                    isAnonymized: viewModel.isAnonymizedOption,
                    canRespond: viewModel.canCurrentProviderRespond,
                    onHelpfulTapped: {
                        Task { await viewModel.toggleHelpful(review: review) }
                    },
                    onRespondTapped: {
                        respondingReview = review
                    },
                    onReportTapped: {
                        reportingReview = review
                    },
                    onPhotoTapped: { photos, index in
                        galleryPhotos = photos
                        galleryIndex = index
                        showGallery = true
                    }
                )
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateSection: some View {
        VStack(spacing: 14) {
            Image(systemName: "star.bubble")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
                .padding(.top, 20)
            
            Text("Henüz değerlendirme yok".localized)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color("Text"))
            
            Text("Bu kriterlere uygun bir yorum bulunamadı. Filtreyi değiştirerek tekrar deneyebilirsiniz.".localized)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
