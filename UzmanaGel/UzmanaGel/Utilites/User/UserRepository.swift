//
//  UserRepository.swift
//  UzmanaGel
//
//  Created by Abdullah B on 5.02.2026.
//

import Foundation
import FirebaseFirestore

/// Firestore bağlantısı: GoogleService-Info.plist içindeki Firebase projesi kullanılır.
/// Database location (eur3 vb.) proje oluşturulurken Console'da seçilir; istemci aynı projeye bağlanır.
final class UserRepository {

    private let db = Firestore.firestore()

    // MARK: - Mükerrer Kontrol

    func isEmailTaken(_ email: String) async throws -> Bool {
        let snapshot = try await db.collection("users")
            .whereField("email", isEqualTo: email.lowercased())
            .limit(to: 1)
            .getDocuments()
        return !snapshot.documents.isEmpty
    }

    func isPhoneTaken(_ phone: String) async throws -> Bool {
        let normalized = phone.filter(\.isNumber)
        guard !normalized.isEmpty else { return false }

        let snapshot = try await db.collection("users")
            .whereField("phoneNumber", isEqualTo: normalized)
            .limit(to: 1)
            .getDocuments()
        return !snapshot.documents.isEmpty
    }

    // MARK: - Kullanıcı Oluştur

    /// Müşteri (normal kullanıcı) dokümanı. Uzman ve müşteri aynı users koleksiyonunda; role ile ayrılır.
    func createUserDocument(
        uid: String,
        displayName: String,
        email: String,
        phoneNumber: String?
    ) async throws {

        let data: [String: Any] = [
            "displayName": displayName,
            "email": email.lowercased(),
            "phoneNumber": phoneNumber?.filter(\.isNumber) ?? "",
            "role": "user",
            "createdAt": Timestamp(date: Date())
        ]

        try await db.collection("users").document(uid).setData(data, merge: true)
    }

    // MARK: - Kullanıcı Getir

    func fetchUser(uid: String) async throws -> AppUser {
        let snap = try await db.collection("users").document(uid).getDocument()
        return try snap.data(as: AppUser.self)
    }

    // MARK: - Uzman İşlemleri

    func createExpertUserDocument(
        uid: String,
        displayName: String,
        email: String,
        phoneNumber: String
    ) async throws {

        let data: [String: Any] = [
            "displayName": displayName,
            "email": email.lowercased(),
            "phoneNumber": phoneNumber.filter(\.isNumber),
            "role": "expert",
            "createdAt": Timestamp(date: Date())
        ]

        try await db.collection("users").document(uid).setData(data, merge: true)
    }

    /// Uzman kayıt (1. adım) sonrası: service_providers'da minimal doküman. Tüm uzman bilgileri service_providers'da tutulur.
    func createMinimalServiceProvider(uid: String, displayName: String, email: String, phoneNumber: String) async throws {
        let data: [String: Any] = [
            "providerId": uid,
            "displayName": displayName,
            "email": email.lowercased(),
            "phoneNumber": phoneNumber.filter(\.isNumber),
            "status": "Draft",
            "createdAt": Timestamp(date: Date()),
            "businessName": "",
            "city": "",
            "isActive": false,
            "description": "",
            "image": "",
            "rating": 0.0,
            "experienceYears": 0,
            "isCertified": false,
            "acceptsCreditCard": false,
            "serviceCategories": [],
            "serviceCities": [],
            "workingDays": [],
            "portfolioImageURLs": []
        ]
        try await db.collection("service_providers").document(uid).setData(data, merge: true)
    }

    /// Kayıtlı uzman profilini Firestore service_providers koleksiyonundan getirir (uzman + müşteri users'da, uzman detayı service_providers'da).
    func fetchExpertProfile(uid: String) async throws -> ExpertProfile? {
        let snap = try await db.collection("service_providers").document(uid).getDocument()
        guard snap.exists else { return nil }
        return try? snap.data(as: ExpertProfile.self)
    }

    /// Uzman profilinde belirtilen alanları günceller (merge). service_providers dokümanına yazar.
    func updateExpertProfile(uid: String, fields: [String: Any]) async throws {
        try await db.collection("service_providers").document(uid).setData(fields, merge: true)
    }

    /// Profil %100 dolu olduğunda uzman "Onay için gönder" yapar; status "Pending" olur.
    func submitExpertForApproval(uid: String) async throws {
        try await db.collection("service_providers").document(uid).setData(["status": "Pending"], merge: true)
    }

    func fetchUserRole(uid: String) async throws -> String? {
        let snap = try await db.collection("users").document(uid).getDocument()
        return snap.data()?["role"] as? String
    }
}

extension Notification.Name {
    static let userDataUpdated = Notification.Name("userDataUpdated")
}

