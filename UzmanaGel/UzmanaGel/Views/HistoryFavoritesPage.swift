//
//  HistoryFavoritesPage.swift
//  UzmanaGel
//

//
//  HistoryFavoritesPage.swift
//  UzmanaGel
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - Models
struct OrderItem: Identifiable {
    let id: String
    let serviceName: String
    let providerName: String
    let providerImageURL: String?
    let date: Date
    let price: Double
    let status: OrderStatus
    var isRated: Bool

    enum OrderStatus: String {
        case completed = "Tamamlandı"
        case cancelled = "İptal Edildi"
        case pending   = "Bekliyor"

        var color: Color {
            switch self {
            case .completed: return .green
            case .cancelled: return .red
            case .pending:   return .orange
            }
        }

        var icon: String {
            switch self {
            case .completed: return "checkmark.circle.fill"
            case .cancelled: return "xmark.circle.fill"
            case .pending:   return "clock.fill"
            }
        }
    }
}

struct RecentlyViewedItem: Identifiable {
    let id: String
    let providerName: String
    let serviceName: String
    let imageURL: String?
    let viewedAt: Date
}

struct SavedSearch: Identifiable {
    let id: String
    let query: String
    let category: String?
    let savedAt: Date
}

// MARK: - Sipariş Geçmişi
struct OrderHistoryPage: View {

    @State private var orderFilter: Int = 0
    @State private var orders: [OrderItem] = []
    @State private var isLoading = true

    private let filterLabels = ["Tümü", "Tamamlandı", "İptal Edildi"]

    var filteredOrders: [OrderItem] {
        switch orderFilter {
        case 1: return orders.filter { $0.status == .completed }
        case 2: return orders.filter { $0.status == .cancelled }
        default: return orders
        }
    }

    var groupedOrders: [(String, [OrderItem])] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "MMMM yyyy"

        let grouped = Dictionary(grouping: filteredOrders) { order -> String in
            formatter.string(from: order.date)
        }
        return grouped.sorted { a, b in
            let dateA = filteredOrders.first(where: { formatter.string(from: $0.date) == a.key })?.date ?? Date()
            let dateB = filteredOrders.first(where: { formatter.string(from: $0.date) == b.key })?.date ?? Date()
            return dateA > dateB
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(0..<filterLabels.count, id: \.self) { idx in
                        Button {
                            withAnimation(.spring(response: 0.3)) { orderFilter = idx }
                        } label: {
                            Text(filterLabels[idx])
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(orderFilter == idx ? .white : Color("Text"))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(orderFilter == idx ? Color("PrimaryColor") : Color("CardBackground"))
                                .clipShape(Capsule())
                                .shadow(color: .black.opacity(0.04), radius: 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }

            if isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if filteredOrders.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                        ForEach(groupedOrders, id: \.0) { month, items in
                            Section {
                                ForEach(items) { order in
                                    orderCard(order)
                                        .padding(.horizontal, 16)
                                        .padding(.bottom, 10)
                                }
                            } header: {
                                Text(month)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 6)
                                    .background(Color("BackgroundColor"))
                            }
                        }
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 24)
                }
            }
        }
        .background(Color("BackgroundColor"))
        .navigationTitle("Sipariş Geçmişi")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadOrders() }
    }

    private func orderCard(_ order: OrderItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color("PrimaryColor").opacity(0.12))
                        .frame(width: 46, height: 46)
                    Image(systemName: "person.fill")
                        .foregroundColor(Color("PrimaryColor"))
                        .font(.system(size: 20))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(order.serviceName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color("Text"))
                        .lineLimit(1)
                    Text(order.providerName)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: order.status.icon)
                            .font(.system(size: 10))
                        Text(order.status.rawValue)
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(order.status.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(order.status.color.opacity(0.1))
                    .clipShape(Capsule())

                    Text(String(format: "₺%.0f", order.price))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color("Text"))
                }
            }

            HStack {
                Text(order.date, style: .date)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Spacer()

                HStack(spacing: 8) {
                    if order.status == .completed && !order.isRated {
                        Button { } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "star")
                                    .font(.system(size: 11))
                                Text("Değerlendir")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(Color("PrimaryColor"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color("PrimaryColor").opacity(0.1))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }

                    Button { } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11))
                            Text("Tekrarla")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(Color("Text"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(.tertiarySystemBackground))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "bag")
                .font(.system(size: 52))
                .foregroundColor(Color("PrimaryColor").opacity(0.4))
            Text("Sipariş geçmişi bulunamadı")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color("Text"))
            Text("Tamamlanan siparişleriniz burada görünecek.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    private func loadOrders() {
        guard let uid = Auth.auth().currentUser?.uid else { isLoading = false; return }
        Firestore.firestore()
            .collection("users").document(uid)
            .collection("orders")
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .getDocuments { snap, _ in
                isLoading = false
                orders = snap?.documents.compactMap { doc -> OrderItem? in
                    let d = doc.data()
                    guard let sName = d["serviceName"] as? String,
                          let pName = d["providerName"] as? String,
                          let ts = d["createdAt"] as? Timestamp,
                          let price = d["price"] as? Double,
                          let statusRaw = d["status"] as? String else { return nil }
                    return OrderItem(
                        id: doc.documentID,
                        serviceName: sName,
                        providerName: pName,
                        providerImageURL: d["providerImageURL"] as? String,
                        date: ts.dateValue(),
                        price: price,
                        status: OrderItem.OrderStatus(rawValue: statusRaw) ?? .pending,
                        isRated: d["isRated"] as? Bool ?? false
                    )
                } ?? []
            }
    }
}

