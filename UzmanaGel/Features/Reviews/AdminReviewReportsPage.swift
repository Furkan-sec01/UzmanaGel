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
            return "Rapor reddedilsin mi?".localized
        case .flag:
            return "Yorum incelemeye alınsın mı?".localized
        case .remove:
            return "Yorum kaldırılsın mı?".localized
        }
    }

    var confirmationTitle: String {
        switch self {
        case .dismiss:
            return "Raporu Reddet".localized
        case .flag:
            return "İncelemeye Al".localized
        case .remove:
            return "Yorumu Kaldır".localized
        }
    }

    var message: String {
        switch self {
        case .dismiss:
            return "Rapor kapatılacak ancak yorum yayında kalacak.".localized
        case .flag:
            return "Rapor ileri inceleme kuyruğuna taşınacak.".localized
        case .remove:
            return "Yorum yayından kaldırılacak ve moderasyon arşivine kaydedilecek.".localized
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
        .navigationTitle("Bildirilen Yorumlar".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color("PrimaryColor"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
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
            "İşlem Başarısız".localized,
            isPresented: operationErrorBinding
        ) {
            Button("Tamam".localized, role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(
                viewModel.errorMessage
                    ?? "Bilinmeyen bir hata oluştu.".localized
            )
        }
    }

    private var adminContent: some View {
        VStack(spacing: 0) {
            Picker(
                "Rapor durumu".localized,
                selection: $selectedStatus
            ) {
                Text("Bekleyen".localized)
                    .tag("pending")

                Text("İncelemede".localized)
                    .tag("flagged")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Group {
                if viewModel.isLoading &&
                    viewModel.reports.isEmpty {
                    ProgressView("Bildirimler yükleniyor...".localized)
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity
                        )
                } else if let errorMessage =
                            viewModel.errorMessage,
                          viewModel.reports.isEmpty {
                    errorView(message: errorMessage)
                } else if viewModel.reports.isEmpty {
                    emptyState
                } else {
                    reportsList
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.green.opacity(0.18), Color.teal.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 110, height: 110)

                Circle()
                    .stroke(Color.green.opacity(0.2), lineWidth: 1.5)
                    .frame(width: 126, height: 126)

                Image(systemName: selectedStatus == "pending" ? "shield.checkmark.fill" : "person.badge.shield.checkmark.fill")
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .teal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Text(selectedStatus == "pending" ? "Bekleyen Bildirim Yok".localized : "İncelemede Yorum Yok".localized)
                        .font(.title3.bold())
                        .foregroundStyle(.primary)

                    Text("0")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.green.opacity(0.12))
                        .clipShape(Capsule())
                }

                Text(
                    selectedStatus == "pending"
                        ? "İncelenmesi gereken yeni bir yorum bildirimi bulunmuyor.".localized
                        : "İleri incelemeye alınmış bir yorum bulunmuyor.".localized
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            }

            Button {
                Task {
                    await viewModel.loadReports(status: selectedStatus)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .bold))
                    Text("Yenile".localized)
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

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.red)

                    Text(report.category)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.red)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.red.opacity(0.1))
                .clipShape(Capsule())

                Spacer()

                HStack(spacing: 5) {
                    Circle()
                        .fill(isFlagged ? Color.purple : Color.orange)
                        .frame(width: 6, height: 6)

                    Text(isFlagged ? "İncelemede" : "Bekliyor")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(isFlagged ? Color.purple : Color.orange)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background((isFlagged ? Color.purple : Color.orange).opacity(0.12))
                .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("BİLDİRİM NEDENİ")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)

                Text(
                    report.description.isEmpty
                        ? "Açıklama belirtilmedi."
                        : report.description
                )
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    HStack(spacing: 5) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color("PrimaryColor"))

                        Text(report.customerName)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.primary)
                    }

                    Spacer()

                    if let rating = report.rating {
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(.orange)
                            Text(String(format: "%.1f", rating))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.primary)
                        }
                    }
                }

                Text("“\(report.reviewComment)”")
                    .font(.system(size: 13, weight: .regular))
                    .italic()
                    .foregroundStyle(.secondary)

                if let createdAt = report.createdAt {
                    HStack {
                        Spacer()
                        Text(formatTurkishDate(createdAt))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color.primary.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

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
                            .font(.system(size: 14, weight: .bold))
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
                            .font(.system(size: 13, weight: .semibold))
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
                            .font(.system(size: 13, weight: .bold))
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
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

    private func formatTurkishDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMM yyyy, HH:mm"
        return formatter.string(from: date)
    }
}
