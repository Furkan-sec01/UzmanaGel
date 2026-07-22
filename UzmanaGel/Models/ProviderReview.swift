import Foundation

struct ProviderReview: Identifiable, Codable, Hashable {
    let reviewId: String
    let reservationId: String

    let providerId: String
    let customerId: String
    let customerName: String

    let serviceId: String
    let serviceTitle: String

    let rating: Int
    let comment: String

    let createdAt: Date
    let updatedAt: Date

    var id: String {
        reviewId
    }
}
