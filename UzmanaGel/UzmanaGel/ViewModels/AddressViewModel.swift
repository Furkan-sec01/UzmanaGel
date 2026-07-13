//
//  AddressViewModel.swift
//  UzmanaGel
//
//  Created by Baran on 10.07.2026.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class AddressViewModel: ObservableObject {

    @Published var addresses: [UserAddress] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    private var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

    private func addressesRef(for uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("addresses")
    }

    func loadAddresses() {
        Task {
            await fetchAddresses()
        }
    }

    func fetchAddresses() async {
        guard let uid = currentUserId else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let snapshot = try await addressesRef(for: uid).getDocuments()
            let fetched = snapshot.documents.compactMap { try? $0.data(as: UserAddress.self) }
            // Varsayılan adres en üstte, sonrasında son eklenenler sırasıyla listelensin
            self.addresses = fetched.sorted {
                if $0.isDefault != $1.isDefault {
                    return $0.isDefault
                }
                let t0 = $0.createdAt?.dateValue() ?? Date.distantPast
                let t1 = $1.createdAt?.dateValue() ?? Date.distantPast
                return t0 > t1
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Adresleri yükleme hatası: \(error.localizedDescription)")
        }
    }

    func saveAddress(_ address: UserAddress) async -> Bool {
        guard let uid = currentUserId else {
            errorMessage = "Kullanıcı oturumu bulunamadı."
            return false
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let ref = addressesRef(for: uid)

            // Eğer kaydedilecek adres varsayılan seçilmişse, diğer adreslerin varsayılan özelliğini kaldır
            if address.isDefault {
                await resetOtherDefaults(exceptId: address.id, uid: uid)
            }

            if let docId = address.id {
                // Güncelleme
                var updated = address
                if updated.createdAt == nil {
                    updated.createdAt = Timestamp(date: Date())
                }
                try ref.document(docId).setData(from: updated, merge: true)
            } else {
                // Yeni adres ekleme
                var newAddress = address
                newAddress.createdAt = Timestamp(date: Date())
                // Eğer listedeki ilk adresse otomatik olarak varsayılan yap
                if addresses.isEmpty {
                    newAddress.isDefault = true
                }
                _ = try ref.addDocument(from: newAddress)
            }

            await fetchAddresses()
            return true
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Adres kaydetme hatası: \(error.localizedDescription)")
            return false
        }
    }

    func deleteAddress(id: String) async {
        guard let uid = currentUserId else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            try await addressesRef(for: uid).document(id).delete()
            await fetchAddresses()
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Adres silme hatası: \(error.localizedDescription)")
        }
    }

    func setDefaultAddress(id: String) async {
        guard let uid = currentUserId else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let batch = db.batch()
            let snapshot = try await addressesRef(for: uid).getDocuments()

            for doc in snapshot.documents {
                let isTarget = (doc.documentID == id)
                batch.updateData(["isDefault": isTarget], forDocument: doc.reference)
            }

            try await batch.commit()
            await fetchAddresses()
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Varsayılan adres güncelleme hatası: \(error.localizedDescription)")
        }
    }

    private func resetOtherDefaults(exceptId: String?, uid: String) async {
        do {
            let snapshot = try await addressesRef(for: uid)
                .whereField("isDefault", isEqualTo: true)
                .getDocuments()

            let batch = db.batch()
            for doc in snapshot.documents {
                if doc.documentID != exceptId {
                    batch.updateData(["isDefault": false], forDocument: doc.reference)
                }
            }
            try await batch.commit()
        } catch {
            print("⚠️ Diğer varsayılan adresleri sıfırlama hatası: \(error.localizedDescription)")
        }
    }

    func clearError() {
        errorMessage = nil
    }
}
