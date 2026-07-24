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
    let createdAt: Date?
    let reviewComment: String
    let customerName: String
    let rating: Double?
}

private enum AdminModerationAction {
    case dismiss
    case remove

    var backendValue: String {
        switch self {
        case .dismiss:
            return "dismiss"
        case .remove:
            return "remove"
        }
    }

    var dialogTitle: String {
        switch self {
        case .dismiss:
            return "Rapor reddedilsin mi?"
        case .remove:
            return "Yorum kaldırılsın mı?"
        }
    }

    var confirmationTitle: String {
        switch self {
        case .dismiss:
            return "Raporu Reddet"
        case .remove:
            return "Yorumu Kaldır"
        }
    }

    var message: String {
        switch self {
        case .dismiss:
            return "Rapor kapatılacak ancak yorum yayında kalacak."
        case .remove:
            return "Yorum yayından kaldırılacak ve moderasyon arşivine kaydedilecek."
        }
    }
}

@MainActor
final class AdminReviewReportsViewModel: ObservableObject {

    @Published private(set) var reports: [AdminReviewReport] = []
    @Published private(set) var isLoading = false
    @Published private(set) var processingReportId: String?
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private let functions = Functions.functions(
        region: "europe-west1"
    )

    func loadPendingReports() async {
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            let snapshot = try await db
                .collection("review_reports")
                .whereField("status", isEqualTo: "pending")
                .getDocuments()

            var loadedReports: [AdminReviewReport] = []

            for document in snapshot.documents {
                let data = document.data()

                guard let reviewId = data["reviewId"] as? String else {
                    continue
                }

                let reviewSnapshot = try? await db
                    .collection("reviews")
                    .document(reviewId)
                    .getDocument()

                let reviewData = reviewSnapshot?.data()

                loadedReports.append(
                    AdminReviewReport(
                        id: document.documentID,
                        reviewId: reviewId,
                        providerId: data["providerId"] as? String ?? "",
                        category: data["category"] as? String ?? "Diğer",
                        description: data["description"] as? String ?? "",
                        reporterId: data["reporterId"] as? String ?? "",
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
                )
            }

            reports = loadedReports.sorted {
                ($0.createdAt ?? .distantPast)
                    > ($1.createdAt ?? .distantPast)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
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
            case .dismiss:
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
            } else if viewModel.isLoading &&
                        viewModel.reports.isEmpty {
                ProgressView("Bildirimler yükleniyor...")
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
            } else if let errorMessage = viewModel.errorMessage,
                      viewModel.reports.isEmpty {
                errorView(message: errorMessage)
            } else if viewModel.reports.isEmpty {
                ContentUnavailableView(
                    "Bekleyen Bildirim Yok",
                    systemImage: "checkmark.shield",
                    description: Text(
                        "İncelenmesi gereken bir yorum bildirimi bulunmuyor."
                    )
                )
            } else {
                reportsList
            }
        }
        .background(backgroundColor.ignoresSafeArea())
        .navigationTitle("Bildirilen Yorumlar")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: session.isAdmin) {
            guard session.isAdmin else {
                return
            }

            await viewModel.loadPendingReports()
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

    private var reportsList: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(viewModel.reports) { report in
                    reportCard(report)
                }
            }
            .padding(16)
        }
        .refreshable {
            await viewModel.loadPendingReports()
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

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(
                    report.category,
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.red)

                Spacer()

                Text("İnceleniyor")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.orange.opacity(0.14))
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
                    await viewModel.loadPendingReports()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
    }
}
