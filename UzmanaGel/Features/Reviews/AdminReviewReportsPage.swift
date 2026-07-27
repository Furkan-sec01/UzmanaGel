import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseFunctions

struct AdminReviewReport: Identifiable {
    let id: String
    let reviewId: String
    let providerId: String
    let category: String
    let description: String
    let reporterId: String
    let status: String
    let createdAt: Date?
    let reviewComment: String
    let customerName: String
    let rating: Double?
}

private enum AdminModerationAction {
    case dismiss
    case flag
    case remove

    var backendValue: String {
        switch self {
        case .dismiss:
            return "dismiss"
        case .flag:
            return "flag"
        case .remove:
            return "remove"
        }
    }

    var dialogTitle: String {
        switch self {
        case .dismiss:
            return "Rapor reddedilsin mi?"
        case .flag:
            return "Yorum incelemeye alınsın mı?"
        case .remove:
            return "Yorum kaldırılsın mı?"
        }
    }

    var confirmationTitle: String {
        switch self {
        case .dismiss:
            return "Raporu Reddet"
        case .flag:
            return "İncelemeye Al"
        case .remove:
            return "Yorumu Kaldır"
        }
    }

    var message: String {
        switch self {
        case .dismiss:
            return "Rapor kapatılacak ancak yorum yayında kalacak."
        case .flag:
            return "Rapor ileri inceleme kuyruğuna taşınacak."
        case .remove:
            return "Yorum yayından kaldırılacak ve moderasyon arşivine kaydedilecek."
        }
    }
}

@MainActor
final class AdminReviewReportsViewModel: ObservableObject {

    @Published private(set) var reports: [AdminReviewReport] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasMore = false
    @Published private(set) var processingReportId: String?
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private let functions = Functions.functions(
        region: "europe-west1"
    )

    private let pageSize = 20
    private var lastDocument: DocumentSnapshot?

