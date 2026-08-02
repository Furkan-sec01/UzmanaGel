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
        .toolbarBackground(Color("PrimaryColor"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
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
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
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
                            .font(.system(size: 14, weight: .bold))
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(Color("PrimaryColor"))
                    .disabled(viewModel.isLoadingMore)
                }
            }
            .padding(16)
        }
    }

    private func historyCard(
        _ record: AdminProviderApplicationHistoryRecord
    ) -> some View {
        let style = actionStyle(record.action)

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(style.color.opacity(0.12))
                        .frame(width: 44, height: 44)

                    Image(systemName: style.icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(style.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(record.providerName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.primary)

                    if !record.businessName.isEmpty {
                        Text(record.businessName)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                HStack(spacing: 5) {
                    Circle()
                        .fill(style.color)
                        .frame(width: 6, height: 6)

                    Text(style.title)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(style.color)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(style.color.opacity(0.12))
                .clipShape(Capsule())
            }

            // Status transition pill box
            HStack(spacing: 12) {
                statusPill(title: "Önceki", status: record.previousStatus)

                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.secondary.opacity(0.6))

                statusPill(title: "Yeni", status: record.status)
            }
            .padding(12)
            .background(Color.primary.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            if !record.adminNote.isEmpty {
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color("PrimaryColor"))
                        .frame(width: 3)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Admin Açıklaması")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color("PrimaryColor"))

                        Text(record.adminNote)
                            .font(.system(size: 13))
                            .foregroundStyle(.primary)
                    }
                }
                .padding(10)
                .background(Color("PrimaryColor").opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            Divider()

            HStack(alignment: .center) {
                HStack(spacing: 6) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.secondary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("İşlemi yapan")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)

                        Text(record.adminName)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.primary)
                    }
                }

                Spacer()

                if let reviewedAt = record.reviewedAt {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11))
                        Text(formatTurkishDate(reviewedAt))
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(.secondary)
                }
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

    private func statusPill(title: String, status: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)

            Text(statusTitle(status))
                .font(.system(size: 13, weight: .bold))
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

    private func formatTurkishDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMM yyyy, HH:mm"
        return formatter.string(from: date)
    }
}
