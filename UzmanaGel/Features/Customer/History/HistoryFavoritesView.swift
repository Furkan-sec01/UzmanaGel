import SwiftUI
import Firebase
import FirebaseAuth

@MainActor
struct HistoryFavoritesView: View {
    @StateObject private var viewModel = HistoryFavoritesViewModel()
    @State private var ratingTargetId: String? = nil
    @State private var reorderService: Service? = nil
    @State private var reorderLoading: String? = nil
    @State private var contactProviderLoading: String? = nil
    @State private var navigateToService = false

    // App's real asset colors
    private let appBg       = Color("BackgroundColor")
    private let appPrimary  = Color("PrimaryColor")
    private let appCard     = Color("CardBackground")
    private let appAccent   = Color("TertiaryColor")   // amber/sarı
    private let appText     = Color("Text")
    private let appSecondary = Color("SecondaryColor")

    var body: some View {
        ZStack {
            appBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Main Tab Picker ──────────────────────────────────────
                HStack(spacing: 0) {
                    mainTabButton(title: "Geçmiş Siparişler", icon: "clock.fill", index: 0)
                    mainTabButton(title: "Favoriler & Arama", icon: "heart.fill",  index: 1)
                }
                .padding(6)
                .background(appCard)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(appSecondary.opacity(0.25), lineWidth: 1))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(appCard)
                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)