    func loadReports(status: String) async {
        guard !isLoading else {
            return
        }

        isLoading = true
        errorMessage = nil
        reports = []
        lastDocument = nil
        hasMore = false

        defer {
            isLoading = false
        }

        do {
            let page = try await fetchPage(
                status: status,
                after: nil
            )

            reports = page.reports
            lastDocument = page.lastDocument
            hasMore = page.documentCount == pageSize
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadMoreReports(status: String) async {
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
            let page = try await fetchPage(
                status: status,
                after: lastDocument
            )

            let existingIds = Set(reports.map(\.id))

            reports.append(
                contentsOf: page.reports.filter {
                    !existingIds.contains($0.id)
                }
            )

            self.lastDocument = page.lastDocument
            hasMore = page.documentCount == pageSize
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func fetchPage(
        status: String,
        after document: DocumentSnapshot?
    ) async throws -> (
        reports: [AdminReviewReport],
        lastDocument: DocumentSnapshot?,
        documentCount: Int
    ) {
        var query: Query = db
            .collection("review_reports")
            .whereField("status", isEqualTo: status)
            .order(
                by: "createdAt",
                descending: true
            )
            .limit(to: pageSize)

        if let document {
            query = query.start(afterDocument: document)
        }

        let snapshot = try await query.getDocuments()

        let reviewIds = snapshot.documents.compactMap {
            $0.data()["reviewId"] as? String
        }

        let reviewsById = try await fetchReviews(
            reviewIds: reviewIds
        )

        let loadedReports = snapshot.documents.compactMap {
            document -> AdminReviewReport? in

            let data = document.data()

            guard let reviewId = data["reviewId"] as? String else {
                return nil
            }

            let reviewData = reviewsById[reviewId]

            return AdminReviewReport(
                id: document.documentID,
                reviewId: reviewId,
                providerId: data["providerId"] as? String ?? "",
                category: data["category"] as? String ?? "Diğer",
                description: data["description"] as? String ?? "",
                reporterId: data["reporterId"] as? String ?? "",
                status: data["status"] as? String ?? status,
                createdAt: (
                    data["createdAt"] as? Timestamp
                )?.dateValue(),
                reviewComment: reviewData?["comment"] as? String
                    ?? "Yorum bulunamadı.",
                customerName: reviewData?["customerName"] as? String
                    ?? "Bilinmeyen kullanıcı",
                rating: (
                    reviewData?["rating"] as? NSNumber
                )?.doubleValue
            )
        }

        return (
            reports: loadedReports,
            lastDocument: snapshot.documents.last,
            documentCount: snapshot.documents.count
        )
    }

    private func fetchReviews(
        reviewIds: [String]
    ) async throws -> [String: [String: Any]] {
        let uniqueIds = Array(Set(reviewIds))

        guard !uniqueIds.isEmpty else {
            return [:]
        }

        var reviewsById: [String: [String: Any]] = [:]
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
                .collection("reviews")
                .whereField(
                    FieldPath.documentID(),
                    in: chunk
                )
                .getDocuments()

            snapshot.documents.forEach {
                reviewsById[$0.documentID] = $0.data()
            }

            startIndex = endIndex
        }

        return reviewsById
    }

    fileprivate func moderateReport(
        _ report: AdminReviewReport,
        action: AdminModerationAction
    ) async {
        guard processingReportId == nil else {
            return
        }

        processingReportId = report.id
        errorMessage = nil

        defer {
            processingReportId = nil
        }

        do {
            let callable = functions.httpsCallable(
                "moderateReviewReport"
            )

            _ = try await callable.call([
                "reportId": report.id,
                "action": action.backendValue,
                "resolutionNote": ""
            ])

            switch action {
            case .dismiss, .flag:
                reports.removeAll {
                    $0.id == report.id
                }

            case .remove:
                reports.removeAll {
                    $0.reviewId == report.reviewId
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct AdminReviewReportsPage: View {

    @EnvironmentObject private var session: SessionViewModel

    @StateObject private var viewModel =
        AdminReviewReportsViewModel()

    @State private var selectedReport: AdminReviewReport?
    @State private var selectedAction: AdminModerationAction?
    @State private var showConfirmation = false
    @State private var selectedStatus = "pending"

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
        .background(backgroundColor.ignoresSafeArea())
        .navigationTitle("Bildirilen Yorumlar")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: "\(session.isAdmin)-\(selectedStatus)") {
            guard session.isAdmin else {
                return
            }

            await viewModel.loadReports(
                status: selectedStatus
            )
        }
        .confirmationDialog(
            selectedAction?.dialogTitle ?? "",
            isPresented: $showConfirmation,
            titleVisibility: .visible
        ) {
            confirmationButtons
        } message: {
            Text(selectedAction?.message ?? "")
        }
        .alert(
            "İşlem Başarısız",
            isPresented: operationErrorBinding
        ) {
            Button("Tamam", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(
                viewModel.errorMessage
                    ?? "Bilinmeyen bir hata oluştu."
            )
        }
    }

    private var adminContent: some View {
        VStack(spacing: 0) {
            Picker(
                "Rapor durumu",
                selection: $selectedStatus
            ) {
                Text("Bekleyen")
                    .tag("pending")

                Text("İncelemede")
                    .tag("flagged")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 6)

            Group {
                if viewModel.isLoading &&
                    viewModel.reports.isEmpty {
                    ProgressView("Bildirimler yükleniyor...")
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity
                        )
                } else if let errorMessage =
                            viewModel.errorMessage,
                          viewModel.reports.isEmpty {
                    errorView(message: errorMessage)
                } else if viewModel.reports.isEmpty {
                    ContentUnavailableView(
                        selectedStatus == "pending"
                            ? "Bekleyen Bildirim Yok"
                            : "İncelemede Yorum Yok",
                        systemImage: "checkmark.shield",
                        description: Text(
                            selectedStatus == "pending"
                                ? "İncelenmesi gereken yeni bir yorum bildirimi bulunmuyor."
                                : "İleri incelemeye alınmış bir yorum bulunmuyor."
                        )
                    )
                } else {
                    reportsList
                }
            }
        }
    }

    private var reportsList: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(viewModel.reports) { report in
                    reportCard(report)
                }

                if viewModel.hasMore {
                    Button {
                        Task {
                            await viewModel.loadMoreReports(
                                status: selectedStatus
                            )
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
            await viewModel.loadReports(
                status: selectedStatus
            )
        }
    }

    @ViewBuilder
    private var confirmationButtons: some View {
        if let report = selectedReport,
           let action = selectedAction {
            switch action {
            case .dismiss:
                Button("Raporu Reddet") {
                    runModeration(
                        report: report,
                        action: action
                    )
                }

            case .flag:
                Button("İncelemeye Al") {
                    runModeration(
                        report: report,
                        action: action
                    )
                }

            case .remove:
                Button(
                    "Yorumu Kaldır",
                    role: .destructive
                ) {
                    runModeration(
                        report: report,
                        action: action
                    )
                }
            }
        }

        Button("Vazgeç", role: .cancel) {}
    }

    private var operationErrorBinding: Binding<Bool> {
        Binding(
            get: {
                viewModel.errorMessage != nil &&
                !viewModel.reports.isEmpty
            },
            set: { isPresented in
                if !isPresented {
                    viewModel.errorMessage = nil
                }
            }
        )
    }

    private func reportCard(
        _ report: AdminReviewReport
    ) -> some View {
        let isProcessing =
            viewModel.processingReportId == report.id
        let isFlagged = report.status == "flagged"

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(
                    report.category,
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.red)

                Spacer()

                Text(
                    isFlagged
                        ? "İncelemede"
                        : "Bekliyor"
                )
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(
                    isFlagged ? Color.purple : Color.orange
                )
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    (isFlagged ? Color.purple : Color.orange)
                        .opacity(0.14)
                )
                .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("Bildirim açıklaması")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(
                    report.description.isEmpty
                        ? "Açıklama belirtilmedi."
                        : report.description
                )
                .font(.system(size: 14, weight: .medium))
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(report.customerName)
                        .font(.system(size: 14, weight: .semibold))

                    Spacer()

                    if let rating = report.rating {
                        Label(
                            String(format: "%.1f", rating),
                            systemImage: "star.fill"
                        )
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.orange)
                    }
                }

                Text(report.reviewComment)
                    .font(.system(size: 14))
                    .foregroundStyle(.primary)
            }

            if let createdAt = report.createdAt {
                Text(
                    createdAt.formatted(
                        date: .abbreviated,
                        time: .shortened
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Divider()

            if isProcessing {
                HStack {
                    Spacer()

                    ProgressView()
                        .controlSize(.small)

                    Text("İşlem yapılıyor...")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)

                    Spacer()
                }
                .frame(minHeight: 38)
            } else {
                VStack(spacing: 10) {
                    if !isFlagged {
                        Button {
                            prepareModeration(
                                report: report,
                                action: .flag
                            )
                        } label: {
                            Label(
                                "İncelemeye Al",
                                systemImage: "flag.fill"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                    }

                    HStack(spacing: 10) {
                        Button {
                            prepareModeration(
                                report: report,
                                action: .dismiss
                            )
                        } label: {
                            Label(
                                "Raporu Reddet",
                                systemImage: "xmark.circle"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button(role: .destructive) {
                            prepareModeration(
                                report: report,
                                action: .remove
                            )
                        } label: {
                            Label(
                                "Yorumu Kaldır",
                                systemImage: "trash"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .font(.system(size: 13, weight: .semibold))
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
        .disabled(viewModel.processingReportId != nil)
    }

    private func prepareModeration(
        report: AdminReviewReport,
        action: AdminModerationAction
    ) {
        selectedReport = report
        selectedAction = action
        showConfirmation = true
    }

    private func runModeration(
        report: AdminReviewReport,
        action: AdminModerationAction
    ) {
        selectedReport = nil
        selectedAction = nil

        Task {
            await viewModel.moderateReport(
                report,
                action: action
            )
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundStyle(.orange)

            Text("Bildirimler yüklenemedi")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Tekrar Dene") {
                Task {
                    await viewModel.loadReports(
                        status: selectedStatus
                    )
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
    }
}
