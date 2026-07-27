import SwiftUI

struct AdminProviderApplicationsPage: View {

    @EnvironmentObject private var session: SessionViewModel

    @StateObject private var viewModel =
        AdminProviderApplicationsViewModel()

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
        .navigationTitle("Uzman Başvuruları")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: session.isAdmin) {
            guard session.isAdmin else {
                return
            }

            await viewModel.loadApplications()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    AdminProviderApplicationHistoryPage()
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                }
                .accessibilityLabel("Başvuru geçmişi")
            }
        }
    }

    @ViewBuilder
    private var adminContent: some View {
        if viewModel.isLoading && viewModel.applications.isEmpty {
            ProgressView("Başvurular yükleniyor...")
        } else if let errorMessage = viewModel.errorMessage,
                  viewModel.applications.isEmpty {
            errorState(message: errorMessage)
        } else if viewModel.applications.isEmpty {
            emptyState
        } else {
            applicationsList
        }
    }

    private var applicationsList: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(viewModel.applications) { application in
                    NavigationLink {
                        AdminProviderApplicationDetailPage(
                            application: application
                        ) {
                            await viewModel.loadApplications()
                        }
                    } label: {
                        applicationCard(application)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .refreshable {
            await viewModel.loadApplications()
        }
    }

    private func applicationCard(
        _ application: ExpertProfile
    ) -> some View {
        HStack(spacing: 14) {
            profileImage(application)

            VStack(alignment: .leading, spacing: 6) {
                Text(
                    application.businessName.isEmpty
                        ? application.displayName
                        : application.businessName
                )
                .font(.headline)
                .foregroundStyle(.primary)

                Text(application.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    statusBadge

                    Text(
                        "%\(application.profileCompletionPercentage) tamamlandı"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
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

    @ViewBuilder
    private func profileImage(
        _ application: ExpertProfile
    ) -> some View {
        if let value = application.profileImageURL,
           let url = URL(string: value),
           !value.isEmpty {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    profilePlaceholder
                }
            }
            .frame(width: 58, height: 58)
            .clipShape(Circle())
        } else {
            profilePlaceholder
        }
    }

    private var profilePlaceholder: some View {
        Image(systemName: "person.crop.circle.fill")
            .font(.system(size: 52))
            .foregroundStyle(.secondary)
            .frame(width: 58, height: 58)
    }

    private var statusBadge: some View {
        Text("Bekliyor")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.orange)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Color.orange.opacity(0.14))
            .clipShape(Capsule())
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "Bekleyen Başvuru Yok",
            systemImage: "person.badge.clock",
            description: Text(
                "Yeni bir uzman başvurusu gönderildiğinde burada görünecek."
            )
        )
    }

    private func errorState(message: String) -> some View {
        ContentUnavailableView {
            Label(
                "Başvurular Yüklenemedi",
                systemImage: "exclamationmark.triangle.fill"
            )
        } description: {
            Text(message)
        } actions: {
            Button("Tekrar Dene") {
                Task {
                    await viewModel.loadApplications()
                }
            }
        }
    }
}

private struct AdminProviderApplicationDetailPage: View {

    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel =
        AdminProviderApplicationDetailViewModel()

    @State private var adminNote = ""
    @State private var selectedAction:
        AdminProviderApplicationAction?
    @State private var showConfirmation = false
    @State private var resultMessage: String?
    @State private var decisionSucceeded = false

    let application: ExpertProfile
    let onDecisionCompleted: () async -> Void

