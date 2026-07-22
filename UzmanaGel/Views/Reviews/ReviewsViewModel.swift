import Combine
import Foundation

@MainActor
final class ReviewsViewModel: ObservableObject {

    @Published private(set) var reviews: [ProviderReview] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let providerId: String
    private let repository: ReviewRepository

    init(
        providerId: String,
        repository: ReviewRepository? = nil
    ) {
        self.providerId = providerId
        self.repository = repository ?? ReviewRepository()
    }

    var reviewCount: Int {
        reviews.count
    }

    var averageRating: Double {
        guard !reviews.isEmpty else {
            return 0
        }

        let totalRating = reviews.reduce(0) {
            $0 + $1.rating
        }

        return Double(totalRating) / Double(reviews.count)
    }

    func loadReviews() async {
        guard !isLoading else {
            return
        }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            reviews = try await repository.fetchReviews(
                providerId: providerId
            )
        } catch {
            reviews = []
            errorMessage = error.localizedDescription
        }
    }
}
