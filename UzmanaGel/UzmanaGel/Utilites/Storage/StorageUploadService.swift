//
//  StorageUploadService.swift
//  UzmanaGel
//
//  Production-ready Firebase Storage upload service.
//  Paths: certificates/{uid}/{filename}, verification_documents/{uid}/{fixedFileName}
//

import Foundation
import UIKit
import FirebaseAuth
import FirebaseStorage

// MARK: - Errors

enum StorageUploadError: LocalizedError {
    /// Auth.auth().currentUser?.uid is nil
    case notAuthenticated
    /// Cannot convert to JPEG / cannot build Data
    case invalidData
    /// Wraps underlying Storage error
    case uploadFailed(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Giriş yapılmamış. Lütfen tekrar giriş yapın."
        case .invalidData:
            return "Dosya verisi geçersiz veya JPEG'e dönüştürülemedi."
        case .uploadFailed(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - Verification Document Type

enum VerificationDocumentType {
    case idCardFront
    case idCardBack
    case selfie
    case businessLicense

    /// Fixed file name (without path). Extension filled from fileExtension parameter.
    func fixedFileName(fileExtension: String) -> String {
        let ext = fileExtension.isEmpty ? "jpg" : fileExtension.lowercased()
        switch self {
        case .idCardFront:   return "id_card_front.\(ext)"
        case .idCardBack:    return "id_card_back.\(ext)"
        case .selfie:        return "selfie.\(ext)"
        case .businessLicense: return "business_license.\(ext)"
        }
    }
}

// MARK: - Service

final class StorageUploadService {

    private let storage = Storage.storage()

    /// UID is ALWAYS read from Auth.auth().currentUser?.uid. If nil -> throw notAuthenticated.
    private func currentUID() throws -> String {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw StorageUploadError.notAuthenticated
        }
        return uid
    }

    /// Returns a Storage reference for the given full path. Validates auth uid first.
    private func storageRef(path: String) throws -> StorageReference {
        _ = try currentUID()
        return storage.reference().child(path)
    }

    /// Storage reference with explicit uid (kayıt sonrası Auth.currentUser henüz set olmamış olabilir).
    private func storageRef(path: String, uid: String) -> StorageReference {
        return storage.reference().child(path)
    }

    /// Uploads data and returns download URL. Wraps any thrown error in uploadFailed.
    private func putDataAndGetDownloadURL(_ data: Data, ref: StorageReference, contentType: String) async throws -> String {
        let metadata = StorageMetadata()
        metadata.contentType = contentType
        do {
            _ = try await ref.putDataAsync(data, metadata: metadata)
            let url = try await ref.downloadURL()
            return url.absoluteString
        } catch {
            throw StorageUploadError.uploadFailed(error)
        }
    }

    private func contentType(for fileExtension: String) -> String {
        switch fileExtension.lowercased() {
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "pdf": return "application/pdf"
        case "heic": return "image/heic"
        default: return "application/octet-stream"
        }
    }

    // MARK: - Certificates

    /// Uploads to certificates/{uid}/{UUID}.{ext}. Returns downloadURL as String.
    func uploadCertificate(data: Data, fileExtension: String) async throws -> String {
        let uid = try currentUID()
        let ext = fileExtension.isEmpty ? "bin" : fileExtension.lowercased()
        let filename = "\(UUID().uuidString).\(ext)"
        let path = "certificates/\(uid)/\(filename)"
        let ref = try storageRef(path: path)
        return try await putDataAndGetDownloadURL(data, ref: ref, contentType: contentType(for: ext))
    }

    /// Converts image to JPEG; if fails -> invalidData. Uploads to certificates/{uid}/{UUID}.jpg.
    func uploadCertificate(image: UIImage, quality: CGFloat = 0.85) async throws -> String {
        guard let data = image.jpegData(compressionQuality: quality) else {
            throw StorageUploadError.invalidData
        }
        let uid = try currentUID()
        let filename = "\(UUID().uuidString).jpg"
        let path = "certificates/\(uid)/\(filename)"
        let ref = try storageRef(path: path)
        return try await putDataAndGetDownloadURL(data, ref: ref, contentType: "image/jpeg")
    }

    // MARK: - Verification Documents

    /// Uploads to verification_documents/{uid}/{fixedFileName}. Fixed file name from type + fileExtension.
    /// idCardFront -> id_card_front.{ext or jpg}, idCardBack -> id_card_back.{ext or jpg},
    /// selfie -> selfie.{ext or jpg}, businessLicense -> business_license.{ext}
    func uploadVerificationDocument(data: Data, type: VerificationDocumentType, fileExtension: String) async throws -> String {
        let uid = try currentUID()
        let ext = fileExtension.isEmpty ? "jpg" : fileExtension.lowercased()
        let fileName = type.fixedFileName(fileExtension: ext)
        let path = "verification_documents/\(uid)/\(fileName)"
        let ref = try storageRef(path: path)
        return try await putDataAndGetDownloadURL(data, ref: ref, contentType: contentType(for: ext))
    }

    // MARK: - Upload with explicit UID (kayıt akışında createUser sonrası currentUser gecikmeli set olabildiği için)

    /// Aynı path kuralları; uid parametre ile (Auth.currentUser kullanılmaz).
    func uploadVerificationDocument(data: Data, type: VerificationDocumentType, fileExtension: String, uid: String) async throws -> String {
        let ext = fileExtension.isEmpty ? "jpg" : fileExtension.lowercased()
        let fileName = type.fixedFileName(fileExtension: ext)
        let path = "verification_documents/\(uid)/\(fileName)"
        let ref = storageRef(path: path, uid: uid)
        return try await putDataAndGetDownloadURL(data, ref: ref, contentType: contentType(for: ext))
    }

    /// Sertifika görseli; uid parametre ile.
    func uploadCertificate(image: UIImage, quality: CGFloat = 0.85, uid: String) async throws -> String {
        guard let data = image.jpegData(compressionQuality: quality) else {
            throw StorageUploadError.invalidData
        }
        let filename = "\(UUID().uuidString).jpg"
        let path = "certificates/\(uid)/\(filename)"
        let ref = storageRef(path: path, uid: uid)
        return try await putDataAndGetDownloadURL(data, ref: ref, contentType: "image/jpeg")
    }

    /// Sertifika PDF veya diğer dosya; uid parametre ile (kayıt akışında).
    func uploadCertificate(data: Data, fileExtension: String, uid: String) async throws -> String {
        let ext = fileExtension.isEmpty ? "bin" : fileExtension.lowercased()
        let filename = "\(UUID().uuidString).\(ext)"
        let path = "certificates/\(uid)/\(filename)"
        let ref = storageRef(path: path, uid: uid)
        return try await putDataAndGetDownloadURL(data, ref: ref, contentType: contentType(for: ext))
    }

    /// Portföy fotoğrafı; portfolio/{uid}/{uuid}.jpg
    func uploadPortfolio(image: UIImage, quality: CGFloat = 0.85, uid: String) async throws -> String {
        guard let data = image.jpegData(compressionQuality: quality) else {
            throw StorageUploadError.invalidData
        }
        let filename = "\(UUID().uuidString).jpg"
        let path = "portfolio/\(uid)/\(filename)"
        let ref = storageRef(path: path, uid: uid)
        return try await putDataAndGetDownloadURL(data, ref: ref, contentType: "image/jpeg")
    }

    /// İlan görseli; listing_images/{uid}/{uuid}.jpg — ilan açma/düzenlemede kullanılır.
    func uploadListingImage(image: UIImage, quality: CGFloat = 0.85, uid: String) async throws -> String {
        guard let data = image.jpegData(compressionQuality: quality) else {
            throw StorageUploadError.invalidData
        }
        let filename = "\(UUID().uuidString).jpg"
        let path = "listing_images/\(uid)/\(filename)"
        let ref = storageRef(path: path, uid: uid)
        return try await putDataAndGetDownloadURL(data, ref: ref, contentType: "image/jpeg")
    }
}