    private let backgroundColor = Color("BackgroundColor")
    private let cardColor = Color("CardBackground")

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                summaryCard
                businessSection
                professionalSection
                identityDocumentsSection
                certificatesSection
                decisionSection
            }
            .padding(16)
        }
        .background(backgroundColor.ignoresSafeArea())
        .navigationTitle("Başvuru Detayı")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            selectedAction?.confirmationTitle ?? "",
            isPresented: $showConfirmation,
            titleVisibility: .visible
        ) {
            confirmationButtons
        } message: {
            Text(selectedAction?.confirmationMessage ?? "")
        }
        .alert(
            decisionSucceeded
                ? "İşlem Tamamlandı"
                : "İşlem Başarısız",
            isPresented: resultAlertBinding
        ) {
            Button("Tamam") {
                let shouldDismiss = decisionSucceeded

                resultMessage = nil
                decisionSucceeded = false
                viewModel.clearError()

                if shouldDismiss {
                    dismiss()
                }
            }
        } message: {
            Text(
                resultMessage
                    ?? viewModel.errorMessage
                    ?? "Bilinmeyen bir hata oluştu."
            )
        }
    }

    private var summaryCard: some View {
        VStack(spacing: 14) {
            if let value = application.profileImageURL,
               let url = URL(string: value),
               !value.isEmpty {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        summaryPlaceholder
                    }
                }
                .frame(width: 88, height: 88)
                .clipShape(Circle())
            } else {
                summaryPlaceholder
            }

            Text(application.displayName)
                .font(.title3.bold())

            Text(
                application.businessName.isEmpty
                    ? "İşletme adı girilmemiş"
                    : application.businessName
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)

            ProgressView(
                value: Double(
                    application.profileCompletionPercentage
                ),
                total: 100
            )

            Text(
                "Profil tamamlanma: %\(application.profileCompletionPercentage)"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(cardColor)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
        )
    }

    private var businessSection: some View {
        detailSection(title: "İşletme Bilgileri") {
            detailRow(
                title: "Ad Soyad",
                value: application.displayName
            )
            detailRow(
                title: "E-posta",
                value: application.email
            )
            detailRow(
                title: "Telefon",
                value: application.phoneNumber
            )
            detailRow(
                title: "İşletme",
                value: application.businessName
            )
            detailRow(
                title: "İşletme Türü",
                value: application.businessType
            )
            detailRow(
                title: "Vergi / TC",
                value: application.taxNumber ?? ""
            )
            detailRow(
                title: "Adres",
                value: application.address ?? ""
            )
            detailRow(
                title: "Şehirler",
                value: application.serviceCities.joined(
                    separator: ", "
                )
            )
        }
    }

    private var professionalSection: some View {
        detailSection(title: "Profesyonel Bilgiler") {
            detailRow(
                title: "Deneyim",
                value: "\(application.experienceYears) yıl"
            )
            detailRow(
                title: "Kategoriler",
                value: application.serviceCategories.joined(
                    separator: ", "
                )
            )
            detailRow(
                title: "Uzmanlıklar",
                value: application.expertiseAreas.joined(
                    separator: ", "
                )
            )
            detailRow(
                title: "Eğitim",
                value: application.educationLevel
            )
            detailRow(
                title: "Okul",
                value: application.schoolName
            )
            detailRow(
                title: "Hakkında",
                value: application.about ?? ""
            )
        }
    }

    private var identityDocumentsSection: some View {
        detailSection(title: "Kimlik Belgeleri") {
            documentRow(
                title: "Kimlik Ön Yüz",
                urlString: application.idFrontURL
            )

            documentRow(
                title: "Kimlik Arka Yüz",
                urlString: application.idBackURL
            )
        }
    }

    private var certificatesSection: some View {
        detailSection(title: "Sertifikalar") {
            if application.certificateURLs.isEmpty {
                Text("Sertifika yüklenmemiş.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(
                    Array(
                        application.certificateURLs.enumerated()
                    ),
                    id: \.offset
                ) { index, value in
                    documentRow(
                        title: "Sertifika \(index + 1)",
                        urlString: value
                    )
                }
            }
        }
    }

    private var decisionSection: some View {
        detailSection(title: "Admin Kararı") {
            Text(
                "Onay için açıklama isteğe bağlıdır. Ret ve eksik belge işlemlerinde açıklama zorunludur."
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            TextEditor(text: $adminNote)
                .frame(minHeight: 110)
                .padding(10)
                .scrollContentBackground(.hidden)
                .background(Color.primary.opacity(0.05))
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 12,
                        style: .continuous
                    )
                )
                .disabled(viewModel.isProcessing)

            HStack {
                Spacer()

                Text("\(adminNote.count)/500")
                    .font(.caption)
                    .foregroundStyle(
                        adminNote.count > 500
                            ? Color.red
                            : Color.secondary
                    )
            }

            if viewModel.isProcessing {
                HStack {
                    Spacer()
                    ProgressView()
                    Text("İşlem yapılıyor...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.vertical, 8)
            } else {
                Button {
                    prepareDecision(.approve)
                } label: {
                    Label(
                        "Başvuruyu Onayla",
                        systemImage: "checkmark.shield.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)

                Button {
                    prepareDecision(.requestDocuments)
                } label: {
                    Label(
                        "Eksik Belge İste",
                        systemImage: "doc.badge.ellipsis"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)

                Button(role: .destructive) {
                    prepareDecision(.reject)
                } label: {
                    Label(
                        "Başvuruyu Reddet",
                        systemImage: "xmark.shield.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    @ViewBuilder
    private var confirmationButtons: some View {
        if let selectedAction {
            Button(
                selectedAction.title,
                role: selectedAction == .reject
                    ? .destructive
                    : nil
            ) {
                runDecision(selectedAction)
            }
        }

        Button("Vazgeç", role: .cancel) {}
    }

    private var resultAlertBinding: Binding<Bool> {
        Binding(
            get: {
                resultMessage != nil ||
                    viewModel.errorMessage != nil
            },
            set: { isPresented in
                if !isPresented {
                    resultMessage = nil
                    decisionSucceeded = false
                    viewModel.clearError()
                }
            }
        )
    }

    private func prepareDecision(
        _ action: AdminProviderApplicationAction
    ) {
        let cleanNote = adminNote.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard adminNote.count <= 500 else {
            viewModel.showError(
                "Admin açıklaması en fazla 500 karakter olabilir."
            )
            return
        }

        guard !action.requiresNote || !cleanNote.isEmpty else {
            viewModel.showError(
                "Bu işlem için admin açıklaması zorunludur."
            )
            return
        }

        selectedAction = action
        showConfirmation = true
    }

    private func runDecision(
        _ action: AdminProviderApplicationAction
    ) {
        selectedAction = nil

        Task {
            let success = await viewModel.submitDecision(
                application: application,
                action: action,
                adminNote: adminNote
            )

            guard success else {
                return
            }

            await onDecisionCompleted()

            decisionSucceeded = true
            resultMessage = action.successMessage
        }
    }

    private func detailSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(cardColor)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
        )
    }

    private func detailRow(
        title: String,
        value: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(
                value.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ).isEmpty
                    ? "Belirtilmemiş"
                    : value
            )
            .font(.subheadline)
            .foregroundStyle(.primary)
        }
    }

    @ViewBuilder
    private func documentRow(
        title: String,
        urlString: String?
    ) -> some View {
        if let value = urlString,
           let url = URL(string: value),
           !value.isEmpty {
            Link(destination: url) {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .foregroundStyle(.blue)

                    Text(title)
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(
                        systemName: "arrow.up.right.square"
                    )
                    .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(Color.primary.opacity(0.05))
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 12,
                        style: .continuous
                    )
                )
            }
        } else {
            HStack {
                Image(systemName: "doc.badge.ellipsis")
                    .foregroundStyle(.secondary)

                Text("\(title): Yüklenmemiş")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var summaryPlaceholder: some View {
        Image(systemName: "person.crop.circle.fill")
            .font(.system(size: 82))
            .foregroundStyle(.secondary)
            .frame(width: 88, height: 88)
    }
}
