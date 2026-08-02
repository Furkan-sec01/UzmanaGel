import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import UIKit

/// PortfolioRepository, uzmanın portföy fotoğraflarını Firestore (portfolio/{uid}/items)
/// ve Firebase Storage (portfolio/{uid}/) üzerinde yönetir.
final class PortfolioRepository {

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    enum PortfolioError: LocalizedError {
        case notAuthenticated
        case invalidData
        case uploadFailed(Error)
        case itemNotFound

        var errorDescription: String? {
            switch self {
            case .notAuthenticated:
                return "Giriş yapılmamış. Lütfen tekrar giriş yapın."
            case .invalidData:
                return "Geçersiz dosya verisi."
            case .uploadFailed(let error):
                return "Yükleme hatası: \(error.localizedDescription)"
            case .itemNotFound:
                return "Portföy öğesi bulunamadı."
            }
        }
    }

    // MARK: - Fetch

    func fetchPortfolio(uid: String) async throws -> [PortfolioItem] {
        let snap = try await db
            .collection("portfolio")
            .document(uid)
            .collection("items")
            .order(by: "order", descending: false)
            .getDocuments()

        let items = snap.documents.compactMap { doc -> PortfolioItem? in
            let data = doc.data()
            guard
                let imageUrl = data["imageUrl"] as? String,
                let description = data["description"] as? String,
                let createdAtTimestamp = data["createdAt"] as? Timestamp
            else {
                print("⚠️ Portfolio öğesi decode hatası: \(doc.documentID)")
                return nil
            }

            return PortfolioItem(
                id: doc.documentID,
                imageUrl: imageUrl,
                description: description,
                createdAt: createdAtTimestamp.dateValue()
            )
        }

        // Fallback: order alanı yoksa createdAt'e göre sırala
        return items.isEmpty ? [] : items
    }

    // MARK: - Add

    func addItem(uid: String, imageData: Data, description: String) async throws -> PortfolioItem {
        // 1. Görseli Firebase Storage'a yükle
        guard let image = UIImage(data: imageData),
              let jpegData = image.jpegData(compressionQuality: 0.82) else {
            throw PortfolioError.invalidData
        }

        let filename = "\(UUID().uuidString).jpg"
        let storageRef = storage.reference().child("portfolio/\(uid)/\(filename)")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        do {
            _ = try await storageRef.putDataAsync(jpegData, metadata: metadata)
        } catch {
            throw PortfolioError.uploadFailed(error)
        }

        let downloadURL: URL
        do {
            downloadURL = try await storageRef.downloadURL()
        } catch {
            throw PortfolioError.uploadFailed(error)
        }

        // 2. Firestore'a kaydet
        let now = Date()
        let currentCount = try await currentItemCount(uid: uid)

        let parentRef = db.collection("portfolio").document(uid)
        try await parentRef.setData([
            "providerId": uid,
            "updatedAt": Timestamp(date: now)
        ], merge: true)

        let docRef = parentRef
            .collection("items")
            .document()

        let itemData: [String: Any] = [
            "imageUrl": downloadURL.absoluteString,
            "storagePath": "portfolio/\(uid)/\(filename)",
            "description": description.trimmingCharacters(in: .whitespacesAndNewlines),
            "order": currentCount,
            "createdAt": Timestamp(date: now)
        ]

        try await docRef.setData(itemData)

        return PortfolioItem(
            id: docRef.documentID,
            imageUrl: downloadURL.absoluteString,
            description: description,
            createdAt: now
        )
    }

    // MARK: - Delete

    func deleteItem(uid: String, itemId: String) async throws {
        let docRef = db
            .collection("portfolio")
            .document(uid)
            .collection("items")
            .document(itemId)

        // Storage path'ini bul ve sil
        let snapshot = try await docRef.getDocument()
        if let storagePath = snapshot.data()?["storagePath"] as? String, !storagePath.isEmpty {
            let storageRef = storage.reference().child(storagePath)
            try? await storageRef.delete()
        }

        // Firestore dokümanı sil
        try await docRef.delete()
    }

    // MARK: - Reorder

    func reorderItems(uid: String, orderedIds: [String]) async throws {
        let batch = db.batch()

        for (index, itemId) in orderedIds.enumerated() {
            let ref = db
                .collection("portfolio")
                .document(uid)
                .collection("items")
                .document(itemId)

            batch.updateData(["order": index], forDocument: ref)
        }

        try await batch.commit()
    }

    // MARK: - Private

    private func currentItemCount(uid: String) async throws -> Int {
        let snap = try await db
            .collection("portfolio")
            .document(uid)
            .collection("items")
            .count
            .getAggregation(source: .server)

        return Int(truncating: snap.count)
    }
}
