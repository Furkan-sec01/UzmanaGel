import SwiftUI

@MainActor
struct ReviewCreateSheet: View {

    @Environment(\.dismiss) private var dismiss

    let reservation: Reservation
    let onSubmitted: () -> Void

    @State private var rating = 0
    @State private var comment = ""
    @State private var isSubmitting = false

    @State private var errorMessage = ""
    @State private var showError = false

    private let repository: ReviewRepository

    init(
        reservation: Reservation,
        onSubmitted: @escaping () -> Void = { }
    ) {
        self.reservation = reservation
        self.onSubmitted = onSubmitted
        self.repository = ReviewRepository()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    reservationInfo
                    ratingSection
                    commentSection
                    submitButton
                }
                .padding(20)
            }
            .navigationTitle("Değerlendir".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Kapat".localized) {
                        dismiss()
                    }
                    .disabled(isSubmitting)
                }
            }
            .alert(
                "Hata".localized,
                isPresented: $showError
            ) {
                Button("Tamam".localized, role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
        .interactiveDismissDisabled(isSubmitting)
    }

    private var reservationInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(reservation.serviceTitle)
                .font(.headline)

            Text(reservation.providerName)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(
                reservation.reservationDate.formatted(
                    date: .abbreviated,
                    time: .shortened
                )
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.secondary.opacity(0.08))
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
        )
    }

    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Puanınız".localized)
                .font(.headline)

            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { value in
                    Button {
                        rating = value
                    } label: {
                        Image(
                            systemName: value <= rating
                                ? "star.fill"
                                : "star"
                        )
                        .font(.system(size: 30))
                        .foregroundStyle(.yellow)
                    }
                    .buttonStyle(.plain)
                    .disabled(isSubmitting)
                }
            }

            if rating == 0 {
                Text("Lütfen 1 ile 5 arasında puan seçin.".localized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var commentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Yorumunuz".localized)
                    .font(.headline)

                Spacer()

                Text("\(comment.count)/500")
                    .font(.caption)
                    .foregroundStyle(
                        comment.count > 500
                            ? Color.red
                            : Color.secondary
                    )
            }

            TextEditor(text: $comment)
                .frame(minHeight: 140)
                .padding(10)
                .scrollContentBackground(.hidden)
                .background(Color.secondary.opacity(0.08))
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 14,
                        style: .continuous
                    )
                )
                .overlay {
                    RoundedRectangle(
                        cornerRadius: 14,
                        style: .continuous
                    )
                    .stroke(
                        comment.count > 500
                            ? Color.red
                            : Color.secondary.opacity(0.2),
                        lineWidth: 1
                    )
                }
                .disabled(isSubmitting)
        }
    }

    private var submitButton: some View {
        Button {
            Task {
                await submitReview()
            }
        } label: {
            HStack(spacing: 10) {
                if isSubmitting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "paperplane.fill")
                }

                Text("Değerlendirmeyi Gönder".localized)
                    .fontWeight(.bold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                canSubmit
                    ? Color.blue
                    : Color.gray
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 14,
                    style: .continuous
                )
            )
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit || isSubmitting)
    }

    private var canSubmit: Bool {
        rating >= 1
            && rating <= 5
            && comment.count <= 500
    }

    private func submitReview() async {
        guard canSubmit else {
            errorMessage =
                "Lütfen geçerli bir puan ve yorum girin.".localized
            showError = true
            return
        }

        isSubmitting = true
        defer {
            isSubmitting = false
        }

        do {
            try await repository.submitReview(
                reservation: reservation,
                rating: rating,
                comment: comment
            )

            onSubmitted()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
