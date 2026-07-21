import SwiftUI
import FirebaseAuth

@MainActor
struct ReviewsPage: View {

    @StateObject private var viewModel: ReviewsViewModel
    @State private var selectedReviewForResponse: ProviderReview?

    private let providerName: String

    init(
        providerId: String,
        providerName: String
    ) {
        self.providerName = providerName

        _viewModel = StateObject(
            wrappedValue: ReviewsViewModel(
                providerId: providerId
            )
        )
    }

    var body: some View {
        ZStack {
            Color("BackgroundColor")
                .ignoresSafeArea()

            content
        }
        .navigationTitle("Yorumlar")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadReviews()
        }
        .refreshable {
            await viewModel.loadReviews()
        }
        .sheet(item: $selectedReviewForResponse) { review in
            ProviderResponseSheet(
                review: review
            ) { response in
                await viewModel.submitProviderResponse(
                    reviewId: review.reviewId,
                    response: response
                )
            }
        }
        .alert(
            "Cevap Gönderilemedi",
            isPresented: Binding(
                get: {
                    viewModel.responseErrorMessage != nil
                },
                set: { isPresented in
                    if !isPresented {
                        viewModel.responseErrorMessage = nil
                    }
                }
            )
        ) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(viewModel.responseErrorMessage ?? "")
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.reviews.isEmpty {
            ProgressView("Yorumlar yükleniyor...")
        } else if let errorMessage = viewModel.errorMessage,
                  viewModel.reviews.isEmpty {
            errorView(message: errorMessage)
        } else if viewModel.reviews.isEmpty {
            emptyView
        } else {
            reviewsContent
        }
    }

    private var reviewsContent: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
                summaryCard

                ForEach(viewModel.reviews) { review in
                    reviewCard(review)
                }
            }
            .padding(16)
        }
    }

    private var summaryCard: some View {
        VStack(spacing: 12) {
            if !providerName.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty {
                Text(providerName)
                    .font(.headline)
                    .foregroundColor(Color("Text"))
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .foregroundColor(.orange)

                Text(
                    String(
                        format: "%.1f",
                        viewModel.averageRating
                    )
                )
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color("Text"))
            }

            Text("\(viewModel.reviewCount) yorum")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color("CardBackground"))
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
        )
    }

    private func reviewCard(
        _ review: ProviderReview
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                customerAvatar(
                    name: review.customerName
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(review.customerName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color("Text"))

                    Text(review.serviceTitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(
                    review.createdAt,
                    format: .dateTime
                        .day()
                        .month(.abbreviated)
                        .year()
                )
                .font(.caption)
                .foregroundColor(.secondary)
            }

            ratingStars(rating: review.rating)

            Text(
                review.comment.isEmpty
                    ? "Yorum metni eklenmedi."
                    : review.comment
            )
            .font(.system(size: 14))
            .foregroundColor(Color("Text"))
            .frame(maxWidth: .infinity, alignment: .leading)

            if let providerResponse = review.providerResponse {
                providerResponseView(
                    response: providerResponse,
                    responseDate: review.providerResponseAt
                )
            } else if Auth.auth().currentUser?.uid == review.providerId {
                Button {
                    selectedReviewForResponse = review
                } label: {
                    Label(
                        "Cevapla",
                        systemImage: "arrowshape.turn.up.left"
                    )
                    .font(.system(size: 14, weight: .semibold))
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(16)
        .background(Color("CardBackground"))
        .clipShape(
            RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
            )
        )
    }

    private func providerResponseView(
        response: String,
        responseDate: Date?
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(
                    "Uzmanın Yanıtı",
                    systemImage: "checkmark.seal.fill"
                )
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color("PrimaryColor"))

                Spacer()

                if let responseDate {
                    Text(
                        responseDate,
                        format: .dateTime
                            .day()
                            .month(.abbreviated)
                            .year()
                    )
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
            }

            Text(response)
                .font(.system(size: 14))
                .foregroundColor(Color("Text"))
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
        }
        .padding(12)
        .background(
            Color("PrimaryColor").opacity(0.08)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 10,
                style: .continuous
            )
        )
    }

    private func customerAvatar(
        name: String
    ) -> some View {
        ZStack {
            Circle()
                .fill(Color("PrimaryColor").opacity(0.15))

            Text(initials(from: name))
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color("PrimaryColor"))
        }
        .frame(width: 42, height: 42)
    }

    private func ratingStars(
        rating: Int
    ) -> some View {
        HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { value in
                Image(
                    systemName: value <= rating
                        ? "star.fill"
                        : "star"
                )
                .font(.system(size: 14))
                .foregroundColor(.orange)
            }
        }
    }

    private var emptyView: some View {
        ContentUnavailableView {
            Label(
                "Henüz yorum yok",
                systemImage: "text.bubble"
            )
        } description: {
            Text(
                "Bu uzman için henüz bir değerlendirme yapılmamış."
            )
        }
    }

    private func errorView(
        message: String
    ) -> some View {
        ContentUnavailableView {
            Label(
                "Yorumlar yüklenemedi",
                systemImage: "exclamationmark.triangle"
            )
        } description: {
            Text(message)
        } actions: {
            Button("Tekrar Dene") {
                Task {
                    await viewModel.loadReviews()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func initials(
        from name: String
    ) -> String {
        let parts = name
            .split(separator: " ")
            .prefix(2)

        let value = parts.compactMap {
            $0.first
        }

        return String(value).uppercased()
    }
}

@MainActor
private struct ProviderResponseSheet: View {

    @Environment(\.dismiss) private var dismiss

    let review: ProviderReview
    let onSubmit: (String) async -> Bool

    @State private var response = ""
    @State private var isSubmitting = false

    private var trimmedResponse: String {
        response.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private var canSubmit: Bool {
        !trimmedResponse.isEmpty
            && trimmedResponse.count <= 500
            && !isSubmitting
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Müşteri Yorumu") {
                    Text(review.customerName)
                        .font(.headline)

                    Text(review.comment.isEmpty
                         ? "Yorum metni eklenmedi."
                         : review.comment)
                }

                Section("Uzman Yanıtı") {
                    ZStack(alignment: .topLeading) {
                        if response.isEmpty {
                            Text("Yanıtınızı yazın...")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                        }

                        TextEditor(text: $response)
                            .frame(minHeight: 140)
                    }

                    Text("\(response.count)/500")
                        .font(.caption)
                        .foregroundColor(
                            response.count > 500
                                ? .red
                                : .secondary
                        )
                        .frame(
                            maxWidth: .infinity,
                            alignment: .trailing
                        )
                }
            }
            .navigationTitle("Yoruma Cevap Ver")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled(isSubmitting)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") {
                        dismiss()
                    }
                    .disabled(isSubmitting)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            await submitResponse()
                        }
                    } label: {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("Gönder")
                        }
                    }
                    .disabled(!canSubmit)
                }
            }
        }
    }

    private func submitResponse() async {
        guard canSubmit else {
            return
        }

        isSubmitting = true

        let isSuccessful = await onSubmit(
            trimmedResponse
        )

        isSubmitting = false

        if isSuccessful {
            dismiss()
        }
    }
}

