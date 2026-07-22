import Foundation
import Combine
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

private enum EditBusinessProfileError: LocalizedError {
    case userNotFound
    case profileNotFound
    case businessNameRequired

    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "Kullanıcı oturumu bulunamadı."
        case .profileNotFound:
            return "Uzman profili bulunamadı."
        case .businessNameRequired:
            return "İşletme adı boş bırakılamaz."
        }
    }
}

@MainActor
final class EditBusinessProfileViewModel: ObservableObject {

    // Form inputs
    @Published var businessName = ""
    @Published var description = ""
    @Published var selectedCategories: [String] = []

    let descriptionLimit = 250

    // Image state
    @Published var logoUrl: String?
    @Published var coverUrl: String?
    @Published var selectedLogoData: Data?
    @Published var selectedCoverData: Data?

    // Status state
    @Published var isCertified = false
    @Published var missingDocuments: [String] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let userRepository: UserRepository

    init(
        userRepository: UserRepository = UserRepository()
    ) {
        self.userRepository = userRepository
    }

    func loadBusinessInfo() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        successMessage = nil

        defer {
            isLoading = false
        }

        do {
            guard let uid = Auth.auth().currentUser?.uid else {
                throw EditBusinessProfileError.userNotFound
            }

            guard let profile =
                    try await userRepository.fetchExpertProfile(uid: uid)
            else {
                throw EditBusinessProfileError.profileNotFound
            }

            businessName = profile.businessName
            description = profile.about ?? ""
            selectedCategories = profile.serviceCategories
            logoUrl = profile.profileImageURL
            coverUrl = nil

            isCertified = !profile.certificateURLs.isEmpty
            updateMissingDocuments(from: profile)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveBusinessProfile() async {
        guard !isLoading else { return }

        let trimmedBusinessName = businessName
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let trimmedDescription = description
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedBusinessName.isEmpty else {
            errorMessage =
                EditBusinessProfileError.businessNameRequired
                    .localizedDescription
            return
        }

        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage =
                EditBusinessProfileError.userNotFound.localizedDescription
            return
        }

        isLoading = true
        errorMessage = nil
        successMessage = nil

        defer {
            isLoading = false
        }

        do {
            let fields: [String: Any] = [
                "businessName": trimmedBusinessName,
                "about": trimmedDescription,
                "description": trimmedDescription,
                "serviceCategories": selectedCategories,
                "updatedAt": FieldValue.serverTimestamp()
            ]

            try await userRepository.updateExpertProfile(
                uid: uid,
                fields: fields
            )

            businessName = trimmedBusinessName
            description = trimmedDescription

            let hasPendingImageChange =
                selectedLogoData != nil ||
                selectedCoverData != nil

            selectedLogoData = nil
            selectedCoverData = nil

            if hasPendingImageChange {
                successMessage =
                    "İşletme bilgileri kaydedildi. " +
                    "Görsel değişiklikleri henüz kaydedilmedi."
            } else {
                successMessage = "İşletme profili güncellendi."
            }

            NotificationCenter.default.post(
                name: .userDataUpdated,
                object: nil
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func enforceDescriptionLimit() {
        if description.count > descriptionLimit {
            description = String(
                description.prefix(descriptionLimit)
            )
        }
    }

    func removeCategory(_ category: String) {
        selectedCategories.removeAll {
            $0 == category
        }
    }

    func addCategory(_ category: String) {
        guard !selectedCategories.contains(category) else {
            return
        }

        selectedCategories.append(category)
    }

    private func updateMissingDocuments(
        from profile: ExpertProfile
    ) {
        var documents: [String] = []

        if profile.idBackURL == nil {
            documents.append("Kimlik Fotokopisi (Arka Yüz)")
        }

        if profile.certificateURLs.isEmpty {
            documents.append(
                "Mesleki Yeterlilik Belgesi / Sertifika"
            )
        }

        missingDocuments = documents
    }
}
