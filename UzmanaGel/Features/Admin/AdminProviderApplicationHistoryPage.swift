//
//  AdminProviderApplicationHistoryPage.swift
//  UzmanaGel
//
//  Created by Halil Keremoğlu on 27.07.2026.
//

import SwiftUI
import Combine
import FirebaseFirestore


struct AdminProviderApplicationHistoryRecord: Identifiable {

    let id: String
    let providerId: String
    let providerName: String
    let businessName: String
    let action: String
    let previousStatus: String
    let status: String
    let adminNote: String
    let reviewedAt: Date?
    let reviewedBy: String
    let adminName: String
}

@MainActor
final class AdminProviderApplicationHistoryViewModel: ObservableObject {

    @Published private(set) var records:
        [AdminProviderApplicationHistoryRecord] = []

    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasMore = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private let pageSize = 20
    private var lastDocument: DocumentSnapshot?

    func loadHistory() async {
        guard !isLoading else {
            return
        }

        isLoading = true
        errorMessage = nil
        records = []
        lastDocument = nil
        hasMore = false

        defer {
            isLoading = false
        }

        do {
            let page = try await fetchPage(after: nil)

            records = page.records
            lastDocument = page.lastDocument
            hasMore = page.documentCount == pageSize
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadMoreHistory() async {
        guard
            !isLoading,
            !isLoadingMore,
            hasMore,
            let lastDocument
        else {
            return
        }

        isLoadingMore = true
        errorMessage = nil

        defer {
            isLoadingMore = false
        }

        do {
            let page = try await fetchPage(after: lastDocument)
            let existingIds = Set(records.map(\.id))

            records.append(
                contentsOf: page.records.filter {
                    !existingIds.contains($0.id)
                }
            )

            self.lastDocument = page.lastDocument
            hasMore = page.documentCount == pageSize
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearError() {
        errorMessage = nil
    }

    private func fetchPage(
        after document: DocumentSnapshot?
    ) async throws -> (
        records: [AdminProviderApplicationHistoryRecord],
        lastDocument: DocumentSnapshot?,
        documentCount: Int
    ) {
        var query: Query = db
            .collection("provider_application_history")
            .order(
                by: "reviewedAt",
                descending: true
            )
            .limit(to: pageSize)

        if let document {
            query = query.start(afterDocument: document)
        }

        let snapshot = try await query.getDocuments()

        let providerIds = snapshot.documents.compactMap {
            cleanString($0.data()["providerId"])
        }

        let adminIds = snapshot.documents.compactMap {
            cleanString($0.data()["reviewedBy"])
        }

        async let providersById = fetchDocuments(
            collection: "service_providers",
            ids: providerIds
        )

        async let adminsById = fetchDocuments(
            collection: "users",
            ids: adminIds
        )

        let providerDocuments = try await providersById
        let adminDocuments = try await adminsById

        let loadedRecords = snapshot.documents.compactMap {
            document -> AdminProviderApplicationHistoryRecord? in

            let data = document.data()

            guard let providerId = cleanString(data["providerId"]) else {
                return nil
            }

            let providerData = providerDocuments[providerId]
            let providerName =
                cleanString(providerData?["displayName"])
                ?? "Bilinmeyen uzman"

            let businessName =
                cleanString(providerData?["businessName"])
                ?? ""

            let reviewedBy =
                cleanString(data["reviewedBy"])
                ?? ""

            let adminData = adminDocuments[reviewedBy]
            let adminName =
                cleanString(adminData?["displayName"])
                ?? cleanString(adminData?["email"])
                ?? (reviewedBy.isEmpty
                    ? "Bilinmeyen admin"
                    : reviewedBy)

            return AdminProviderApplicationHistoryRecord(
                id: document.documentID,
                providerId: providerId,
                providerName: providerName,
                businessName: businessName,
                action: cleanString(data["action"]) ?? "",
                previousStatus:
                    cleanString(data["previousStatus"]) ?? "",
                status: cleanString(data["status"]) ?? "",
                adminNote: cleanString(data["adminNote"]) ?? "",
                reviewedAt:
                    (data["reviewedAt"] as? Timestamp)?.dateValue(),
                reviewedBy: reviewedBy,
                adminName: adminName
            )
        }

        return (
            records: loadedRecords,
            lastDocument: snapshot.documents.last,
            documentCount: snapshot.documents.count
        )
    }

    private func fetchDocuments(
        collection: String,
        ids: [String]
    ) async throws -> [String: [String: Any]] {
        let uniqueIds = Array(Set(ids)).filter {
            !$0.isEmpty
        }

        guard !uniqueIds.isEmpty else {
            return [:]
        }

        var documentsById: [String: [String: Any]] = [:]
        var startIndex = 0

        while startIndex < uniqueIds.count {
            let endIndex = min(
                startIndex + 10,
                uniqueIds.count
            )

            let chunk = Array(
                uniqueIds[startIndex..<endIndex]
            )

            let snapshot = try await db
                .collection(collection)
                .whereField(
                    FieldPath.documentID(),
                    in: chunk
                )
                .getDocuments()

            snapshot.documents.forEach {
                documentsById[$0.documentID] = $0.data()
            }

            startIndex = endIndex
        }

        return documentsById
    }

    private func cleanString(_ value: Any?) -> String? {
        guard let value = value as? String else {
            return nil
        }

        let cleanValue = value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return cleanValue.isEmpty ? nil : cleanValue
    }
}


struct AdminProviderApplicationHistoryPage: View {

    @EnvironmentObject private var session: SessionViewModel

    @StateObject private var viewModel =
        AdminProviderApplicationHistoryViewModel()

    private let backgroundColor = Color("BackgroundColor")
    private let cardColor = Color("CardBackground")

    var body: some View {
        Group {
            if !session.isAdmin {
                ContentUnavailableView(
                    "Yetkisiz Erişim",
                    systemImage: "lock.shield",
                    description: Text(
                        "Bu ekran yalnızca yöneticiler tarafından kullanılabilir."
                    )
                )
            } else {
                adminContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColor.ignoresSafeArea())
        .navigationTitle("Başvuru Geçmişi")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: session.isAdmin) {
            guard session.isAdmin else {
                return
            }

            await viewModel.loadHistory()
        }
        .alert(
            "Geçmiş Yüklenemedi",
            isPresented: operationErrorBinding
        ) {
            Button("Tamam", role: .cancel) {
                viewModel.clearError()
            }
        } message: {
            Text(
                viewModel.errorMessage
                    ?? "Bilinmeyen bir hata oluştu."
            )
        }
        }

        

    @ViewBuilder
    private var adminContent: some View {
        if viewModel.isLoading && viewModel.records.isEmpty {
            ProgressView("Başvuru geçmişi yükleniyor...")
        } else if let errorMessage = viewModel.errorMessage,
                  viewModel.records.isEmpty {
            errorState(message: errorMessage)
        } else if viewModel.records.isEmpty {
            emptyState
        } else {
            historyList
        }
    }

    private var historyList: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(viewModel.records) { record in
                    historyCard(record)
                }

                if viewModel.hasMore {
                    Button {
                        Task {
                            await viewModel.loadMoreHistory()
                        }
                    } label: {
                        if viewModel.isLoadingMore {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Label(
                                "Daha Fazla Yükle",
                                systemImage: "arrow.down.circle"
                            )
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isLoadingMore)
                }
            }
            .padding(16)
        }
        .refreshable {
            await viewModel.loadHistory()
        }
    }

    private func historyCard(
        _ record: AdminProviderApplicationHistoryRecord
    ) -> some View {
        let style = actionStyle(record.action)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: style.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(style.color)
                    .frame(width: 42, height: 42)
                    .background(style.color.opacity(0.14))
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 12,
                            style: .continuous
                        )
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(record.providerName)
                        .font(.headline)

                    if !record.businessName.isEmpty {
                        Text(record.businessName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Text(style.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(style.color)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(style.color.opacity(0.14))
                    .clipShape(Capsule())
            }

            Divider()

            HStack {
                statusLabel(
                    title: "Önceki",
                    value: statusTitle(record.previousStatus)
                )

                Image(systemName: "arrow.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                statusLabel(
                    title: "Yeni",
                    value: statusTitle(record.status)
                )
            }

            if !record.adminNote.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Admin açıklaması")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(record.adminNote)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
            }

            Divider()

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("İşlemi yapan")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(record.adminName)
                        .font(.subheadline.weight(.medium))
                }

                Spacer()

                if let reviewedAt = record.reviewedAt {
                    Text(
                        reviewedAt.formatted(
                            date: .abbreviated,
                            time: .shortened
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(cardColor)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
            .stroke(Color.primary.opacity(0.08))
        }
    }

    private func statusLabel(
        title: String,
        value: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func actionStyle(
        _ action: String
    ) -> (
        title: String,
        icon: String,
        color: Color
    ) {
        switch action {
        case "approve":
            return (
                "Onaylandı",
                "checkmark.shield.fill",
                .green
            )

        case "reject":
            return (
                "Reddedildi",
                "xmark.shield.fill",
                .red
            )

        case "requestDocuments":
            return (
                "Eksik Belge",
                "doc.badge.ellipsis",
                .orange
            )

        default:
            return (
                "İşlem",
                "clock.arrow.circlepath",
                .secondary
            )
        }
    }

    private func statusTitle(_ status: String) -> String {
        switch status.lowercased() {
        case "draft":
            return "Taslak"

        case "pending":
            return "Bekliyor"

        case "approved":
            return "Onaylandı"

        case "rejected":
            return "Reddedildi"

        case "documentsrequired":
            return "Eksik Belge"

        default:
            return status.isEmpty ? "Belirtilmemiş" : status
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "Başvuru Geçmişi Yok",
            systemImage: "clock.arrow.circlepath",
            description: Text(
                "Tamamlanan uzman başvuru kararları burada görünecek."
            )
        )
    }

    private func errorState(message: String) -> some View {
        ContentUnavailableView {
            Label(
                "Geçmiş Yüklenemedi",
                systemImage: "exclamationmark.triangle.fill"
            )
        } description: {
            Text(message)
        } actions: {
            Button("Tekrar Dene") {
                Task {
                    await viewModel.loadHistory()
                }
            }
        }
    }

    private var operationErrorBinding: Binding<Bool> {
        Binding(
            get: {
                viewModel.errorMessage != nil &&
                    !viewModel.records.isEmpty
            },
            set: { isPresented in
                if !isPresented {
                    viewModel.clearError()
                }
            }
        )
    }
}