// MARK: - Favori Sağlayıcılar
struct FavoriteProvidersPage: View {

    @State private var favorites: [FavoriteProvider] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView().padding(.top, 60)
            } else if favorites.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 14
                    ) {
                        ForEach(favorites) { fav in
                            favoriteCard(fav)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
        }
        .background(Color("BackgroundColor"))
        .navigationTitle("Favorilerim")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadFavorites() }
    }

    private func favoriteCard(_ fav: FavoriteProvider) -> some View {
        VStack(spacing: 10) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    Circle()
                        .fill(Color("PrimaryColor").opacity(0.12))
                        .frame(width: 68, height: 68)
                    Image(systemName: "person.fill")
                        .foregroundColor(Color("PrimaryColor"))
                        .font(.system(size: 28))
                }

                Button {
                    withAnimation { removeFavorite(fav) }
                } label: {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .frame(width: 26, height: 26)
                        .background(Color("CardBackground"))
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 4)
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 3) {
                Text(fav.name)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color("Text"))
                    .lineLimit(1)
                Text(fav.specialty)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", fav.rating))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color("Text"))
                }
            }

            Button { } label: {
                Text("İletişim")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color("PrimaryColor"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color("PrimaryColor").opacity(0.1))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "heart.slash")
                .font(.system(size: 52))
                .foregroundColor(Color("PrimaryColor").opacity(0.4))
            Text("Henüz favori yok")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color("Text"))
            Text("Beğendiğiniz uzmanları favorilere ekleyin.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    private func loadFavorites() {
        guard let uid = Auth.auth().currentUser?.uid else { isLoading = false; return }
        Firestore.firestore()
            .collection("users").document(uid)
            .collection("favorites")
            .getDocuments { snap, _ in
                isLoading = false
                favorites = snap?.documents.compactMap { doc -> FavoriteProvider? in
                    let d = doc.data()
                    guard let name = d["name"] as? String else { return nil }
                    return FavoriteProvider(
                        id: doc.documentID,
                        name: name,
                        specialty: d["specialty"] as? String ?? "Uzman",
                        rating: d["rating"] as? Double ?? 4.5,
                        imageURL: d["imageURL"] as? String
                    )
                } ?? []
            }
    }

    private func removeFavorite(_ fav: FavoriteProvider) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore()
            .collection("users").document(uid)
            .collection("favorites").document(fav.id)
            .delete()
        favorites.removeAll { $0.id == fav.id }
    }
}

// MARK: - FavoriteProvider Model
struct FavoriteProvider: Identifiable {
    let id: String
    let name: String
    let specialty: String
    let rating: Double
    let imageURL: String?
}

#Preview {
    NavigationStack { OrderHistoryPage() }
}
