//
//  MessageViewModel.swift
//  UzmanaGel
//
//  Created by Halil Keremoğlu on 9.07.2026.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class MessageViewModel: ObservableObject {

    @Published private(set) var conversations: [Conversation] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let repository = MessageRepository()
    private var listener: ListenerRegistration?

    func load() {
        guard listener == nil else { return }

        guard let currentUserId = Auth.auth().currentUser?.uid else {
            errorMessage = "Oturum açmış kullanıcı bulunamadı."
            return
        }

        isLoading = true
        errorMessage = nil

        listener = repository.listenToConversations(
            currentUserId: currentUserId
        ) { [weak self] conversations in

            Task { @MainActor in
                guard let self else { return }

                self.conversations = conversations
                self.isLoading = false
            }

        } onError: { [weak self] error in

            Task { @MainActor in
                guard let self else { return }

                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func getOrCreateConversation(
        participantId: String,
        participantName: String,
        participantPhotoURL: String? = nil
    ) async throws -> Conversation {

        guard let user = Auth.auth().currentUser else {
            throw MessageViewModelError.userNotFound
        }

        let currentUserName =
            user.displayName?
                .trimmingCharacters(in: .whitespacesAndNewlines)

        let resolvedName: String

        if let currentUserName,
           !currentUserName.isEmpty {

            resolvedName = currentUserName

        } else if let email = user.email,
                  !email.isEmpty {

            resolvedName = email

        } else {
            resolvedName = "Kullanıcı"
        }

        return try await repository.getOrCreateConversation(
            currentUserId: user.uid,
            currentUserName: resolvedName,
            participantId: participantId,
            participantName: participantName,
            currentUserPhotoURL: user.photoURL?.absoluteString,
            participantPhotoURL: participantPhotoURL
        )
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }
    
    
}

enum MessageViewModelError: LocalizedError {
    case userNotFound

    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "Oturum açmış kullanıcı bulunamadı."
        }
    }
}
