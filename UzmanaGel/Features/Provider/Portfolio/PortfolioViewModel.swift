import Foundation
import Combine
import SwiftUI
import FirebaseAuth

@MainActor
class PortfolioViewModel: ObservableObject {
    @Published var portfolioItems: [PortfolioItem] = []
    @Published var isLoading = false
    @Published var isUploading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    // UI details
    @Published var fullscreenItem: PortfolioItem? = nil
    @Published var showCropFilterSimulator = false
    @Published var selectedImageData: Data? = nil

    // Simulated Drag-and-Drop state
    @Published var dragOverId: String? = nil

    private let repo = PortfolioRepository()

    private var currentUID: String? {
        Auth.auth().currentUser?.uid
    }

    // MARK: - Load

    func loadPortfolio() async {
        guard let uid = currentUID else {
            errorMessage = "Giriş yapılmamış."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            portfolioItems = try await repo.fetchPortfolio(uid: uid)
            print("✅ Portfolio yüklendi: \(portfolioItems.count) öğe")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Portfolio yükleme hatası: \(error)")
        }
    }

    // MARK: - Add

    func addPortfolioItem(description: String, imageData: Data) {
        guard let uid = currentUID else {
            errorMessage = "Giriş yapılmamış."
            return
        }

        Task {
            isUploading = true
            errorMessage = nil
            defer { isUploading = false }

            do {
                let newItem = try await repo.addItem(
                    uid: uid,
                    imageData: imageData,
                    description: description
                )
                portfolioItems.insert(newItem, at: 0)
                successMessage = "Fotoğraf portfolyonuza eklendi."
                print("✅ Portfolio öğesi eklendi: \(newItem.id)")
            } catch {
                errorMessage = error.localizedDescription
                print("❌ Portfolio ekleme hatası: \(error)")
            }
        }
    }

    // MARK: - Delete

    func deleteItem(id: String) {
        guard let uid = currentUID else { return }

        Task {
            do {
                try await repo.deleteItem(uid: uid, itemId: id)
                portfolioItems.removeAll(where: { $0.id == id })
                if fullscreenItem?.id == id {
                    fullscreenItem = nil
                }
                successMessage = "Öğe galeriden silindi."
                print("✅ Portfolio öğesi silindi: \(id)")
            } catch {
                errorMessage = error.localizedDescription
                print("❌ Portfolio silme hatası: \(error)")
            }
        }
    }

    // MARK: - Reorder (Drag & Drop)

    func moveItem(from sourceId: String, to targetId: String) {
        guard
            let sourceIndex = portfolioItems.firstIndex(where: { $0.id == sourceId }),
            let targetIndex = portfolioItems.firstIndex(where: { $0.id == targetId }),
            sourceIndex != targetIndex
        else { return }

        withAnimation(.spring()) {
            let item = portfolioItems.remove(at: sourceIndex)
            portfolioItems.insert(item, at: targetIndex)
        }

        // Sıralamayı Firebase'e kaydet
        guard let uid = currentUID else { return }
        let orderedIds = portfolioItems.map { $0.id }

        Task {
            do {
                try await repo.reorderItems(uid: uid, orderedIds: orderedIds)
            } catch {
                print("⚠️ Sıralama kaydedilemedi: \(error)")
            }
        }
    }

    // MARK: - Reset

    func resetForm() {
        selectedImageData = nil
        showCropFilterSimulator = false
    }
}
