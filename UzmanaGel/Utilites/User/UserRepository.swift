//
//  UserRepository.swift
//  UzmanaGel
//
//  Created by Abdullah B on 5.02.2026.
//

import Foundation
import FirebaseFirestore

enum UserRepositoryError: LocalizedError {
    case invalidPrivateFields([String])

    var errorDescription: String? {
        switch self {
        case .invalidPrivateFields(let fields):
            return "Geçersiz özel veri alanları: \(fields.joined(separator: ", "))"
        }
    }
}

/// Reads and writes user and provider data.
final class UserRepository {

    private let db = Firestore.firestore()

    private let usersCollection = "users"
    private let providersCollection = "service_providers"
    private let privateProvidersCollection = "provider_private_data"

    private let allowedPrivateUpdateFields: Set<String> = [
        "email",
        "phoneNumber",
        "taxNumber",
        "bankName",
        "iban",
        "accountHolderName",
        "certificateURLs",
        "idFrontURL",
        "idBackURL"
    ]

    // MARK: - Duplicate Check

    func isEmailTaken(
        _ email: String
    ) async throws -> Bool {
        let snapshot = try await db
            .collection(usersCollection)
            .whereField(
                "email",
                isEqualTo: email.lowercased()
            )
            .limit(to: 1)
            .getDocuments()

        return !snapshot.documents.isEmpty
    }

    func isPhoneTaken(
        _ phone: String
    ) async throws -> Bool {
        let normalized = phone.filter(\.isNumber)

        guard !normalized.isEmpty else {
            return false
        }

        let snapshot = try await db
            .collection(usersCollection)
            .whereField(
                "phoneNumber",
                isEqualTo: normalized
            )
            .limit(to: 1)
            .getDocuments()

        return !snapshot.documents.isEmpty
    }

    // MARK: - Create User

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

