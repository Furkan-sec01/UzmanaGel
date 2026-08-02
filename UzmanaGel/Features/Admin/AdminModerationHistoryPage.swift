import SwiftUI
import Combine
import FirebaseFirestore

private enum AdminModerationHistoryAction {
    case dismissed
    case removed

    var title: String {
        switch self {
        case .dismissed:
            return "Rapor Reddedildi"
        case .removed:
            return "Yorum Kaldırıldı"
        }
    }

    var systemImage: String {
        switch self {
        case .dismissed:
            return "xmark.shield.fill"
        case .removed:
            return "trash.fill"
        }
    }

    var tint: Color {
        switch self {
        case .dismissed:
            return .orange
        case .removed:
            return .red
        }
    }
}

private struct AdminModerationHistoryItem: Identifiable {
    let id: String
    let action: AdminModerationHistoryAction
    let reviewId: String
    let category: String
    let comment: String
    let userName: String
    let note: String
    let date: Date?
    let adminId: String
}

@MainActor
private final class AdminModerationHistoryViewModel:
    ObservableObject {

    @Published private(set) var items:
        [AdminModerationHistoryItem] = []

    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    func loadHistory() async {
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            let dismissedSnapshot = try await db
                .collection("review_report_archive")
                .order(
                    by: "archivedAt",
                    descending: true
                )
                .limit(to: 50)
                .getDocuments()

            let removedSnapshot = try await db
                .collection("review_moderation_archive")
                .order(
                    by: "removedAt",
                    descending: true
                )
                .limit(to: 50)
                .getDocuments()

            let dismissedItems = dismissedSnapshot.documents.map {
                document in

                let data = document.data()

                return AdminModerationHistoryItem(
                    id: "dismissed-\(document.documentID)",
                    action: .dismissed,
                    reviewId: data["reviewId"] as? String ?? "",
                    category: data["category"] as? String
                        ?? "Diğer",
                    comment: "",
                    userName: data["reporterId"] as? String
                        ?? "Bilinmeyen kullanıcı",
                    note: data["resolutionNote"] as? String
                        ?? "",
                    date: (
                        data["archivedAt"] as? Timestamp
                    )?.dateValue(),
                    adminId: data["resolvedBy"] as? String
                        ?? ""
                )
            }

            let removedItems = removedSnapshot.documents.map {
                document in

                let data = document.data()

                return AdminModerationHistoryItem(
                    id: "removed-\(document.documentID)",
                    action: .removed,
                    reviewId: data["originalReviewId"] as? String
                        ?? document.documentID,
                    category: "",
                    comment: data["comment"] as? String ?? "",
                    userName: data["customerName"] as? String
                        ?? "Bilinmeyen kullanıcı",
                    note: data["resolutionNote"] as? String
                        ?? "",
                    date: (
                        data["removedAt"] as? Timestamp
                    )?.dateValue(),
                    adminId: data["removedBy"] as? String
                        ?? ""
                )
            }

            items = (dismissedItems + removedItems).sorted {
                ($0.date ?? .distantPast)
                    > ($1.date ?? .distantPast)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct AdminModerationHistoryPage: View {

    @EnvironmentObject private var session: SessionViewModel

    @StateObject private var viewModel =
        AdminModerationHistoryViewModel()

    private let backgroundColor = Color("BackgroundColor")
    private let cardColor = Color("CardBackground")

    var body: some View {
        Group {
            if !session.isAdmin {
                ContentUnavailableView(
                    "Yetkisiz Erişim",
                    systemImage: "lock.shield"
                )
            } else if viewModel.isLoading &&
                        viewModel.items.isEmpty {
                ProgressView("Geçmiş yükleniyor...")
            } else if let errorMessage = viewModel.errorMessage,
                      viewModel.items.isEmpty {
                ContentUnavailableView(
                    "Geçmiş yüklenemedi",
                    systemImage: "exclamationmark.triangle",
                    description: Text(errorMessage)
                )
            } else if viewModel.items.isEmpty {
                emptyState
            } else {
                historyList
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .background(backgroundColor.ignoresSafeArea())
        .navigationTitle("Moderasyon Geçmişi")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color("PrimaryColor"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task(id: session.isAdmin) {
            guard session.isAdmin else {
                return
            }

            await viewModel.loadHistory()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.18), Color.pink.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 110, height: 110)

                Circle()
                    .stroke(Color.purple.opacity(0.2), lineWidth: 1.5)
                    .frame(width: 126, height: 126)

                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("Moderasyon Geçmişi Yok")
                    .font(.title3.bold())
                    .foregroundStyle(.primary)

                Text("Tamamlanan yorum moderasyon işlemleri burada görüntülenecektir.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                Task {
                    await viewModel.loadHistory()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .bold))
                    Text("Yenile")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(Color("PrimaryColor"))
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Color("PrimaryColor").opacity(0.1))
                .clipShape(Capsule())
            }
            .padding(.top, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var historyList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 14) {
                ForEach(viewModel.items) { item in
                    historyCard(item)
                }
            }
            .padding(16)
        }
        .refreshable {
            await viewModel.loadHistory()
        }
    }

    private func historyCard(_ item: AdminModerationHistoryItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                HStack(spacing: 6) {
                    Image(systemName: item.action.systemImage)
                        .font(.system(size: 13, weight: .bold))
                    Text(item.action.title)
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(item.action.tint)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(item.action.tint.opacity(0.12))
                .clipShape(Capsule())

                Spacer()

                if let date = item.date {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11))
                        Text(formatTurkishDate(date))
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(.secondary)
                }
            }

            if !item.category.isEmpty {
                HStack(spacing: 6) {
                    Text("Kategori:")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.primary)

                    Text(item.category)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color("PrimaryColor"))
                }
            }

            if !item.comment.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("YORUM İÇERİĞİ")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)

                    Text("“\(item.comment)”")
                        .font(.system(size: 13))
                        .italic()
                        .foregroundStyle(.primary)
                }
                .padding(10)
                .background(Color.primary.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)

                    Text("Kullanıcı:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)

                    Text(formatIdentifier(item.userName))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)
                }

                HStack(spacing: 6) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)

                    Text("Yorum ID:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)

                    Text(formatIdentifier(item.reviewId))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)
                }
            }

            if !item.note.isEmpty {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(item.action.tint)
                        .frame(width: 3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Admin Notu")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(item.action.tint)

                        Text(item.note)
                            .font(.system(size: 12))
                            .foregroundStyle(.primary)
                    }
                }
                .padding(8)
                .background(item.action.tint.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .padding(16)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }

    private func formatIdentifier(_ raw: String) -> String {
        if raw.count > 16 {
            let prefix = raw.prefix(8)
            let suffix = raw.suffix(6)
            return "\(prefix)...\(suffix)"
        }
        return raw
    }

    private func formatTurkishDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMM yyyy, HH:mm"
        return formatter.string(from: date)
    }
}
