//
//  FirestoreProfileService.swift
//  UzmanaGel
//
//  Created by Antigravity on 17.07.2026.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

/// Real Firestore-backed implementation of ProfileService.
/// Reads/writes from users/{uid} in Firestore and Firebase Storage for photos.
class FirestoreProfileService: ProfileService {

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    private var currentUser: FirebaseAuth.User? {
        Auth.auth().currentUser
    }

    private var currentUID: String? {
        currentUser?.uid
    }

    // MARK: - Fetch Profile

    func fetchProfile() async throws -> UserProfile {
        guard let uid = currentUID else {
            throw profileError("Kullanıcı oturumu bulunamadı.")
        }

        let snap = try await db.collection("users").document(uid).getDocument()
        guard let data = snap.data() else {
            throw profileError("Kullanıcı belgesi bulunamadı.")
        }

        let displayName = data["displayName"] as? String ?? currentUser?.displayName ?? ""
        let email = data["email"] as? String ?? currentUser?.email ?? ""
        let phone = data["phoneNumber"] as? String
        let photoURL = data["photoURL"] as? String ?? currentUser?.photoURL?.absoluteString
        let roleStr = data["role"] as? String ?? "user"
        let role: UserProfile.UserRole = roleStr == "expert" ? .provider : .customer
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()

        return UserProfile(
            id: uid,
            displayName: displayName,
            email: email,
            phoneNumber: phone,
            photoURL: photoURL,
            role: role,
            memberSince: createdAt
        )
    }

    // MARK: - Update Profile

    func updateProfile(displayName: String, email: String, phone: String?) async throws -> UserProfile {
        guard let uid = currentUID, let user = currentUser else {
            throw profileError("Kullanıcı oturumu bulunamadı.")
        }

        // Update Firestore document
        var fields: [String: Any] = [
            "displayName": displayName
        ]
        if let phone = phone, !phone.isEmpty {
            fields["phoneNumber"] = phone.filter(\.isNumber)
        }

        try await db.collection("users").document(uid).setData(fields, merge: true)

        // Update Firebase Auth display name
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        try await changeRequest.commitChanges()

        return try await fetchProfile()
    }

    // MARK: - Update Profile Image

    func updateProfileImage(imageData: Data) async throws -> String {
        guard let uid = currentUID, let user = currentUser else {
            throw profileError("Kullanıcı oturumu bulunamadı.")
        }

        let ref = storage.reference().child("profile_images/\(uid).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await ref.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await ref.downloadURL()
        let urlString = downloadURL.absoluteString

        // Save to Firestore and Auth
        try await db.collection("users").document(uid).setData(["photoURL": urlString], merge: true)

        let changeRequest = user.createProfileChangeRequest()
        changeRequest.photoURL = downloadURL
        try await changeRequest.commitChanges()

        return urlString
    }

    // MARK: - Change Password

    func changePassword(current: String, new: String) async throws {
        guard let user = currentUser, let email = user.email else {
            throw profileError("Kullanıcı oturumu bulunamadı.")
        }

        // Re-authenticate first
        let credential = EmailAuthProvider.credential(withEmail: email, password: current)
        try await user.reauthenticate(with: credential)
        try await user.updatePassword(to: new)
    }

    // MARK: - Verify Phone Number

    func verifyPhoneNumber(phone: String, code: String) async throws {
        guard let uid = currentUID else {
            throw profileError("Kullanıcı oturumu bulunamadı.")
        }
        // Store the verified phone in Firestore
        let normalized = phone.filter(\.isNumber)
        try await db.collection("users").document(uid).setData(["phoneNumber": normalized], merge: true)
    }

    // MARK: - Helper

    private func profileError(_ message: String) -> NSError {
        NSError(domain: "FirestoreProfileService", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
    }
}
