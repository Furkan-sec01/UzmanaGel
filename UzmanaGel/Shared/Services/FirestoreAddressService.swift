//
//  FirestoreAddressService.swift
//  UzmanaGel
//
//  Created by Antigravity on 17.07.2026.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class FirestoreAddressService: AddressService {
    private let db = Firestore.firestore()
    
    private var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
    
    private func addressesRef(for uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("addresses")
    }
    
    func fetchAddresses() async throws -> [Address] {
        guard let uid = currentUserId else {
            throw NSError(domain: "FirestoreAddressService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı oturumu bulunamadı."])
        }
        
        let snapshot = try await addressesRef(for: uid).getDocuments()
        let fetchedWithMeta = snapshot.documents.compactMap { doc -> (Address, Date)? in
            let data = doc.data()
            let id = doc.documentID
            let title = data["title"] as? String ?? ""
            let fullAddress = data["fullAddress"] as? String ?? ""
            let city = data["city"] as? String ?? ""
            let district = data["district"] as? String ?? ""
            let buildingNo = data["buildingNo"] as? String ?? ""
            let apartmentNo = data["apartmentNo"] as? String ?? ""
            let floor = data["floor"] as? String ?? ""
            let directionsNote = data["directionsNote"] as? String ?? ""
            let tag = data["tag"] as? String
            let isDefault = data["isDefault"] as? Bool ?? false
            let latitude = data["latitude"] as? Double
            let longitude = data["longitude"] as? Double
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date.distantPast
            
            let addr = Address(
                id: id,
                title: title,
                fullAddress: fullAddress,
                city: city,
                district: district,
                buildingNo: buildingNo,
                apartmentNo: apartmentNo,
                floor: floor,
                directionsNote: directionsNote,
                tag: tag,
                isDefault: isDefault,
                latitude: latitude,
                longitude: longitude
            )
            return (addr, createdAt)
        }
        
        // Sort: default address first, then by creation date descending
        let sorted = fetchedWithMeta.sorted {
            if $0.0.isDefault != $1.0.isDefault {
                return $0.0.isDefault
            }
            return $0.1 > $1.1
        }
        
        return sorted.map { $0.0 }
    }
    
    func addAddress(_ address: Address) async throws -> Address {
        guard let uid = currentUserId else {
            throw NSError(domain: "FirestoreAddressService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı oturumu bulunamadı."])
        }
        
        let ref = addressesRef(for: uid)
        
        // If this address is default, reset others
        if address.isDefault {
            try await resetOtherDefaults(uid: uid)
        }
        
        var newAddress = address
        // Check if it's the first address, set as default automatically
        let existingSnapshot = try await ref.getDocuments()
        if existingSnapshot.documents.isEmpty {
            newAddress.isDefault = true
        }
        
        let docRef = ref.document()
        newAddress.id = docRef.documentID
        
        let data: [String: Any] = [
            "title": newAddress.title,
            "fullAddress": newAddress.fullAddress,
            "city": newAddress.city,
            "district": newAddress.district,
            "buildingNo": newAddress.buildingNo,
            "apartmentNo": newAddress.apartmentNo,
            "floor": newAddress.floor,
            "directionsNote": newAddress.directionsNote,
            "tag": newAddress.tag as Any,
            "isDefault": newAddress.isDefault,
            "latitude": newAddress.latitude as Any,
            "longitude": newAddress.longitude as Any,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        try await docRef.setData(data)
        return newAddress
    }
    
    func updateAddress(_ address: Address) async throws -> Address {
        guard let uid = currentUserId else {
            throw NSError(domain: "FirestoreAddressService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı oturumu bulunamadı."])
        }
        
        let docRef = addressesRef(for: uid).document(address.id)
        
        if address.isDefault {
            try await resetOtherDefaults(uid: uid, exceptId: address.id)
        }
        
        let data: [String: Any] = [
            "title": address.title,
            "fullAddress": address.fullAddress,
            "city": address.city,
            "district": address.district,
            "buildingNo": address.buildingNo,
            "apartmentNo": address.apartmentNo,
            "floor": address.floor,
            "directionsNote": address.directionsNote,
            "tag": address.tag as Any,
            "isDefault": address.isDefault,
            "latitude": address.latitude as Any,
            "longitude": address.longitude as Any
        ]
        
        try await docRef.setData(data, merge: true)
        return address
    }
    
    func deleteAddress(id: String) async throws {
        guard let uid = currentUserId else {
            throw NSError(domain: "FirestoreAddressService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı oturumu bulunamadı."])
        }
        
        try await addressesRef(for: uid).document(id).delete()
    }
    
    func setDefaultAddress(id: String) async throws {
        guard let uid = currentUserId else {
            throw NSError(domain: "FirestoreAddressService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı oturumu bulunamadı."])
        }
        
        let ref = addressesRef(for: uid)
        let snapshot = try await ref.getDocuments()
        
        let batch = db.batch()
        for doc in snapshot.documents {
            let isTarget = (doc.documentID == id)
            batch.updateData(["isDefault": isTarget], forDocument: doc.reference)
        }
        try await batch.commit()
    }
    
    private func resetOtherDefaults(uid: String, exceptId: String? = nil) async throws {
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
    }
}
