//  ChatDetailViewModel.swift
//  UzmanaGel
//
//  Created by Halil Keremoğlu on 9.07.2026.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class ChatDetailViewModel: ObservableObject {

    @Published private(set) var messages: [ChatMessage] = []
    @Published var messageText: String = ""
    @Published private(set) var isSending = false
    @Published var errorMessage: String?

    let conversation: Conversation

    private let repository = MessageRepository()
    private var listener: ListenerRegistration?
    private var isMarkingAsRead = false

    init(conversation: Conversation) {
        self.conversation = conversation
    }

    func load() {
        guard listener == nil else { return }

        guard let currentUserId = Auth.auth().currentUser?.uid else {
            errorMessage = "Oturum açmış kullanıcı bulunamadı."
            return
        }

        errorMessage = nil

        listener = repository.listenToMessages(
            conversationId: conversation.id
        ) { [weak self] messages in

            Task { @MainActor in
                guard let self else { return }

                self.messages = messages

                await self.markUnreadMessagesAsRead(
                    messages: messages,
                    currentUserId: currentUserId
                )
            }

        } onError: { [weak self] error in

            Task { @MainActor in
                guard let self else { return }

                self.errorMessage = error.localizedDescription
            }
        }
    }

    func sendMessage() {
        let trimmedText = messageText
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedText.isEmpty else { return }

        guard let currentUserId = Auth.auth().currentUser?.uid else {
            errorMessage = "Oturum açmış kullanıcı bulunamadı."
            return
        }

        guard !isSending else { return }

        isSending = true
        errorMessage = nil

        Task {
            do {
                try await repository.sendMessage(
                    conversation: conversation,
                    senderId: currentUserId,
                    text: trimmedText
                )

                messageText = ""

            } catch {
                errorMessage = error.localizedDescription
            }

            isSending = false
        }
    }

    func isCurrentUser(_ message: ChatMessage) -> Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            return false
        }

        return message.senderId == currentUserId
    }

    private func markUnreadMessagesAsRead(
        messages: [ChatMessage],
        currentUserId: String
    ) async {

        guard !isMarkingAsRead else { return }

        let unreadMessageIds = messages
            .filter {
                $0.receiverId == currentUserId &&
                !$0.isRead
            }
            .map(\.id)

        guard !unreadMessageIds.isEmpty else { return }

        isMarkingAsRead = true

        defer {
            isMarkingAsRead = false
        }

        do {
            try await repository.markConversationAsRead(
                conversationId: conversation.id,
                currentUserId: currentUserId,
                messageIds: unreadMessageIds
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    func stopListening() {
        listener?.remove()
        listener = nil
    }
}
