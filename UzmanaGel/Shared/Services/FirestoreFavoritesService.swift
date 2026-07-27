import Foundation
import FirebaseFirestore
import FirebaseAuth


class FirestoreFavoritesService: FavoritesService {
    private let db = Firestore.firestore()
    private let usersCollection = "users"
    // Matches the existing Firestore collection where expert profiles are stored
    private let providersCollection = "service_providers"
    
    // MARK: - Helper to get current user document ref
    private var currentUserRef: DocumentReference {
        get throws {
            guard let userId = Auth.auth().currentUser?.uid else {
                throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı girişi yapılmamış."])
            }
            return db.collection(usersCollection).document(userId)
        }
    }
    
    // MARK: - Fetch Providers by IDs (from service_providers collection)
    // Converts Firestore's ServiceProvider documents to the app's shared Provider model.
    private func fetchProviders(by ids: [String]) async throws -> [Provider] {
        if ids.isEmpty { return [] }
        
        var providers: [Provider] = []
        // Firestore 'in' queries support max 10 elements at a time
        let chunks = ids.chunked(into: 10)
        
        for chunk in chunks {
            let snapshot = try await db.collection(providersCollection)
                .whereField("providerId", in: chunk)
                .getDocuments()
            
            let chunkProviders = snapshot.documents.compactMap { doc -> Provider? in
                serviceProviderDocToProvider(doc: doc)
            }
            providers.append(contentsOf: chunkProviders)
        }
        return providers
    }
    
    // MARK: - Favorite Providers
    // Reads from users/{uid}/favorites sub-collection (where ServiceDetailPage saves favorites by serviceId)
    func fetchFavoriteProviders() async throws -> [Provider] {
        guard let uid = Auth.auth().currentUser?.uid else { return [] }
        
        // Step 1: Get saved serviceIds from favorites sub-collection
        let favSnap = try await db.collection(usersCollection)
            .document(uid)
            .collection("favorites")
            .getDocuments()
        
        let serviceIds = favSnap.documents.compactMap { $0.data()["serviceId"] as? String }
        guard !serviceIds.isEmpty else { return [] }
        
        // Step 2: Fetch services to get providerIds (in chunks of 10)
        var providerIds: [String] = []
        let chunks = serviceIds.chunked(into: 10)
        for chunk in chunks {
            let servSnap = try await db.collection("services")
                .whereField("serviceId", in: chunk)
                .getDocuments()
            let ids = servSnap.documents.compactMap { $0.data()["providerId"] as? String }
            providerIds.append(contentsOf: ids)
        }
        
        // Deduplicate providerIds
        let uniqueProviderIds = Array(Set(providerIds))
        guard !uniqueProviderIds.isEmpty else { return [] }
        
        // Step 3: Fetch provider profiles
        return try await fetchProviders(by: uniqueProviderIds)
    }
    
    func toggleFavorite(providerId: String) async throws {
        let ref = try currentUserRef
        let userSnapshot = try await ref.getDocument()
        var favorites = userSnapshot.data()?["favoriteProviderIds"] as? [String] ?? []
        
        if favorites.contains(providerId) {
            favorites.removeAll { $0 == providerId }
        } else {
            favorites.append(providerId)
        }
        try await ref.updateData(["favoriteProviderIds": favorites])
    }
    
    // MARK: - Recently Viewed
    func fetchRecentlyViewed() async throws -> [Provider] {
        let ref = try currentUserRef
        let userSnapshot = try await ref.getDocument()
        let viewedIds = userSnapshot.data()?["recentlyViewedProviderIds"] as? [String] ?? []
        return try await fetchProviders(by: viewedIds)
    }
    
    func addRecentlyViewed(providerId: String) async throws {
        let ref = try currentUserRef
        let userSnapshot = try await ref.getDocument()
        var viewed = userSnapshot.data()?["recentlyViewedProviderIds"] as? [String] ?? []
        
        viewed.removeAll { $0 == providerId }
        viewed.insert(providerId, at: 0)
        if viewed.count > 5 { viewed = Array(viewed.prefix(5)) }
        
        try await ref.updateData(["recentlyViewedProviderIds": viewed])
    }
    
    // MARK: - Saved Searches
    func fetchSavedSearches() async throws -> [String] {
        let ref = try currentUserRef
        let userSnapshot = try await ref.getDocument()
        return userSnapshot.data()?["savedSearches"] as? [String] ?? []
    }
    
    func addSavedSearch(_ query: String) async throws {
        let ref = try currentUserRef
        let userSnapshot = try await ref.getDocument()
        var searches = userSnapshot.data()?["savedSearches"] as? [String] ?? []
        
        if !searches.contains(query) {
            searches.append(query)
            try await ref.updateData(["savedSearches": searches])
        }
    }
    
    func removeSavedSearch(_ query: String) async throws {
        let ref = try currentUserRef
        let userSnapshot = try await ref.getDocument()
        var searches = userSnapshot.data()?["savedSearches"] as? [String] ?? []
        
        searches.removeAll { $0 == query }
        try await ref.updateData(["savedSearches": searches])
    }
    
    // MARK: - Helper: Convert Firestore ServiceProvider doc → app's Provider model
    private func serviceProviderDocToProvider(doc: DocumentSnapshot) -> Provider? {
        guard let data = doc.data() else { return nil }
        let id = data["providerId"] as? String ?? doc.documentID
        let businessName = data["businessName"] as? String ?? "Bilinmeyen Usta"
        let rating = data["rating"] as? Double ?? 0.0
        let experienceYears = data["experienceYears"] as? Int ?? 0
        let acceptsCreditCard = data["acceptsCreditCard"] as? Bool ?? false
        let description = data["description"] as? String ?? ""
        let isCertified = data["isCertified"] as? Bool ?? false
        // Use profileImageURL from Firestore (stored as 'profileImageURL' field)
        let imageUrl = data["profileImageURL"] as? String ?? data["image"] as? String
        
        return Provider(
            id: id,
            businessName: businessName,
            rating: rating,
            experienceYears: experienceYears,
            acceptsCreditCard: acceptsCreditCard,
            description: description,
            imageUrl: imageUrl,
            isCertified: isCertified
        )
    }
}

// Helper: Array chunking (fileprivate to avoid redeclaration in other files)
fileprivate extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