        try await db
            .collection(usersCollection)
            .document(uid)
            .setData(
                data,
                merge: true
            )
    }

    // MARK: - Fetch User

    func fetchUser(
        uid: String
    ) async throws -> AppUser {
        let snapshot = try await db
            .collection(usersCollection)
            .document(uid)
            .getDocument()

        return try snapshot.data(
            as: AppUser.self
        )
    }

    func userDocumentExists(
        uid: String
    ) async throws -> Bool {
        let snapshot = try await db
            .collection(usersCollection)
            .document(uid)
            .getDocument()

        return snapshot.exists
    }

    func fetchUserRole(
        uid: String
    ) async throws -> String? {
        let snapshot = try await db
            .collection(usersCollection)
            .document(uid)
            .getDocument()

        return snapshot.data()?["role"] as? String
    }

    // MARK: - Expert User

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

        try await db
            .collection(usersCollection)
            .document(uid)
            .setData(
                data,
                merge: true
            )
    }

    // MARK: - Public Provider Profile

    /// Creates the current public provider document.
    ///
    /// Email and phone are temporarily kept here until all screens
    /// are moved to provider_private_data.
    /// Creates the public and private provider documents together.
    func createMinimalServiceProvider(
        uid: String,
        displayName: String,
        email: String,
        phoneNumber: String
    ) async throws {
        let now = Timestamp(date: Date())

        let publicReference = db
            .collection(providersCollection)
            .document(uid)

        let privateReference = db
            .collection(privateProvidersCollection)
            .document(uid)

        let privateSnapshot = try await privateReference.getDocument()

        // Public profile data
        let publicData: [String: Any] = [
            "providerId": uid,
            "displayName": displayName,
            "status": "Draft",
            "createdAt": now,
            "businessName": "",
            "city": "",
            "isActive": false,
            "isAvailable": true,
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

        // Private provider data
        var privateData: [String: Any] = [
            "providerId": uid,
            "email": email.lowercased(),
            "phoneNumber": phoneNumber.filter(\.isNumber),
            "taxNumber": "",
            "bankName": "",
            "iban": "",
            "accountHolderName": "",
            "certificateURLs": [],
            "idFrontURL": "",
            "idBackURL": "",
            "updatedAt": now
        ]

        if !privateSnapshot.exists {
            privateData["createdAt"] = now
        }

        let batch = db.batch()

        batch.setData(
            publicData,
            forDocument: publicReference,
            merge: true
        )

        batch.setData(
            privateData,
            forDocument: privateReference,
            merge: true
        )

        try await batch.commit()
    }
    func fetchExpertProfile(
        uid: String
    ) async throws -> ExpertProfile? {
        let publicSnapshot = try await db
            .collection(providersCollection)
            .document(uid)
            .getDocument()

        guard publicSnapshot.exists else {
            return nil
        }

        var profile = try publicSnapshot.data(
            as: ExpertProfile.self
        )

        do {
            if let privateData = try await fetchProviderPrivateData(
                uid: uid
            ) {
                profile.applyPrivateData(privateData)
            }
        } catch let error as NSError {
            let isPermissionDenied =
                error.domain == FirestoreErrorDomain
                && error.code
                    == FirestoreErrorCode.Code.permissionDenied.rawValue

            // Other users cannot read private provider data.
            if !isPermissionDenied {
                throw error
            }
        }

        return profile
    }
    func updateExpertProfile(
        uid: String,
        fields: [String: Any]
    ) async throws {
        guard !fields.isEmpty else {
            return
        }

        var publicFields: [String: Any] = [:]
        var privateFields: [String: Any] = [:]

        for (key, value) in fields {
            if allowedPrivateUpdateFields.contains(key) {
                privateFields[key] = value
            } else {
                publicFields[key] = value
            }
        }

        let batch = db.batch()

        if !publicFields.isEmpty {
            batch.setData(
                publicFields,
                forDocument: db
                    .collection(providersCollection)
                    .document(uid),
                merge: true
            )
        }

        if !privateFields.isEmpty {
            // providerId allows creating the private document
            // for existing providers during migration.
            privateFields["providerId"] = uid
            privateFields["updatedAt"] = Timestamp(date: Date())

            batch.setData(
                privateFields,
                forDocument: db
                    .collection(privateProvidersCollection)
                    .document(uid),
                merge: true
            )
        }

        try await batch.commit()
    }
    func submitExpertForApproval(
        uid: String
    ) async throws {
        try await db
            .collection(providersCollection)
            .document(uid)
            .setData(
                [
                    "status": "Pending"
                ],
                merge: true
            )
    }

    func fetchExpertAvailability(
        uid: String
    ) async throws -> Bool {
        let snapshot = try await db
            .collection(providersCollection)
            .document(uid)
            .getDocument()

        return snapshot.data()?["isAvailable"] as? Bool ?? true
    }

    func updateExpertAvailability(
        uid: String,
        isAvailable: Bool
    ) async throws {
        try await db
            .collection(providersCollection)
            .document(uid)
            .setData(
                [
                    "isAvailable": isAvailable,
                    "updatedAt": Timestamp(date: Date())
                ],
                merge: true
            )
    }

    // MARK: - Provider Private Data

    /// Creates the private provider document.
    ///
    /// This function is not connected to signup yet.
    func createProviderPrivateData(
        uid: String,
        email: String,
        phoneNumber: String
    ) async throws {
        let reference = db
            .collection(privateProvidersCollection)
            .document(uid)

        let snapshot = try await reference.getDocument()
        let now = Timestamp(date: Date())

        var data: [String: Any] = [
            "providerId": uid,
            "email": email.lowercased(),
            "phoneNumber": phoneNumber.filter(\.isNumber),
            "taxNumber": "",
            "bankName": "",
            "iban": "",
            "accountHolderName": "",
            "certificateURLs": [],
            "idFrontURL": "",
            "idBackURL": "",
            "updatedAt": now
        ]

        if !snapshot.exists {
            data["createdAt"] = now
        }

        try await reference.setData(
            data,
            merge: true
        )
    }

    func fetchProviderPrivateData(
        uid: String
    ) async throws -> ProviderPrivateData? {
        let snapshot = try await db
            .collection(privateProvidersCollection)
            .document(uid)
            .getDocument()

        guard snapshot.exists else {
            return nil
        }

        return try snapshot.data(
            as: ProviderPrivateData.self
        )
    }

    func providerPrivateDataExists(
        uid: String
    ) async throws -> Bool {
        let snapshot = try await db
            .collection(privateProvidersCollection)
            .document(uid)
            .getDocument()

        return snapshot.exists
    }

    func updateProviderPrivateData(
        uid: String,
        fields: [String: Any]
    ) async throws {
        guard !fields.isEmpty else {
            return
        }

        let requestedFields = Set<String>(
            fields.keys
        )

        let invalidFields = requestedFields
            .subtracting(
                allowedPrivateUpdateFields
            )
            .sorted()

        guard invalidFields.isEmpty else {
            throw UserRepositoryError
                .invalidPrivateFields(
                    invalidFields
                )
        }

        var safeFields = fields

        safeFields["updatedAt"] = Timestamp(
            date: Date()
        )

        try await db
            .collection(privateProvidersCollection)
            .document(uid)
            .setData(
                safeFields,
                merge: true
            )
    }
}

extension Notification.Name {
    static let userDataUpdated =
        Notification.Name("userDataUpdated")
}
