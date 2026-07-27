//
//  AdminProviderApplicationService.swift
//  UzmanaGel
//
//  Created by Halil Keremoğlu on 27.07.2026.
//

import Foundation
import FirebaseFunctions

enum AdminProviderApplicationAction: String, Identifiable, Equatable {
    case approve
    case reject
    case requestDocuments

    var id: String { rawValue }

    var title: String {
        switch self {
        case .approve:
            return "Onayla"
        case .reject:
            return "Reddet"
        case .requestDocuments:
            return "Eksik Belge İste"
        }
    }

    var confirmationTitle: String {
        switch self {
        case .approve:
            return "Başvuru onaylansın mı?"
        case .reject:
            return "Başvuru reddedilsin mi?"
        case .requestDocuments:
            return "Eksik belge istensin mi?"
        }
    }

    var confirmationMessage: String {
        switch self {
        case .approve:
            return "Uzman hesabı aktif edilecek."
        case .reject:
            return "Başvuru reddedilecek ve uzman bilgilendirilecek."
        case .requestDocuments:
            return "Uzmandan eksik belgeleri tamamlaması istenecek."
        }
    }

    var successMessage: String {
        switch self {
        case .approve:
            return "Uzman başvurusu onaylandı."
        case .reject:
            return "Uzman başvurusu reddedildi."
        case .requestDocuments:
            return "Eksik belge isteği gönderildi."
        }
    }

    var requiresNote: Bool {
        switch self {
        case .approve:
            return false
        case .reject, .requestDocuments:
            return true
        }
    }
}

final class AdminProviderApplicationService {

    private let functions = Functions.functions(
        region: "europe-west1"
    )

    func moderateApplication(
        providerId: String,
        action: AdminProviderApplicationAction,
        adminNote: String
    ) async throws {
        let cleanProviderId = providerId.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let cleanNote = adminNote.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !cleanProviderId.isEmpty else {
            throw NSError(
                domain: "AdminProviderApplicationService",
                code: 400,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Uzman kimliği bulunamadı."
                ]
            )
        }

        guard cleanNote.count <= 500 else {
            throw NSError(
                domain: "AdminProviderApplicationService",
                code: 400,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Admin açıklaması en fazla 500 karakter olabilir."
                ]
            )
        }

        guard !action.requiresNote || !cleanNote.isEmpty else {
            throw NSError(
                domain: "AdminProviderApplicationService",
                code: 400,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Bu işlem için admin açıklaması zorunludur."
                ]
            )
        }

        let callable = functions.httpsCallable(
            "moderateProviderApplication"
        )

        _ = try await callable.call([
            "providerId": cleanProviderId,
            "action": action.rawValue,
            "adminNote": cleanNote
        ])
    }
}
