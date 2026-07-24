//
//  ProviderReviewsViewModel.swift
//  UzmanaGel
//
//  Created by Antigravity on 22.07.2026.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

enum ReviewSortOption: String, CaseIterable, Identifiable {
    case newest = "En Yeni"
    case highest = "En Yüksek Puan"
    case lowest = "En Düşük Puan"
    
    var id: String { rawValue }
    var localized: String { rawValue.localized }
}

enum ReviewFilterOption: String, CaseIterable, Identifiable {
    case all = "Tümü"
    case withPhotos = "Fotoğraflı"
    case verified = "Onaylı Hizmet"
    
    var id: String { rawValue }
    var localized: String { rawValue.localized }
}

@MainActor
final class ProviderReviewsViewModel: ObservableObject {
    
    @Published var reviews: [Review] = []
    @Published var filteredReviews: [Review] = []
    @Published var summary: ProviderReviewSummary = .empty
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    @Published var selectedSort: ReviewSortOption = .newest {
        didSet { applyFiltersAndSort() }
    }
    @Published var selectedFilter: ReviewFilterOption = .all {
        didSet { applyFiltersAndSort() }
    }
    
    @Published var isAnonymizedOption: Bool = true
    
    private let repo = ReviewRepository()
    private let providerId: String
    
    init(providerId: String) {
        self.providerId = providerId
    }
    
    func loadReviews() async {
        guard !providerId.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        do {
            let fetched = try await repo.fetchReviews(forProviderId: providerId)
            self.reviews = fetched
            self.summary = ProviderReviewSummary(reviews: fetched)
            applyFiltersAndSort()
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    private func applyFiltersAndSort() {
        var result = reviews
        
        // Filter
        switch selectedFilter {
        case .all:
            break
        case .withPhotos:
            result = result.filter { !$0.photos.isEmpty }
        case .verified:
            result = result.filter { $0.isVerifiedBooking }
        }
        
        // Sort
        switch selectedSort {
        case .newest:
            result.sort { ($0.createdAt?.dateValue() ?? Date()) > ($1.createdAt?.dateValue() ?? Date()) }
        case .highest:
            result.sort { $0.rating > $1.rating }
        case .lowest:
            result.sort { $0.rating < $1.rating }
        }
        
        self.filteredReviews = result
    }
    
    func toggleHelpful(review: Review) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let reviewId = review.id else { return }
        
        do {
            let (newCount, isHelpful) = try await repo.toggleHelpful(reviewId: reviewId, userId: uid)
            if let idx = reviews.firstIndex(where: { $0.id == reviewId }) {
                reviews[idx].helpfulCount = newCount
                if isHelpful {
                    reviews[idx].helpfulUsers.append(uid)
                } else {
                    reviews[idx].helpfulUsers.removeAll { $0 == uid }
                }
            }
            applyFiltersAndSort()
        } catch {
            print("❌ Helpful toggle hatası: \(error.localizedDescription)")
        }
    }
    
    func submitResponse(review: Review, responseText: String) async -> Bool {
        guard let reviewId = review.id, !responseText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        do {
            try await repo.submitProviderResponse(reviewId: reviewId, response: responseText)
            if let idx = reviews.firstIndex(where: { $0.id == reviewId }) {
                reviews[idx].providerResponse = responseText
                reviews[idx].providerResponseDate = Timestamp(date: Date())
            }
            applyFiltersAndSort()
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            return false
        }
    }
    
    func report(review: Review, category: ReviewReportCategory, description: String) async -> Bool {
        guard let reviewId = review.id else { return false }
        do {
            try await repo.reportReview(
                reviewId: reviewId,
                providerId: review.providerId,
                category: category,
                description: description
            )
            if let idx = reviews.firstIndex(where: { $0.id == reviewId }) {
                reviews[idx].isReported = true
            }
            applyFiltersAndSort()
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            return false
        }
    }
    
    var canCurrentProviderRespond: Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        return uid == providerId
    }
}
