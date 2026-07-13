import Foundation
import FirebaseAuth
import FirebaseFirestore

final class FavoritesRepository {

    private let db = Firestore.firestore()

    private func favoritesRef(uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("favorites")
    }

    func addFavorite(serviceId: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        try await favoritesRef(uid: uid)
            .document(serviceId)
            .setData([
                "serviceId": serviceId,
                "createdAt": FieldValue.serverTimestamp()
            ], merge: true)
    }

    func removeFavorite(serviceId: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        try await favoritesRef(uid: uid)
            .document(serviceId)
            .delete()
    }

    func fetchFavoriteServiceIds() async throws -> [String] {
        guard let uid = Auth.auth().currentUser?.uid else { return [] }

        // Index gerektirmeyen basit sorgu kullan
        // createdAt sıralaması composite index gerektirir ve
        // eski kayıtlarda createdAt olmayabilir
        let snap = try await favoritesRef(uid: uid)
            .getDocuments()

        return snap.documents.compactMap { $0.data()["serviceId"] as? String }
    }
}
