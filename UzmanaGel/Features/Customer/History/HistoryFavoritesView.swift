import SwiftUI

struct HistoryFavoritesView: View {
    @StateObject private var viewModel = HistoryFavoritesViewModel()
    @State private var ratingTargetId: String? = nil
    
    var body: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Segmented tab picker
                Picker("Sekme Seçimi", selection: $viewModel.selectedTab) {
                    Text("Geçmiş Siparişler").tag(0)
                    Text("Favoriler & Arama").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .background(Color.themeCardBackground)
                
                if viewModel.isLoading && viewModel.orders.isEmpty {
                    LoadingView(message: "Verileriniz yükleniyor...")
                } else {
                    if viewModel.selectedTab == 0 {
                        ordersTab
                    } else {
                        favoritesTab
                    }
                }
            }
            
            // Status overlay toast notifications
            if let success = viewModel.successMessage {
                toastOverlay(message: success, isError: false)
            }
            if let error = viewModel.errorMessage {
                toastOverlay(message: error, isError: true)
            }
        }
        .navigationTitle("Geçmiş ve Favoriler")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadAllData()
        }
    }
    
    // MARK: - Orders Tab
    private var ordersTab: some View {
        VStack(spacing: 0) {
            // Filter Picker
            Picker("Filtrele", selection: $viewModel.orderFilter) {
                ForEach(HistoryFavoritesViewModel.OrderFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.bottom, Constants.paddingS)
            
            if viewModel.filteredOrders.isEmpty {
                EmptyStateView(
                    iconName: "clock.badge.exclamationmark",
                    title: "Sipariş Geçmişiniz Boş",
                    message: "Daha önce hiçbir hizmet siparişi oluşturmadınız."
                )
            } else {
                List {
                    ForEach(viewModel.groupedOrders, id: \.key) { group in
                        Section(header: Text(group.key).font(.subheadline).fontWeight(.bold).foregroundColor(Color.themeSecondaryText)) {
                            ForEach(group.value) { order in
                                orderRow(order)
                                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }
    
    @ViewBuilder
    private func orderRow(_ order: Order) -> some View {
        CardView(cornerRadius: Constants.radiusM, shadowRadius: Constants.shadowRadiusS) {
            VStack(alignment: .leading, spacing: Constants.spacingS) {
                HStack {
                    Text(order.providerName)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.themeText)
                    Spacer()
                    BadgeView(text: order.status.rawValue, style: badgeStyle(for: order.status))
                }
                
                Text(order.serviceTitle)
                    .font(.footnote)
                    .foregroundColor(Color.themeSecondaryText)
                
                HStack {
                    Text("₺\(String(format: "%.2f", order.price))")
                        .font(.footnote)
                        .fontWeight(.bold)
                        .foregroundColor(Color.themePrimary)
                    Spacer()
                    Text(dateString(for: order.date))
                        .font(.caption2)
                        .foregroundColor(Color.themeSecondaryText)
                }
                
                Divider()
                    .background(Color.themeBorder)
                
                HStack {
                    if order.status == .completed {
                        if order.isRated, let rate = order.rating {
                            HStack(spacing: 2) {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: "star.fill")
                                        .foregroundColor(star <= rate ? Color.themeWarning : Color.themeBorder)
                                        .font(.caption2)
                                }
                            }
                        } else {
                            Button {
                                ratingTargetId = order.id
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "star")
                                    Text("Puan Ver")
                                }
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.themeWarning)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    Spacer()
                    Button {
                        Task {
                            await viewModel.repeatOrder(id: order.id)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                            Text("Tekrar Sipariş Et")
                        }
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.themePrimary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { ratingTargetId == order.id },
            set: { if !$0 { ratingTargetId = nil } }
        )) {
            ratingView(orderId: order.id)
        }
    }
    
    // MARK: - Favorites Tab
    private var favoritesTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Constants.spacingL) {
                
                // 1. Favorite Providers Grid
                VStack(alignment: .leading, spacing: Constants.spacingS) {
                    Text("Favori Ustalarım")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color.themeSecondaryText)
                        .padding(.horizontal)
                    
                    if viewModel.favoriteProviders.isEmpty {
                        Text("Henüz favori listenize kimseyi eklemediniz.")
                            .font(.footnote)
                            .foregroundColor(Color.themeSecondaryText)
                            .padding(.horizontal)
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(viewModel.favoriteProviders) { provider in
                                providerCard(provider)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // 2. Recently Viewed (Horizontal scroll)
                VStack(alignment: .leading, spacing: Constants.spacingS) {
                    Text("Son Görüntülenenler")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color.themeSecondaryText)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Constants.spacingM) {
                            ForEach(viewModel.recentlyViewed) { provider in
                                recentThumbnail(provider)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // 3. Saved Searches
                VStack(alignment: .leading, spacing: Constants.spacingS) {
                    Text("Kaydedilen Aramalarım")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color.themeSecondaryText)
                        .padding(.horizontal)
                    
                    VStack(spacing: 0) {
                        ForEach(viewModel.savedSearches, id: \.self) { search in
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(Color.themeSecondaryText)
                                Text(search)
                                    .font(.subheadline)
                                    .foregroundColor(Color.themeText)
                                Spacer()
                                Button {
                                    if let idx = viewModel.savedSearches.firstIndex(of: search) {
                                        viewModel.deleteSavedSearch(at: IndexSet(integer: idx))
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(Color.themeError)
                                        .font(.caption)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding()
                            Divider()
                        }
                    }
                    .background(Color.themeCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Constants.radiusM))
                    .overlay(RoundedRectangle(cornerRadius: Constants.radiusM).stroke(Color.themeBorder, lineWidth: 1))
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
    
    @ViewBuilder
    private func providerCard(_ provider: Provider) -> some View {
        CardView(cornerRadius: Constants.radiusM, shadowRadius: Constants.shadowRadiusS) {
            VStack(spacing: Constants.spacingS) {
                HStack {
                    Spacer()
                    Button {
                        viewModel.toggleFavorite(id: provider.id)
                    } label: {
                        Image(systemName: "heart.fill")
                            .foregroundColor(Color.themeError)
                            .font(.subheadline)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                AvatarView(imageURLString: provider.imageUrl, size: 55, isEditable: false)
                
                Text(provider.businessName)
                    .font(.footnote)
                    .fontWeight(.bold)
                    .foregroundColor(Color.themeText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 36)
                
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .foregroundColor(Color.themeWarning)
                        .font(.caption2)
                    Text(String(format: "%.1f", provider.rating))
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.themeText)
                }
                
                Button {
                    // Quick contact action (stub)
                } label: {
                    Text("İletişime Geç")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .background(Color.themePrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    @ViewBuilder
    private func recentThumbnail(_ provider: Provider) -> some View {
        VStack(spacing: Constants.spacingXS) {
            AvatarView(imageURLString: provider.imageUrl, size: 50, isEditable: false)
            Text(provider.businessName.prefix(12) + "...")
                .font(.caption2)
                .foregroundColor(Color.themeText)
                .lineLimit(1)
        }
        .frame(width: 80)
        .padding(Constants.paddingS)
        .background(Color.themeCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Constants.radiusS))
        .overlay(RoundedRectangle(cornerRadius: Constants.radiusS).stroke(Color.themeBorder, lineWidth: 1))
    }
    
    // Rating overlay sheet
    @ViewBuilder
    private func ratingView(orderId: String) -> some View {
        NavigationStack {
            VStack(spacing: Constants.spacingL) {
                Text("Hizmeti Puanlayın")
                    .font(.headline)
                    .padding(.top)
                
                Text("Ustanın hizmet kalitesini değerlendirerek diğer kullanıcılara yardımcı olun.")
                    .font(.caption)
                    .foregroundColor(Color.themeSecondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { rate in
                        Button {
                            Task {
                                await viewModel.submitRating(orderId: orderId, rating: rate)
                                ratingTargetId = nil
                            }
                        } label: {
                            Image(systemName: "star.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 38, height: 38)
                                .foregroundColor(Color.themeWarning)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Değerlendirme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") {
                        ratingTargetId = nil
                    }
                }
            }
            .background(Color.themeBackground)
        }
    }
    
    // Helpers
    private func badgeStyle(for status: Order.OrderStatus) -> BadgeView.BadgeStyle {
        switch status {
        case .pending: return .warning
        case .active: return .primary
        case .completed: return .success
        case .cancelled: return .error
        }
    }
    
    private func dateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "dd MMM yyyy"
        return formatter.string(from: date)
    }
    
    @ViewBuilder
    private func toastOverlay(message: String, isError: Bool) -> some View {
        VStack {
            Spacer()
            HStack {
                Image(systemName: isError ? "xmark.circle.fill" : "checkmark.circle.fill")
                Text(message)
                    .font(.footnote)
                    .fontWeight(.medium)
            }
            .padding()
            .background(isError ? Color.themeError : Color.themeSuccess)
            .foregroundColor(.white)
            .clipShape(Capsule())
            .shadow(radius: 5)
            .padding(.bottom, Constants.paddingXL)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    viewModel.successMessage = nil
                }
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut, value: viewModel.successMessage)
    }
}

#Preview {
    NavigationStack {
        HistoryFavoritesView()
    }
}
