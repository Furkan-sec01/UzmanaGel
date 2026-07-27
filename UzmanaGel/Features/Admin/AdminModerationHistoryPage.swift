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
                ContentUnavailableView(
                    "Moderasyon Geçmişi Yok",
                    systemImage: "clock.arrow.circlepath"
                )
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
        .task(id: session.isAdmin) {
            guard session.isAdmin else {
                return
            }

            await viewModel.loadHistory()
        }
    }

    private var historyList: some View {
        ScrollView {
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

    private func historyCard(
        _ item: AdminModerationHistoryItem
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(
                    item.action.title,
                    systemImage: item.action.systemImage
                )
                .font(.headline)
                .foregroundStyle(item.action.tint)

                Spacer()

                if let date = item.date {
                    Text(
                        date.formatted(
                            date: .abbreviated,
                            time: .shortened
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }

            if !item.category.isEmpty {
                Text("Kategori: \(item.category)")
                    .font(.subheadline.weight(.semibold))
            }

            if !item.comment.isEmpty {
                Text(item.comment)
                    .font(.subheadline)
            }

            Text("Kullanıcı: \(item.userName)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Yorum ID: \(item.reviewId)")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)

            if !item.note.isEmpty {
                Text("Admin notu: \(item.note)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(cardColor)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
            .stroke(Color.primary.opacity(0.08))
        }
    }
}