                // ── Content ──────────────────────────────────────────────
                if viewModel.isLoading && viewModel.orders.isEmpty && viewModel.favoriteProviders.isEmpty {
                    Spacer()
                    VStack(spacing: 14) {
                        ProgressView().tint(appPrimary).scaleEffect(1.2)
                        Text("Yükleniyor...").font(.footnote).foregroundColor(appSecondary)
                    }
                    Spacer()
                } else {
                    Group {
                        if viewModel.selectedTab == 0 { ordersTab }
                        else { favoritesTab }
                    }
                }
            }

            // Toast messages
            if let msg = viewModel.successMessage { toast(msg, isError: false) }
            if let msg = viewModel.errorMessage   { toast(msg, isError: true)  }
        }
        .navigationTitle("Geçmiş ve Favoriler")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadAllData() }
        .navigationDestination(isPresented: $navigateToService) {
            if let s = reorderService {
                ServiceDetailPage(service: s, imageURL: nil, isFavorite: false)
            }
        }
    }

    // MARK: - Custom Tab Button
    private func mainTabButton(title: String, icon: String, index: Int) -> some View {
        let selected = viewModel.selectedTab == index
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { viewModel.selectedTab = index }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.caption)
                Text(title).font(.caption).fontWeight(selected ? .bold : .medium)
            }
            .foregroundColor(selected ? .white : appPrimary.opacity(0.6))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(selected ? appPrimary : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .animation(.easeInOut(duration: 0.2), value: selected)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: ─────────────────── ORDERS TAB ───────────────────────────────
    private var ordersTab: some View {
        VStack(spacing: 0) {
            // Filter chips
            HStack(spacing: 8) {
                ForEach(HistoryFavoritesViewModel.OrderFilter.allCases, id: \.self) { f in
                    filterChip(f)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(appBg)

            if viewModel.filteredOrders.isEmpty {
                emptyOrders
            } else {
                List {
                    ForEach(viewModel.groupedOrders, id: \.key) { group in
                        Section {
                            ForEach(group.value) { order in
                                orderCard(order)
                                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                            }
                        } header: {
                            HStack(spacing: 6) {
                                Rectangle()
                                    .fill(appAccent)
                                    .frame(width: 3, height: 14)
                                    .clipShape(Capsule())
                                Text(group.key)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(appPrimary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .background(appBg)
                .scrollContentBackground(.hidden)
            }
        }
    }

    private func filterChip(_ filter: HistoryFavoritesViewModel.OrderFilter) -> some View {
        let sel = viewModel.orderFilter == filter
        return Button {
            withAnimation(.easeInOut(duration: 0.18)) { viewModel.orderFilter = filter }
        } label: {
            Text(filter.rawValue)
                .font(.caption2)
                .fontWeight(sel ? .bold : .regular)
                .foregroundColor(sel ? appPrimary : appSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(sel ? appAccent.opacity(0.18) : appCard)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(sel ? appAccent : appSecondary.opacity(0.3), lineWidth: 1.5))
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var emptyOrders: some View {
        VStack(spacing: 18) {
            Spacer()
            ZStack {
                Circle().fill(appAccent.opacity(0.12)).frame(width: 88, height: 88)
                Image(systemName: "clock.badge.exclamationmark")
                    .font(.system(size: 36))
                    .foregroundColor(appPrimary.opacity(0.5))
            }
            Text("Sipariş Geçmişiniz Boş")
                .font(.headline).fontWeight(.bold).foregroundColor(appText)
            Text("Daha önce hiçbir hizmet siparişi oluşturmadınız.")
                .font(.footnote).foregroundColor(appSecondary)
                .multilineTextAlignment(.center).padding(.horizontal, 32)
            Spacer()
        }
    }

    // MARK: - Order Card (classic style)
    @ViewBuilder
    private func orderCard(_ order: Order) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                // Provider name + Status badge
                HStack {
                    Text(order.providerName)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(appText)
                    Spacer()
                    inlineStatusBadge(order.status)
                }

                // Service title
                Text(order.serviceTitle)
                    .font(.footnote)
                    .foregroundColor(appSecondary)

                // Price + Date
                HStack {
                    Text("₺\(String(format: "%.2f", order.price))")
                        .font(.footnote)
                        .fontWeight(.bold)
                        .foregroundColor(appPrimary)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "calendar").font(.caption2)
                        Text(dateStr(order.date))
                    }
                    .font(.caption2)
                    .foregroundColor(appSecondary)
                }

                Divider().background(appSecondary.opacity(0.2))

                // Action row
                HStack(spacing: 10) {
                    if order.status == .completed {
                        if order.isRated, let r = order.rating {
                            HStack(spacing: 2) {
                                ForEach(1...5, id: \.self) { s in
                                    Image(systemName: s <= r ? "star.fill" : "star")
                                        .foregroundColor(s <= r ? appAccent : appSecondary.opacity(0.4))
                                        .font(.caption2)
                                }
                            }
                        } else {
                            Button { ratingTargetId = order.id } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "star")
                                    Text("Puan Ver")
                                }
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(appAccent)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }

                    Spacer()

                    // "Yeniden Al" — ghost/text style like the old design
                    Button {
                        Task {
                            reorderLoading = order.id
                            if let svc = await viewModel.fetchServiceForReorder(order: order) {
                                reorderService = svc; navigateToService = true
                            } else {
                                viewModel.errorMessage = "Hizmet artık mevcut değil."
                            }
                            reorderLoading = nil
                        }
                    } label: {
                        HStack(spacing: 4) {
                            if reorderLoading == order.id {
                                ProgressView().scaleEffect(0.65).tint(appPrimary)
                            } else {
                                Image(systemName: "arrow.clockwise.circle")
                                Text("Hizmeti Yeniden Al")
                            }
                        }
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(appPrimary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(reorderLoading == order.id)
                }
            }
            .padding(14)
        }
        .background(appCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(appSecondary.opacity(0.18), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        // Rating sheet
        .sheet(isPresented: Binding(
            get: { ratingTargetId == order.id },
            set: { if !$0 { ratingTargetId = nil } }
        )) { ratingSheet(orderId: order.id) }
    }


    private func inlineStatusBadge(_ status: Order.OrderStatus) -> some View {
        let (txt, color) = statusInfo(status)
        return Text(txt)
            .font(.caption2).fontWeight(.bold)
            .foregroundColor(color)
            .padding(.horizontal, 9).padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 1))
    }

    private func statusInfo(_ s: Order.OrderStatus) -> (String, Color) {
        switch s {
        case .pending:   return ("Bekliyor",    appAccent)
        case .active:    return ("Aktif",        appPrimary)
        case .completed: return ("Tamamlandı",   Color(red: 0.1, green: 0.6, blue: 0.35))
        case .cancelled: return ("İptal Edildi", Color(red: 0.8, green: 0.2, blue: 0.2))
        }
    }

    private func statusColor(_ s: Order.OrderStatus) -> Color { statusInfo(s).1 }

    // MARK: ─────────────────── FAVORITES TAB ────────────────────────────
    private var favoritesTab: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {

                // ── Favorite Providers ──────────────────────────────────
                sectionTitle("Favori Ustalarım", icon: "heart.fill", color: Color(red: 0.8, green: 0.2, blue: 0.2))

                if viewModel.favoriteProviders.isEmpty {
                    emptyRow("Henüz favori listenize kimseyi eklemediniz.")
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ForEach(viewModel.favoriteProviders) { providerCard($0) }
                    }
                    .padding(.horizontal, 16)
                }

                // ── Recently Viewed ─────────────────────────────────────
                sectionTitle("Son Görüntülenenler", icon: "eye.fill", color: appPrimary)

                if viewModel.recentlyViewed.isEmpty {
                    emptyRow("Henüz bir usta profiline bakmadınız.")
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.recentlyViewed) { recentChip($0) }
                        }
                        .padding(.horizontal, 16)
                    }
                }

                // ── Saved Searches ──────────────────────────────────────
                sectionTitle("Kayıtlı Aramalar", icon: "magnifyingglass.circle.fill", color: appAccent.opacity(0.8))

                if viewModel.savedSearches.isEmpty {
                    emptyRow("Kayıtlı arama bulunmuyor.")
                } else {
                    VStack(spacing: 0) {
                        ForEach(viewModel.savedSearches, id: \.self) { query in
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(appAccent.opacity(0.18))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "magnifyingglass")
                                        .font(.caption).foregroundColor(appPrimary)
                                }
                                Text(query)
                                    .font(.subheadline).foregroundColor(appText)
                                Spacer()
                                Button {
                                    if let i = viewModel.savedSearches.firstIndex(of: query) {
                                        viewModel.deleteSavedSearch(at: IndexSet(integer: i))
                                    }
                                } label: {
                                    Image(systemName: "trash.fill")
                                        .font(.caption)
                                        .foregroundColor(Color(red: 0.8, green: 0.2, blue: 0.2))
                                        .padding(7)
                                        .background(Color(red: 0.8, green: 0.2, blue: 0.2).opacity(0.1))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 14).padding(.vertical, 11)
                            if query != viewModel.savedSearches.last {
                                Divider().padding(.leading, 58).background(appSecondary.opacity(0.2))
                            }
                        }
                    }
                    .background(appCard)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(appSecondary.opacity(0.2), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 16)
        }
    }

    private func sectionTitle(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(appAccent.opacity(0.18)).frame(width: 28, height: 28)
                Image(systemName: icon).font(.caption2).foregroundColor(color)
            }
            Text(title)
                .font(.footnote).fontWeight(.bold).foregroundColor(appText)
            Spacer()
        }
        .padding(.horizontal, 16)
    }

    private func emptyRow(_ msg: String) -> some View {
        Text(msg)
            .font(.footnote).foregroundColor(appSecondary)
            .padding(.horizontal, 16)
    }

    // MARK: - Provider Grid Card
    private func providerCard(_ p: Provider) -> some View {
        VStack(spacing: 10) {
            ZStack(alignment: .topTrailing) {
                AvatarView(imageURLString: p.imageUrl, size: 54, isEditable: false)
                Button { viewModel.toggleFavorite(id: p.id) } label: {
                    Image(systemName: "heart.fill")
                        .font(.caption2)
                        .foregroundColor(Color(red: 0.8, green: 0.2, blue: 0.2))
                        .padding(5)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
                .buttonStyle(PlainButtonStyle())
                .offset(x: 6, y: -6)
            }

            Text(p.businessName)
                .font(.footnote).fontWeight(.bold).foregroundColor(appText)
                .multilineTextAlignment(.center).lineLimit(2)
                .frame(height: 34)

            HStack(spacing: 3) {
                Image(systemName: "star.fill").font(.caption2).foregroundColor(appAccent)
                Text(String(format: "%.1f", p.rating))
                    .font(.caption2).fontWeight(.bold).foregroundColor(appText)
            }

            Button {
                Task {
                    contactProviderLoading = p.id
                    if let svc = await viewModel.fetchFirstService(forProviderId: p.id) {
                        reorderService = svc
                        navigateToService = true
                        
                        // Let's also add it to recently viewed since they are viewing it
                        try? await FirestoreFavoritesService().addRecentlyViewed(providerId: p.id)
                    } else {
                        viewModel.errorMessage = "Uzmana ait hizmet bulunamadı."
                    }
                    contactProviderLoading = nil
                }
            } label: {
                HStack(spacing: 5) {
                    if contactProviderLoading == p.id {
                        ProgressView().scaleEffect(0.7).tint(.white)
                    } else {
                        Text("İletişime Geç")
                    }
                }
                .font(.caption2).fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.vertical, 6).frame(maxWidth: .infinity)
                .background(appPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(contactProviderLoading == p.id)
        }
        .padding(12)
        .background(appCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(appSecondary.opacity(0.2), lineWidth: 1))

        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    // MARK: - Recently Viewed Chip
    private func recentChip(_ p: Provider) -> some View {
        VStack(spacing: 6) {
            AvatarView(imageURLString: p.imageUrl, size: 48, isEditable: false)
            Text(String(p.businessName.prefix(12)))
                .font(.caption2).foregroundColor(appText).lineLimit(1)
        }
        .frame(width: 76)
        .padding(10)
        .background(appCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(appAccent.opacity(0.3), lineWidth: 1.5))
        .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
    }

    // MARK: - Rating Sheet
    @ViewBuilder
    private func ratingSheet(orderId: String) -> some View {
        if let order = viewModel.orders.first(where: { $0.id == orderId }) {
            ReviewSubmissionSheet(
                bookingId: order.id,
                serviceId: order.serviceId,
                serviceTitle: order.serviceTitle,
                providerId: order.providerId ?? order.id,
                providerName: order.providerName,
                customerId: Auth.auth().currentUser?.uid ?? "",
                customerName: "Müşteri"
            ) { rating in
                Task {
                    await viewModel.submitRating(orderId: orderId, rating: Int(rating))
                    ratingTargetId = nil
                }
            }
        } else {
            NavigationStack {
                Text("Sipariş bulunamadı.")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Kapat") { ratingTargetId = nil }
                        }
                    }
            }
        }
    }

    // MARK: - Toast
    @ViewBuilder
    private func toast(_ msg: String, isError: Bool) -> some View {
        let color = isError ? Color(red: 0.8, green: 0.2, blue: 0.2) : Color(red: 0.1, green: 0.6, blue: 0.35)
        VStack {
            Spacer()
            HStack(spacing: 10) {
                Image(systemName: isError ? "xmark.circle.fill" : "checkmark.circle.fill")
                Text(msg).font(.footnote).fontWeight(.medium)
            }
            .padding(.horizontal, 18).padding(.vertical, 13)
            .background(color)
            .foregroundColor(.white)
            .clipShape(Capsule())
            .shadow(color: color.opacity(0.4), radius: 8, x: 0, y: 4)
            .padding(.bottom, 40)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    viewModel.successMessage = nil
                    viewModel.errorMessage = nil
                }
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: viewModel.successMessage)
    }

    // MARK: - Helpers
    private func dateStr(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "dd MMM yyyy"
        return f.string(from: d)
    }

    private func badgeStyle(for status: Order.OrderStatus) -> BadgeView.BadgeStyle {
        switch status {
        case .pending:   return .warning
        case .active:    return .primary
        case .completed: return .success
        case .cancelled: return .error
        }
    }
}

#Preview {
    NavigationStack { HistoryFavoritesView() }
}
